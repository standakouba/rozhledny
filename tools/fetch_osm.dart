// Generátor výchozí sady rozhleden z OpenStreetMap.
//
// Není součástí aplikace — spouští se ručně a jeho výstupem je asset
// assets/data/rozhledny.json, který se zabalí do APK a při prvním spuštění
// se naseeduje do lokální databáze.
//
//   dart tools/fetch_osm.dart
//
// Bez závislostí (jen dart:io / dart:convert), aby šel spustit i bez `pub get`.

import 'dart:convert';
import 'dart:math';
import 'dart:io';

/// Overpass instance; při chybě se zkouší další v pořadí.
const _endpoints = <String>[
  // overpass-api.de je jediny, ktery timhle dotazem spolehlive projde.
  // Pozor: po davce dotazu odrizne IP na urovni site (odmitnute spojeni)
  // a trva desitky minut, nez pusti zpatky — proto ten odstup mezi kraji.
  // kumi a private.coffee jsou jeden backend pod dvema jmeny a jejich
  // /api/interpreter casto vraci 500 i na trivialni dotaz.
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

/// Rozhledna v OSM = `tower:type=observation`. Druhý řádek dobírá věže
/// značené jen jako vyhlídka, které první filtr mine.
const _towerFilter = '''
  nwr(area.reg)["tower:type"="observation"];
  nwr(area.reg)["man_made"="tower"]["tourism"="viewpoint"];
''';

const _outPath = 'assets/data/rozhledny.json';

/// Syrová odpověď prvního dotazu. Overpass je nespolehlivý a přiřazování krajů
/// se občas rozbije v půlce — díky cache se pak nestahuje 700 rozhleden znovu.
/// Smaž soubor (nebo pusť s `--fresh`), když chceš čerstvá data.
const _cachePath = '.cache/osm_towers_raw.json';
const _regionCachePath = '.cache/qlever_regions.json';

Future<void> main(List<String> args) async {
  final sw = Stopwatch()..start();
  final fresh = args.contains('--fresh');

  stdout.writeln('1/2  Stahuji rozhledny v CR (Overpass)...');
  final elements = await _cached(_cachePath, fresh, () => _overpass('''
[out:json][timeout:600];
area["ISO3166-1"="CZ"][admin_level=2]->.reg;
(
$_towerFilter);
out center tags;
'''));
  final towers = _parseTowers(elements);
  stdout.writeln('     ${towers.length} rozhleden');

  stdout.writeln('2/2  Prirazuji kraje (QLever, jeden dotaz)...');
  final byRegion = await _cachedMap(_regionCachePath, fresh, _fetchRegions);
  final counts = <String, int>{};
  for (final t in towers) {
    final region = byRegion[t.key];
    if (region != null) {
      t.region = region;
      counts[region] = (counts[region] ?? 0) + 1;
    }
  }
  for (final e in counts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key))) {
    stdout.writeln('     ${e.key.padRight(24)} ${e.value}');
  }

  towers.sort(_byName);

  final missingRegion = towers.where((t) => t.region == null).toList();
  final unnamed = towers.where((t) => t.name == null).length;

  final out = File(_outPath);
  await out.parent.create(recursive: true);
  await out.writeAsString(const JsonEncoder.withIndent('  ').convert({
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'area': 'CZ',
    'source': 'OpenStreetMap contributors (ODbL)',
    'count': towers.length,
    'towers': towers.map((t) => t.toJson()).toList(),
  }));

  stdout
    ..writeln('')
    ..writeln('Hotovo za ${sw.elapsed.inSeconds}s -> $_outPath '
        '(${(out.lengthSync() / 1024).round()} kB)')
    ..writeln('  rozhleden ............ ${towers.length}')
    ..writeln('  bez nazvu ............ $unnamed')
    ..writeln('  bez kraje ............ ${missingRegion.length}');
  for (final t in missingRegion.take(20)) {
    stdout.writeln('      ! ${t.name ?? "(bez nazvu)"}  ${t.lat},${t.lon}');
  }
}

/// Pojmenované napřed a podle abecedy, nepojmenované na konec.
int _byName(_Tower a, _Tower b) {
  if (a.name == null || b.name == null) {
    if (a.name == b.name) return a.key.compareTo(b.key);
    return a.name == null ? 1 : -1;
  }
  return a.name!.toLowerCase().compareTo(b.name!.toLowerCase());
}

// ---------------------------------------------------------------- Overpass

/// Spustí [fetch], nebo vrátí dřív uloženou odpověď, pokud existuje.
Future<List<dynamic>> _cached(
  String path,
  bool fresh,
  Future<List<dynamic>> Function() fetch,
) async {
  final file = File(path);
  if (!fresh && file.existsSync()) {
    stdout.writeln('     (z cache $path, --fresh vynuti nove stazeni)');
    return jsonDecode(await file.readAsString()) as List<dynamic>;
  }
  final data = await fetch();
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(data));
  return data;
}

/// Totéž co [_cached], jen pro dotaz vracející mapu.
Future<Map<String, String>> _cachedMap(
  String path,
  bool fresh,
  Future<Map<String, String>> Function() fetch,
) async {
  final file = File(path);
  if (!fresh && file.existsSync()) {
    stdout.writeln('     (z cache $path)');
    return (jsonDecode(await file.readAsString()) as Map<String, dynamic>)
        .cast<String, String>();
  }
  final data = await fetch();
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(data));
  return data;
}

/// Zavolá Overpass a vrátí pole `elements`. Zkouší postupně všechny instance,
/// každou s exponenciálním odstupem — veřejné servery běžně vracejí 429/504.
Future<List<dynamic>> _overpass(String query) async {
  Object? lastError;
  for (final endpoint in _endpoints) {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        final wait = Duration(seconds: 5 * attempt * attempt);
        stdout.writeln('     ...cekam ${wait.inSeconds}s a zkousim znovu');
        await Future<void>.delayed(wait);
      }
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 30);
        try {
          final req = await client.postUrl(Uri.parse(endpoint));
          req.headers.set(HttpHeaders.contentTypeHeader,
              'application/x-www-form-urlencoded; charset=utf-8');
          req.headers.set(HttpHeaders.userAgentHeader,
              'rozhledny-app-data-generator/1.0 (osobni projekt)');
          req.add(utf8.encode('data=${Uri.encodeQueryComponent(query)}'));
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join();
          if (res.statusCode != 200) {
            lastError = 'HTTP ${res.statusCode} z $endpoint: '
                '${body.substring(0, body.length.clamp(0, 300))}';
            continue;
          }
          return (jsonDecode(body) as Map<String, dynamic>)['elements']
              as List<dynamic>;
        } finally {
          client.close();
        }
      } catch (e) {
        lastError = '$endpoint: $e';
      }
    }
    stdout.writeln('     $endpoint nefunguje ($lastError), zkousim dalsi');
  }
  throw StateError('Overpass se nepodarilo zavolat. Posledni chyba: $lastError');
}

// ------------------------------------------------------------------ QLever

/// SPARQL nad OSM planetou (Uni Freiburg). Jiná infrastruktura než Overpass,
/// a hlavně jiný způsob dotazování: přiřazení krajů je tu **jeden** dotaz.
///
/// Přes Overpass by to bylo 14 dotazů, a ten po čtyřech pěti odřízne IP
/// na desítky minut — celý běh se tak nikdy nedostal za třetí kraj.
const _qleverEndpoint = 'https://qlever.dev/api/osm-planet';

/// Relace České republiky v OSM.
const _czRelation = 51684;

/// Vrátí mapu `node/123` -> `Jihočeský kraj`.
///
/// Dvě pasti, na které se dá narazit:
/// - `admin_level` je v datech `xsd:int`, ne řetězec — `"4"` nevrátí nic;
/// - `sfContains` chytá i hraniční *cesty*, proto omezení na `rdf:type` relace.
///   Bez něj vyjde místo 14 krajů 1667 objektů.
Future<Map<String, String>> _fetchRegions() async {
  final body = await _sparql('''
PREFIX osmkey: <https://www.openstreetmap.org/wiki/Key:>
PREFIX ogc: <http://www.opengis.net/rdf#>
PREFIX osmrel: <https://www.openstreetmap.org/relation/>
PREFIX osm: <https://www.openstreetmap.org/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT ?s ?kraj WHERE {
  osmrel:$_czRelation ogc:sfContains ?k .
  ?k rdf:type osm:relation .
  ?k osmkey:admin_level 4 .
  ?k osmkey:name ?kraj .
  ?k ogc:sfContains ?s .
  { ?s osmkey:tower:type "observation" }
  UNION
  { ?s osmkey:man_made "tower" . ?s osmkey:tourism "viewpoint" }
}
''');

  final bindings = (body['results'] as Map<String, dynamic>)['bindings'] as List;
  final result = <String, String>{};
  for (final raw in bindings) {
    final b = raw as Map<String, dynamic>;
    final iri = b['s']['value'] as String;
    final kraj = b['kraj']['value'] as String;
    // https://www.openstreetmap.org/node/123 -> node/123
    final parts = iri.split('/');
    if (parts.length < 2) continue;
    result['${parts[parts.length - 2]}/${parts.last}'] = kraj;
  }

  final regionCount = result.values.toSet().length;
  if (regionCount != 14) {
    stderr.writeln('     ! cekal jsem 14 kraju, dostal $regionCount');
  }
  return result;
}

Future<Map<String, dynamic>> _sparql(String query) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 60);
  try {
    final req = await client.postUrl(Uri.parse(_qleverEndpoint));
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/sparql-query');
    req.headers.set(HttpHeaders.acceptHeader, 'application/sparql-results+json');
    req.headers.set(HttpHeaders.userAgentHeader,
        'rozhledny-app-data-generator/1.0 (osobni projekt)');
    req.add(utf8.encode(query));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw StateError('QLever HTTP ${res.statusCode}: '
          '${body.substring(0, body.length.clamp(0, 400))}');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}

// ------------------------------------------------------------------ Model

List<_Tower> _parseTowers(List<dynamic> elements) {
  final byKey = <String, _Tower>{};
  for (final raw in elements) {
    final e = raw as Map<String, dynamic>;
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};

    // Nodes mají lat/lon přímo, ways a relations jen `center` z `out center`.
    final lat = (e['lat'] ?? (e['center'] as Map?)?['lat']) as num?;
    final lon = (e['lon'] ?? (e['center'] as Map?)?['lon']) as num?;
    if (lat == null || lon == null) continue;

    final tower = _Tower(
      osmType: e['type'] as String,
      osmId: e['id'] as int,
      name: _str(tags['name']),
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      height: _num(tags['height'] ?? tags['building:height']),
      ele: _num(tags['ele']),
      website: _str(tags['website'] ?? tags['contact:website'] ?? tags['url']),
      openingHours: _str(tags['opening_hours']),
      fee: _str(tags['fee']),
      access: _str(tags['access']),
      operator: _str(tags['operator']),
      wikidata: _str(tags['wikidata']),
    );
    byKey[tower.key] = tower;
  }
  return _dedupeByProximity(byKey.values.toList());
}

/// Dvě rozhledny patnáct metrů od sebe neexistují.
///
/// Stejná rozhledna je v OSM běžně dvakrát — jako bod a jako obrys stavby —
/// a názvy se přitom liší natolik, že párování podle jména nestačí
/// („Milešovka“ vs „Rozhledna Milešovka“, „Doubrava“ vs „Rozhledna Doubrava“).
/// Práh je schválně nízký: ve 40–50 m od sebe už stojí skutečné samostatné
/// vyhlídky (Křeslo, Lavička, Silo u Kroměříže), které se slučovat nesmí.
List<_Tower> _dedupeByProximity(List<_Tower> towers) {
  const thresholdMeters = 15.0;
  final dropped = <int>{};

  for (var i = 0; i < towers.length; i++) {
    if (dropped.contains(i)) continue;
    for (var k = i + 1; k < towers.length; k++) {
      if (dropped.contains(k)) continue;
      final a = towers[i], b = towers[k];
      if (_distanceMeters(a.lat, a.lon, b.lat, b.lon) > thresholdMeters) {
        continue;
      }
      // Vyhrává bohatší záznam; jméno váží nejvíc.
      final keepA = a.score >= b.score;
      final keep = keepA ? a : b;
      final drop = keepA ? b : a;
      dropped.add(keepA ? k : i);
      stdout.writeln('     slouceno: "${drop.name ?? "(bez nazvu)"}" '
          '(${drop.key}) -> "${keep.name ?? "(bez nazvu)"}" (${keep.key})');
      if (!keepA) break; // i vypadlo, dál se s ním nesrovnává
    }
  }

  return [
    for (var i = 0; i < towers.length; i++)
      if (!dropped.contains(i)) towers[i],
  ];
}

/// Haversine. Na patnáctimetrovém prahu by stačila i rovinná aproximace,
/// ale tohle je stejně levné a nemusí se řešit zeměpisná šířka.
double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

String? _str(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

/// „25 m“, „25.5“, „cca 30“ -> 25 / 25.5 / 30. Nečitelné hodnoty zahodí.
double? _num(Object? v) {
  final s = _str(v);
  if (s == null) return null;
  final m = RegExp(r'-?\d+([.,]\d+)?').firstMatch(s);
  return m == null ? null : double.tryParse(m[0]!.replaceAll(',', '.'));
}

class _Tower {
  _Tower({
    required this.osmType,
    required this.osmId,
    required this.name,
    required this.lat,
    required this.lon,
    this.height,
    this.ele,
    this.website,
    this.openingHours,
    this.fee,
    this.access,
    this.operator,
    this.wikidata,
  });

  final String osmType;
  final int osmId;
  final String? name;
  final double lat;
  final double lon;
  final double? height;
  final double? ele;
  final String? website;
  final String? openingHours;
  final String? fee;
  final String? access;
  final String? operator;
  final String? wikidata;
  String? region;

  String get key => '$osmType/$osmId';

  /// Kolik toho o rozhledně víme. Rozhoduje, který ze dvou záznamů téhož místa
  /// přežije slučování — název váží nejvíc, protože bez něj je bod na mapě němý.
  int get score =>
      (name != null ? 10 : 0) +
      [height, ele, website, openingHours, fee, access, operator, wikidata]
          .where((v) => v != null)
          .length;

  Map<String, dynamic> toJson() => {
        'osmType': osmType,
        'osmId': osmId,
        if (name != null) 'name': name,
        'lat': double.parse(lat.toStringAsFixed(6)),
        'lon': double.parse(lon.toStringAsFixed(6)),
        if (height != null) 'height': height,
        if (ele != null) 'ele': ele,
        if (region != null) 'region': region,
        if (website != null) 'website': website,
        if (openingHours != null) 'openingHours': openingHours,
        if (fee != null) 'fee': fee,
        if (access != null) 'access': access,
        if (operator != null) 'operator': operator,
        if (wikidata != null) 'wikidata': wikidata,
      };
}
