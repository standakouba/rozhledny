import 'dart:async';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
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
import '../towers/tower_colors.dart';
import '../towers/tower_detail_sheet.dart';
import '../towers/tower_editor_sheet.dart';
import '../towers/tower_visibility.dart';
import 'map_compass.dart';
import 'map_round_button.dart';
import 'tile_retry.dart';
import 'tower_marker.dart';

/// Zhruba střed republiky a zoom, ve kterém je vidět celá.
const _czCenter = LatLng(49.80, 15.47);
const _czZoom = 7.0;

/// Pod tímto zoomem se kreslí jen tečky — jmenovky ani odznaky nejsou čitelné.
const _compactBelowZoom = 10.0;

/// Od tohohle přiblížení se pod značku vypisuje jméno rozhledny.
///
/// Níž je ve výřezu tolik bodů, že by z jmenovek byla souvislá kaše a stejně
/// by se nedaly přečíst. Třináctka leží mezi zoomem, na který mapa startuje
/// u aktuální polohy (12), a tím, kam skáče tlačítko „moje poloha“ (14) —
/// takže se jména objeví hned, jak se člověk podívá na konkrétní kout.
const _labelsFromZoom = 13.0;

/// Zoom pro pohled „co mám kolem sebe“ — pár kilometrů na šířku obrazovky.
const _nearbyZoom = 12.0;

/// Průměr bílého očka v hlavičce špendlíku, do kterého se kreslí plus.
const _pinEye = 20.0;

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

  /// Kamera se drží celá kvůli přepočtu zeměpisných souřadnic na pixely —
  /// bez něj nejde poznat, které jmenovky by se na obrazovce překryly.
  MapCamera? _camera;

  /// Místo zapíchnuté dlouhým stiskem, odkud se dá založit nová rozhledna.
  LatLng? _pin;

  /// MapController vyhodí výjimku, když se na něj sáhne dřív, než se mapa
  /// poprvé vykreslí — a nastavení ze SharedPreferences dorazí právě dřív.
  bool _mapReady = false;

  StreamSubscription<MapEvent>? _events;

  /// Poskytovatel dlaždic přežívá překreslení.
  ///
  /// `CachedTileProvider` si v konstruktoru zakládá vlastního HTTP klienta.
  /// Vyrobit ho v `build` znamená nového klienta s prázdným poolem spojení na
  /// každý snímek posunu mapy — a ten předchozí po sobě nikdo neuklidí.
  TileProvider? _tiles;
  String? _tilesFor;

  /// Kanál, kterým se dlaždicová vrstva požádá o nové načtení, a hlídač,
  /// který o to po nepovedené dlaždici požádá. Bez něj zůstane rozmazaná
  /// mapa rozmazaná, dokud s ní člověk sám nepohne — viz [TileRetry].
  final _tileReset = StreamController<void>.broadcast();
  late final _tileRetry = TileRetry(
    onRetry: () {
      if (mounted && !_tileReset.isClosed) _tileReset.add(null);
    },
  );

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
    _tileRetry.dispose();
    _tileReset.close();
    _events?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Poskytovatel dlaždic pro daný podklad. Vyrobí se jednou a drží se.
  ///
  /// Dokud není připravená cache, vrací `null` a podklad se nekreslí vůbec.
  /// Vyžádat dlaždice dřív znamená poslat je mimo cache rovnou na síť — a ta
  /// po startu telefonu chvíli nemusí být. Cesta k adresáři cache je přitom
  /// otázka pár snímků, takže je to sotva postřehnutelné čekání.
  TileProvider? _tileProvider(String basemapId, AsyncValue<CacheStore> store) {
    if (store.isLoading) return null;
    if (_tilesFor != basemapId) {
      _tiles = store.hasValue
          ? CachedTileProvider(
              store: store.requireValue,
              maxStale: tileMaxStale,
            )
          : NetworkTileProvider();
      _tilesFor = basemapId;
    }
    return _tiles;
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
    MapEventSource.scrollWheel => true,
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
    // Jiný výřez znamená jiné dlaždice, takže i nové pokusy o načtení. Bez
    // toho by mapa po třech nepovedených zůstala bez opakování až do restartu.
    _tileRetry.viewChanged();
    setState(() {
      _bounds = camera.visibleBounds;
      _zoom = camera.zoom;
      _rotation = camera.rotation;
      _camera = camera;
    });
  }

  /// Které rozhledny ve výřezu dostanou jmenovku.
  ///
  /// Bez jména v datech není co psát — takových je v OSM zhruba třetina a
  /// prázdná jmenovka by jen odsadila značku od jejího bodu.
  Set<String> _labelled(List<TowerWithStats> visible) {
    final camera = _camera;
    if (camera == null || _zoom < _labelsFromZoom) return const {};
    return labelledMarkers([
      for (final t in visible)
        if (t.tower.name?.trim().isNotEmpty ?? false)
          (
            uuid: t.tower.uuid,
            pixel: camera.projectAtZoom(LatLng(t.tower.lat, t.tower.lon)),
          ),
    ]);
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
      if (_mapReady &&
          !next.allowRotation &&
          _controller.camera.rotation != 0) {
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
    final tiles = _tileProvider(
      basemap.id,
      ref.watch(tileCacheStoreProvider(basemap.id)),
    );
    final towers = ref.watch(towersProvider);
    final me = ref.watch(currentPositionProvider).value;
    final shown = shownTowers(
      towers.value ?? const [],
      showUnnamed: settings.showUnnamed,
    );
    final visible = _visible(shown);
    final labelled = _labelled(visible);

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
          // Stejné kulaté tlačítko jako kompas. Barevný FAB tu dřív křičel
          // přes mapu a velikostí se s kompasem nepotkal.
          MapRoundButton(
            tooltip: 'Moje poloha',
            onPressed: me == null ? null : () => _goTo(me),
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
              onTap: (_, _) => setState(() {
                _selectedUuid = null;
                _pin = null;
              }),
              // Dlouhý stisk zapíchne špendlík, formulář se otevře až z něj.
              // Napřímo by se otevřel nad místem, které uživatel pod prstem
              // neviděl — a souřadnice by pak opravoval poslepu v dialogu.
              onLongPress: (_, point) => setState(() => _pin = point),
            ),
            children: [
              // Podklad se objeví, teprve až je připravená cache dlaždic —
              // viz _tileProvider.
              if (tiles != null)
                TileLayer(
                  urlTemplate: basemap.url(apiKey),
                  userAgentPackageName: 'cz.standakouba.rozhledny',
                  maxNativeZoom: basemap.maxZoom,
                  tileProvider: tiles,
                  reset: _tileReset.stream,
                  errorTileCallback: (_, _, _) => _tileRetry.failed(),
                ),
              MarkerLayer(
                markers: [
                  for (final t in visible)
                    _towerMarker(t, withLabel: labelled.contains(t.tower.uuid)),
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
              // Nad ostatními vrstvami, ať špendlík nezmizí pod značkou
              // rozhledny, která už na tom místě je.
              if (_pin != null) MarkerLayer(markers: [_pinMarker(_pin!)]),
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
          // Jmenovatel se řídí nastavením: se skrytými bezejmennými by
          // „3 / 672“ tvrdilo, že na mapě chybí stovky bodů.
          _CountBadge(visible: visible.length, total: shown.length),
        ],
      ),
    );
  }

  Marker _towerMarker(TowerWithStats t, {required bool withLabel}) =>
      towerMarker(
        point: LatLng(t.tower.lat, t.tower.lon),
        visitCount: t.visitCount,
        compact: _zoom < _compactBelowZoom,
        selected: _selectedUuid == t.tower.uuid,
        // Nad pootočenou mapou musí text zůstat vodorovný, jinak se nepřečte.
        // Jen nad pootočenou: srovnaná mapa je výchozí stav a Transform
        // u každé ze sedmi stovek značek by mapě na plynulosti nepřidal.
        rotate: _rotation != 0,
        label: withLabel ? t.tower.name : null,
        onTap: () {
          setState(() => _selectedUuid = t.tower.uuid);
          TowerDetailSheet.show(context, t.tower.uuid);
        },
      );

  void _goTo(Position me) => _controller.move(
    LatLng(me.latitude, me.longitude),
    // Zoom, ve kterém jsou vidět jednotlivé rozhledny i cesty k nim.
    _zoom < 13 ? 14 : _zoom,
  );

  /// Špendlík se znaménkem plus.
  ///
  /// Dlouhý stisk sám o sobě formulář neotevírá: uživatel má nejdřív vidět,
  /// kam prst doopravdy mířil. Trefit se pod bříškem prstu na deset metrů
  /// nejde a opravovat souřadnice v dialogu je horší než posunout špendlík
  /// dalším stiskem.
  Marker _pinMarker(LatLng point) {
    const pin = 44.0;

    return Marker(
      point: point,
      width: pin,
      height: pin,
      // Na vybraném místě musí sedět hrot špendlíku, ne střed obrázku.
      alignment: Marker.computePixelAlignment(
        width: pin,
        height: pin,
        left: pin / 2,
        top: pin,
      ),
      rotate: true,
      child: Tooltip(
        message: 'Přidat rozhlednu tady',
        child: GestureDetector(
          onTap: _addTowerAtPin,
          // Plus sedí přímo v hlavičce špendlíku, ne vedle něj. Samostatné
          // tlačítko mířilo jinam, než kam ukazuje hrot, a na malém displeji
          // si obojí překáželo.
          //
          // Skládá se ze dvou kusů, protože `add_location_alt` je jednobarevná
          // a plus by tím pádem muselo mít barvu celého špendlíku. Takhle nese
          // barvu jen ta část, která říká „klepni sem a přidej“.
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Icon(
                Icons.place,
                size: pin,
                // Táž šedá jako značka dosud nenavštívené rozhledny — na mapě
                // je tak jedna šedá, ne dvě podobné. Barvu si nese až plus,
                // které jediné znamená akci.
                color: unvisitedColor,
                shadows: [
                  // Bílá zář odděluje špendlík od tmavších míst mapy, stín pod
                  // ním ho zvedá nad podklad.
                  Shadow(color: Colors.white, blurRadius: 3),
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              // Bílé očko zakrývá díru, kterou má hlavička špendlíku v sobě,
              // a dělá zelenému plus čitelné pozadí. Střed hlavičky leží
              // v 0,40 výšky ikony — odtud to odsazení.
              Positioned(
                top: pin * 0.40 - _pinEye / 2,
                child: Container(
                  width: _pinEye,
                  height: _pinEye,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: _pinEye - 4,
                    color: brandColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addTowerAtPin() async {
    final point = _pin;
    if (point == null) return;
    await TowerEditorSheet.show(context, initialPoint: point);
    // Špendlík už udělal svoje; nechat ho na mapě by jen mátlo.
    if (mounted) setState(() => _pin = null);
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
              color: Theme.of(context).colorScheme.surface
                  .withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$visible / $total',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
    );
  }
}
