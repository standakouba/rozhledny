import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/settings.dart';
import '../../services/tile_cache.dart';
import '../../services/location.dart';
import '../towers/tower_detail_sheet.dart';
import '../towers/tower_editor_sheet.dart';
import 'map_compass.dart';
import 'tower_marker.dart';

/// Zhruba střed republiky a zoom, ve kterém je vidět celá.
const _czCenter = LatLng(49.80, 15.47);
const _czZoom = 7.0;

/// Pod tímto zoomem se kreslí jen tečky — jmenovky ani odznaky nejsou čitelné.
const _compactBelowZoom = 10.0;

/// Zoom pro pohled „co mám kolem sebe“ — pár kilometrů na šířku obrazovky.
const _nearbyZoom = 12.0;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();

  LatLngBounds? _bounds;
  double _zoom = _czZoom;
  double _rotation = 0;
  String? _selectedUuid;

  /// MapController vyhodí výjimku, když se na něj sáhne dřív, než se mapa
  /// poprvé vykreslí — a nastavení ze SharedPreferences dorazí právě dřív.
  bool _mapReady = false;

  StreamSubscription<MapEvent>? _events;

  /// Po startu se mapa jednou přesune na aktuální polohu.
  ///
  /// Jen jednou: GPS chodí opakovaně a bez téhle pojistky by mapa trhla
  /// zpátky pokaždé, když přijde přesnější údaj — klidně uprostřed toho,
  /// jak si člověk prohlíží úplně jiný kout republiky.
  bool _centeredOnMe = false;

  @override
  void initState() {
    super.initState();
    // Stav kamery se bere ze streamu událostí, ne z `onPositionChanged`.
    // Ten se totiž volá jen z `moveRaw`, tedy při posunu a zoomu — otočení
    // jde ve flutter_map samostatnou cestou (`rotateRaw`) a do callbacku
    // se nikdy nedostane. Střelka kompasu by pak visela na hodnotě z
    // posledního posunu a tvářila se, že ukazuje špatným směrem.
    _events = _controller.mapEventStream.listen((e) {
      // Jakmile uživatel s mapou sám pohne, automatické vycentrování se
      // zruší. Přijít o rozkoukaný výřez kvůli opožděnému GPS fixu je horší
      // než zůstat tam, kam se člověk podíval.
      if (_isUserGesture(e.source)) _centeredOnMe = true;
      _syncCamera(e.camera);
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Pohnul mapou uživatel, nebo se posunula sama (kód, změna velikosti)?
  bool _isUserGesture(MapEventSource source) => switch (source) {
        MapEventSource.dragStart ||
        MapEventSource.onDrag ||
        MapEventSource.dragEnd ||
        MapEventSource.multiFingerGestureStart ||
        MapEventSource.onMultiFinger ||
        MapEventSource.multiFingerEnd ||
        MapEventSource.doubleTapZoomAnimationController ||
        MapEventSource.doubleTapHold ||
        MapEventSource.flingAnimationController ||
        MapEventSource.scrollWheel =>
          true,
        _ => false,
      };

  /// Přesune mapu na aktuální polohu, pokud je k dispozici a ještě se to
  /// nestalo. Volá se ze dvou míst, protože není dané, co přijde dřív —
  /// připravená mapa, nebo první poloha z GPS.
  void _centerOnMeOnce() {
    if (_centeredOnMe || !_mapReady) return;
    final me = ref.read(currentPositionProvider).value;
    if (me == null) return;
    _centeredOnMe = true;
    _controller.move(LatLng(me.latitude, me.longitude), _nearbyZoom);
  }

  /// Překresluje se jen při skutečné změně — stream chodí i při každém
  /// snímku posunu a setState na každý z nich by mapu zbytečně brzdil.
  void _syncCamera(MapCamera camera) {
    if (_bounds == camera.visibleBounds &&
        _zoom == camera.zoom &&
        _rotation == camera.rotation) {
      return;
    }
    setState(() {
      _bounds = camera.visibleBounds;
      _zoom = camera.zoom;
      _rotation = camera.rotation;
    });
  }

  /// Vykreslují se jen rozhledny ve výřezu.
  ///
  /// Clustering by byl hezčí, ale `flutter_map_marker_cluster` ani
  /// `flutter_map_supercluster` zatím neumí latlong2 0.10, které flutter_map 8
  /// vyžaduje. Ořez výřezem drží počet značek v jednotkách až desítkách
  /// všude kromě pohledu na celou republiku.
  List<TowerWithStats> _visible(List<TowerWithStats> all) {
    final bounds = _bounds;
    if (bounds == null) return all;
    return [
      for (final t in all)
        if (bounds.contains(LatLng(t.tower.lat, t.tower.lon))) t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Vypnutí gesta samo o sobě mapu nenarovná — když ji uživatel nechal
    // pootočenou a rotaci pak zakáže, zůstala by natočená napořád.
    ref.listen(settingsProvider, (previous, next) {
      if (_mapReady && !next.allowRotation && _controller.camera.rotation != 0) {
        _controller.rotate(0);
      }
    });

    // GPS fix obvykle dorazí až po vykreslení mapy, takže vycentrování musí
    // počkat na něj. Poslední známá poloha přijde skoro hned, takže pohled
    // na celou republiku bliká jen zlomek vteřiny.
    ref.listen(currentPositionProvider, (previous, next) {
      if (next.value != null) _centerOnMeOnce();
    });

    final settings = ref.watch(sharedPrefsProvider);

    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Nastavení se nenačetlo: $e')),
      data: (_) => _buildMap(context),
    );
  }

  Widget _buildMap(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final basemap = settings.basemap;
    final apiKey = settings.mapyApiKey;
    final store = ref.watch(tileCacheStoreProvider(basemap.id));
    final towers = ref.watch(towersProvider);
    final me = ref.watch(currentPositionProvider).value;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MapCompass(
            rotation: _rotation,
            locked: !settings.allowRotation,
            onUnlock: () =>
                ref.read(settingsProvider.notifier).setAllowRotation(true),
            onLockToNorth: () {
              _controller.rotate(0);
              ref.read(settingsProvider.notifier).setAllowRotation(false);
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'add',
            tooltip: 'Přidat rozhlednu',
            onPressed: () => _addTowerHere(me),
            child: const Icon(Icons.add_location_alt_outlined),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'locate',
            tooltip: 'Moje poloha',
            onPressed: me == null ? null : () => _goTo(me),
            backgroundColor: me == null
                ? Theme.of(context).disabledColor
                : null,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _czCenter,
            initialZoom: _czZoom,
            maxZoom: basemap.maxZoom.toDouble(),
            minZoom: 5,
            // Otáčení dvěma prsty se spouští omylem a mapa pak zůstane
            // natočená, aniž by bylo poznat jak zpátky. Sever nahoru je
            // proto výchozí; odemyká se kompasem na mapě.
            interactionOptions: InteractionOptions(
              flags: settings.allowRotation
                  ? InteractiveFlag.all
                  : InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: () {
              setState(() => _mapReady = true);
              _syncCamera(_controller.camera);
              _centerOnMeOnce();
            },
            onTap: (_, _) => setState(() => _selectedUuid = null),
            // Dlouhý stisk je nejrychlejší cesta k „tady stojí rozhledna,
            // kterou nemáme“ — poloha se předvyplní z místa stisku.
            onLongPress: (_, point) => TowerEditorSheet.show(
              context,
              initialPoint: point,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: basemap.url(apiKey),
              userAgentPackageName: 'cz.rozhledny.rozhledny',
              maxNativeZoom: basemap.maxZoom,
              tileProvider: store.value == null
                  ? NetworkTileProvider()
                  : CachedTileProvider(
                      store: store.value!,
                      maxStale: tileMaxStale,
                    ),
            ),
            MarkerLayer(
              markers: [
                for (final t in _visible(towers.value ?? const []))
                  Marker(
                    point: LatLng(t.tower.lat, t.tower.lon),
                    width: 34,
                    height: 34,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedUuid = t.tower.uuid);
                        TowerDetailSheet.show(context, t.tower.uuid);
                      },
                      child: TowerMarker(
                        visitCount: t.visitCount,
                        compact: _zoom < _compactBelowZoom,
                        selected: _selectedUuid == t.tower.uuid,
                      ),
                    ),
                  ),
              ],
            ),
            if (me != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(me.latitude, me.longitude),
                    width: 22,
                    height: 22,
                    child: const _MyLocationDot(),
                  ),
                ],
              ),
            // Vlevo dole, aby se nepotkalo s atribucí vpravo ani s tlačítky.
            const Scalebar(
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(left: 12, bottom: 8),
              lineColor: Color(0xFF212121),
              textStyle: TextStyle(
                color: Color(0xFF212121),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                // Podklad mapy je pestrý, takže bílý obrys drží čitelnost
                // nad lesem i nad silnicí.
                shadows: [
                  Shadow(color: Colors.white, blurRadius: 2),
                  Shadow(color: Colors.white, blurRadius: 4),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: basemap.attributionBuilder(context),
              ),
            ),
          ],
        ),
        if (towers.isLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(),
          ),
        _CountBadge(
          visible: _visible(towers.value ?? const []).length,
          total: towers.value?.length ?? 0,
        ),
      ],
      ),
    );
  }

  void _goTo(Position me) => _controller.move(
        LatLng(me.latitude, me.longitude),
        // Zoom, ve kterém jsou vidět jednotlivé rozhledny i cesty k nim.
        _zoom < 13 ? 14 : _zoom,
      );

  /// Přidání rozhledny z tlačítka: přednost má poloha, kde stojím. Bez GPS
  /// se vezme střed mapy, což je pořád lepší než prázdný formulář.
  void _addTowerHere(Position? me) {
    final point = me != null
        ? LatLng(me.latitude, me.longitude)
        : _controller.camera.center;
    TowerEditorSheet.show(context, initialPoint: point);
  }
}

/// Modrá tečka s prstencem — stejná konvence jako v každé mapové aplikaci,
/// takže nepotřebuje vysvětlení.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
    );
  }
}

/// Malá kontrola pro vývoj i pro uživatele: kolik rozhleden je zrovna ve výřezu.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.visible, required this.total});

  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$visible / $total',
                style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
      ),
    );
  }
}
