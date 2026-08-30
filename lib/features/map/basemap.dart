import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Definice mapového podkladu.
///
/// Mapová obrazovka nezná žádnou konkrétní URL — bere ji odsud. Přidat nebo
/// prohodit podklad je tak úprava tohoto seznamu, ne zásah do mapy.
///
/// Atribuce je součástí definice schválně: každý poskytovatel ji vyžaduje jinak
/// (Mapy.com logo s odkazem, OSM textovou poznámku), a když by seděla natvrdo
/// v mapě, bylo by snadné ji při přepnutí podkladu nechat špatnou.
class MapBasemap {
  const MapBasemap({
    required this.id,
    required this.label,
    required this.urlTemplate,
    required this.attributionBuilder,
    this.requiresApiKey = false,
    this.maxZoom = 19,
  });

  /// Klíč do nastavení a zároveň do cache dlaždic — po přepnutí podkladu se
  /// nesmí míchat dlaždice z různých zdrojů.
  final String id;
  final String label;

  /// Šablona s `{z}/{x}/{y}`; u placených zdrojů i `{apiKey}`.
  final String urlTemplate;
  final bool requiresApiKey;
  final int maxZoom;
  final WidgetBuilder attributionBuilder;

  String url(String? apiKey) =>
      urlTemplate.replaceAll('{apiKey}', apiKey ?? '');

  /// Podklad je použitelný, jen když má případný klíč.
  bool isUsable(String? apiKey) =>
      !requiresApiKey || (apiKey != null && apiKey.trim().isNotEmpty);
}

/// Turistická mapa Seznamu. Značené trasy a vrstevnice z ní dělají nejlepší
/// podklad pro hledání rozhleden; free tier je 250 tis. dlaždic měsíčně.
const mapyOutdoor = MapBasemap(
  id: 'mapy_outdoor',
  label: 'Turistická (Mapy.com)',
  urlTemplate:
      'https://api.mapy.com/v1/maptiles/outdoor/256/{z}/{x}/{y}?apikey={apiKey}',
  requiresApiKey: true,
  maxZoom: 19,
  attributionBuilder: _mapyAttribution,
);

const mapyAerial = MapBasemap(
  id: 'mapy_aerial',
  label: 'Letecká (Mapy.com)',
  urlTemplate:
      'https://api.mapy.com/v1/maptiles/aerial/256/{z}/{x}/{y}?apikey={apiKey}',
  requiresApiKey: true,
  maxZoom: 20,
  attributionBuilder: _mapyAttribution,
);

/// Záloha bez klíče — funguje hned po instalaci a při vyčerpaném free tieru.
const osmStandard = MapBasemap(
  id: 'osm',
  label: 'OpenStreetMap',
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  maxZoom: 19,
  attributionBuilder: _osmAttribution,
);

/// OpenStreetMap je první, protože je výchozí a funguje bez klíče.
/// Podklady Mapy.com jdou vybrat, teprve když si uživatel zadá vlastní klíč.
const basemaps = <MapBasemap>[osmStandard, mapyOutdoor, mapyAerial];

MapBasemap basemapById(String? id) =>
    basemaps.firstWhere((b) => b.id == id, orElse: () => osmStandard);

// ------------------------------------------------------------------ atribuce

/// Podmínky Mapy.com (developer.mapy.com/rest-api-mapy-cz/atribution):
/// logo minimálně 30 px vysoké s odkazem na mapy.com **a vedle něj** text
/// „Seznam.cz a.s. and others“ odkazující na jejich copyright.
/// Obojí musí být viditelné nad mapou — proto tu nejsou volitelné rozměry.
const _mapyLogoMinHeight = 30.0;

Widget _mapyAttribution(BuildContext context) => _AttributionBar(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _open('https://mapy.com/'),
            child: SvgPicture.network(
              'https://api.mapy.com/img/api/logo.svg',
              height: _mapyLogoMinHeight,
              placeholderBuilder: (_) => const SizedBox(
                height: _mapyLogoMinHeight,
                child: Center(
                  child: Text('mapy.com',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _open('https://api.mapy.com/copyright'),
            child: const Text(
              'Seznam.cz a.s. and others',
              style: TextStyle(fontSize: 11, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );

Widget _osmAttribution(BuildContext context) => _AttributionBar(
      child: GestureDetector(
        onTap: () => _open('https://www.openstreetmap.org/copyright'),
        child: const Text('© OpenStreetMap contributors',
            style: TextStyle(fontSize: 11)),
      ),
    );

Future<void> _open(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Podklad pod atribuci. Světlý i v tmavém režimu — leží na mapě, ne na pozadí
/// aplikace, a logo Mapy.com je navržené na světlo.
class _AttributionBar extends StatelessWidget {
  const _AttributionBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.black87),
        child: child,
      ),
    );
  }
}
