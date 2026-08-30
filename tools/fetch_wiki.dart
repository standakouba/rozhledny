// Doplní k rozhlednám popis a fotku z Wikidat, české Wikipedie a Commons.
//
// Spouští se po tools/fetch_osm.dart a přepisuje týž asset:
//
//   dart tools/fetch_osm.dart
//   dart tools/fetch_wiki.dart
//
// Proč ne Mapy.cz: jejich veřejné REST API nemá endpoint na detail místa (jen
// dlaždice, geokódování, routing, výškopis, statické mapy, časová pásma,
// panorama). Popisy a fotky na webu mapy.cz jedou přes interní rozhraní, které
// není součástí licencovaného API — použít ho by porušovalo jejich podmínky.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _outPath = 'assets/data/rozhledny.json';
const _wikidataCache = '.cache/wikidata_towers.json';
const _extractCache = '.cache/wikipedia_extracts.json';
const _commonsCache = '.cache/commons_images.json';

/// Wikidata třída „rozhledna“.
const _rozhlednaClass = 'Q1440300';

/// Česká republika ve Wikidatech.
const _czechia = 'Q213';

/// Dvě rozhledny sto metrů od sebe neexistují, takže shoda na téhle vzdálenosti
/// je bezpečná. Vyšší práh už jen přidává riziko: 250 m přinese o 13 párů víc,
/// 500 m o dalších 12 — a přitom roste šance, že se text přilepí k jiné věži.
const _matchRadiusMeters = 100.0;

/// Delší text se do karty v detailu stejně nevejde.
const _maxExtractChars = 700;

const _userAgent = 'rozhledny-app/1.0 (osobni projekt; kontakt pres GitHub)';

Future<void> main(List<String> args) async {
  final sw = Stopwatch()..start();
  final fresh = args.contains('--fresh');

  final file = File(_outPath);
  if (!file.existsSync()) {
    stderr.writeln('Chybí $_outPath — nejdřív pusť dart tools/fetch_osm.dart');
    exit(1);
  }
  final doc = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final towers = (doc['towers'] as List).cast<Map<String, dynamic>>();
  stdout.writeln('Rozhleden v assetu: ${towers.length}');

  stdout.writeln('\n1/4  Wikidata: rozhledny v ČR...');
  final items = await _cached(_wikidataCache, fresh, _fetchWikidata);
  stdout.writeln('     ${items.length} položek');

  stdout.writeln('\n2/4  Párování...');
  final matches = _match(towers, items);
  stdout.writeln('     spárováno ${matches.length} z ${towers.length}');

  stdout.writeln('\n3/4  Wikipedie: výtahy...');
  final titles = <String>{
    for (final m in matches.values)
      if (m.wikipediaTitle != null) m.wikipediaTitle!,
  };
  final extracts =
      await _cachedBatches(_extractCache, fresh, titles, _fetchExtracts);
  stdout.writeln('     ${extracts.length} textů');

  stdout.writeln('\n4/4  Commons: fotky, autoři a licence...');
  final fileNames = <String>{
    for (final m in matches.values)
      if (m.commonsFile != null) m.commonsFile!,
  };
  final images =
      await _cachedBatches(_commonsCache, fresh, fileNames, _fetchImages);
  stdout.writeln('     ${images.length} fotek');

  // Zápis zpátky do assetu
  var withText = 0, withPhoto = 0, photoNoAttribution = 0;
  for (final tower in towers) {
    final key = '${tower['osmType']}/${tower['osmId']}';
    final m = matches[key];

    // Pole se vždycky nejdřív vyhodí — po přegenerování nesmí zůstat viset
    // popis rozhledny, která se mezitím přestala párovat.
    for (final field in const [
      'wikidataId', 'wikipediaTitle', 'wikipediaUrl', 'wikipediaExtract',
      'photoUrl', 'photoAuthor', 'photoLicense', 'photoLicenseUrl',
      'photoPageUrl',
    ]) {
      tower.remove(field);
    }
    if (m == null) continue;

    tower['wikidataId'] = m.wikidataId;

    final extract = m.wikipediaTitle == null ? null : extracts[m.wikipediaTitle];
    if (extract != null && extract.isNotEmpty) {
      tower['wikipediaTitle'] = m.wikipediaTitle;
      tower['wikipediaUrl'] = m.wikipediaUrl;
      tower['wikipediaExtract'] = _trim(extract);
      withText++;
    }

    final image = m.commonsFile == null ? null : images[m.commonsFile];
    if (image != null) {
      final parts = jsonDecode(image) as Map<String, dynamic>;
      // Fotka bez autora a licence se nepublikuje — Commons u těchhle snímků
      // hlásí AttributionRequired a bez atribuce by šlo o porušení licence.
      if (parts['author'] == null || parts['license'] == null) {
        photoNoAttribution++;
      } else {
        tower['photoUrl'] = parts['url'];
        tower['photoAuthor'] = parts['author'];
        tower['photoLicense'] = parts['license'];
        if (parts['licenseUrl'] != null) {
          tower['photoLicenseUrl'] = parts['licenseUrl'];
        }
        tower['photoPageUrl'] = parts['pageUrl'];
        withPhoto++;
      }
    }
  }

  doc['enrichedAt'] = DateTime.now().toUtc().toIso8601String();
  doc['enrichmentSource'] =
      'Wikidata, Wikipedia (CC BY-SA), Wikimedia Commons';
  await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(doc));

  stdout
    ..writeln('')
    ..writeln('Hotovo za ${sw.elapsed.inSeconds}s -> $_outPath '
        '(${(file.lengthSync() / 1024).round()} kB)')
    ..writeln('  s popisem ............ $withText')
    ..writeln('  s fotkou ............. $withPhoto')
    ..writeln('  fotka bez atribuce ... $photoNoAttribution (vynechána)');
}

String _trim(String text) {
  if (text.length <= _maxExtractChars) return text;
  // Radši kratší text končící větou než uříznuté slovo.
  final cut = text.substring(0, _maxExtractChars);
  final lastStop = cut.lastIndexOf('. ');
  return lastStop > _maxExtractChars ~/ 2
      ? cut.substring(0, lastStop + 1)
      : '$cut…';
}

// ---------------------------------------------------------------- Wikidata

class _WikiItem {
  _WikiItem({
    required this.id,
    required this.label,
    required this.lat,
    required this.lon,
    this.wikipediaUrl,
    this.commonsFile,
  });

  final String id;
  final String label;
  final double lat;
  final double lon;
  final String? wikipediaUrl;
  final String? commonsFile;

  String? get wikipediaTitle => wikipediaUrl == null
      ? null
      : Uri.decodeComponent(wikipediaUrl!.split('/wiki/').last)
          .replaceAll('_', ' ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'lat': lat,
        'lon': lon,
        if (wikipediaUrl != null) 'wikipediaUrl': wikipediaUrl,
        if (commonsFile != null) 'commonsFile': commonsFile,
      };

  static _WikiItem fromJson(Map<String, dynamic> j) => _WikiItem(
        id: j['id'] as String,
        label: j['label'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        wikipediaUrl: j['wikipediaUrl'] as String?,
        commonsFile: j['commonsFile'] as String?,
      );

  String get wikidataId => id;
}

Future<List<_WikiItem>> _fetchWikidata() async {
  final body = await _getJson(Uri.parse(
      'https://query.wikidata.org/sparql?format=json&query=${Uri.encodeQueryComponent('''
SELECT ?item ?itemLabel ?coord ?cs ?img WHERE {
  ?item wdt:P31/wdt:P279* wd:$_rozhlednaClass ; wdt:P17 wd:$_czechia ; wdt:P625 ?coord .
  OPTIONAL { ?cs schema:about ?item ; schema:isPartOf <https://cs.wikipedia.org/> . }
  OPTIONAL { ?item wdt:P18 ?img . }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "cs,en". }
}
''')}'));

  final point = RegExp(r'Point\(([-0-9.]+) ([-0-9.]+)\)');
  final byId = <String, _WikiItem>{};
  for (final raw in (body['results'] as Map)['bindings'] as List) {
    final b = raw as Map<String, dynamic>;
    final id = (b['item']['value'] as String).split('/').last;
    if (byId.containsKey(id)) continue;
    final m = point.firstMatch(b['coord']['value'] as String);
    if (m == null) continue;

    byId[id] = _WikiItem(
      id: id,
      label: b['itemLabel']?['value'] as String? ?? id,
      lat: double.parse(m[2]!),
      lon: double.parse(m[1]!),
      wikipediaUrl: b['cs']?['value'] as String?,
      // P18 přijde jako .../Special:FilePath/Nazev%20souboru.jpg
      commonsFile: b['img'] == null
          ? null
          : Uri.decodeComponent(
              (b['img']['value'] as String).split('FilePath/').last),
    );
  }
  return byId.values.toList();
}

// ---------------------------------------------------------------- párování

/// Spáruje naše rozhledny s Wikidaty.
///
/// Přednost má `wikidata` tag z OSM — je to explicitní tvrzení mapera, ne dohad.
/// Teprve když chybí, hledá se nejbližší položka do [_matchRadiusMeters].
Map<String, _WikiItem> _match(
  List<Map<String, dynamic>> towers,
  List<_WikiItem> items,
) {
  final byId = {for (final i in items) i.id: i};
  final result = <String, _WikiItem>{};
  final usedItems = <String>{};
  var byTag = 0, byDistance = 0;
  final suspicious = <String>[];

  // Nejdřív jistoty podle tagu, ať proximita nesebere položku někomu,
  // kdo na ni má explicitní odkaz.
  for (final t in towers) {
    final tag = t['wikidata'] as String?;
    if (tag == null) continue;
    final item = byId[tag];
    if (item == null) continue;
    result['${t['osmType']}/${t['osmId']}'] = item;
    usedItems.add(item.id);
    byTag++;
  }

  for (final t in towers) {
    final key = '${t['osmType']}/${t['osmId']}';
    if (result.containsKey(key)) continue;

    _WikiItem? best;
    var bestDistance = double.infinity;
    for (final item in items) {
      if (usedItems.contains(item.id)) continue;
      final d = _distanceMeters(
          (t['lat'] as num).toDouble(), (t['lon'] as num).toDouble(),
          item.lat, item.lon);
      if (d < bestDistance) {
        bestDistance = d;
        best = item;
      }
    }
    if (best == null || bestDistance > _matchRadiusMeters) continue;

    result[key] = best;
    usedItems.add(best.id);
    byDistance++;

    // Shoda podle vzdálenosti s úplně jiným názvem je nejpravděpodobnější
    // místo, kde se text přilepí ke špatné věži — proto se vypisuje.
    final ourName = t['name'] as String?;
    if (ourName != null && !_namesOverlap(ourName, best.label)) {
      suspicious.add('     ? ${bestDistance.round()}m: "$ourName" '
          '-> "${best.label}" (${best.id})');
    }
  }

  stdout.writeln('     podle wikidata tagu: $byTag, podle vzdálenosti: $byDistance');
  if (suspicious.isNotEmpty) {
    stdout.writeln('     ${suspicious.length} párů s odlišným názvem '
        '(zkontroluj namátkou):');
    for (final s in suspicious.take(25)) {
      stdout.writeln(s);
    }
  }
  return result;
}

/// Sdílí dvojice názvů aspoň jedno delší slovo? „Kleť“ vs „Rozhledna Kleť“ ano,
/// „Jarník“ vs „Bezděz“ ne. Slouží jen k označení podezřelých párů, nic nefiltruje.
bool _namesOverlap(String a, String b) {
  Set<String> words(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-záčďéěíňóřšťúůýž ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 3 && w != 'rozhledna' && w != 'věž')
      .toSet();
  return words(a).intersection(words(b)).isNotEmpty;
}

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// --------------------------------------------------------------- Wikipedie

/// Úvodní odstavce článků. `titles` snese 20 názvů na dotaz, takže 250 článků
/// je 13 requestů místo 250.
Future<void> _fetchExtracts(List<String> batch, Map<String, String> into) async {
  final body = await _getJson(Uri.parse(
      'https://cs.wikipedia.org/w/api.php?action=query&format=json'
      '&formatversion=2&prop=extracts&exintro=1&explaintext=1&redirects=1'
      '&titles=${Uri.encodeQueryComponent(batch.join('|'))}'));

  // Redirecty a normalizace mění název, takže se musí zmapovat zpátky
  // na to, o co jsme žádali — jinak by se text k rozhledně nepřiřadil.
  final alias = <String, String>{};
  for (final key in const ['normalized', 'redirects']) {
    for (final r in ((body['query'] as Map)[key] as List? ?? const [])) {
      alias[(r as Map)['to'] as String] = r['from'] as String;
    }
  }

  // Každý název z dávky dostane záznam, i když článek výtah nemá. Prázdná
  // hodnota znamená „zjištěno, nic tam není“ — bez toho by se takové články
  // stahovaly při každém dalším běhu znovu.
  for (final title in batch) {
    into[title] = '';
  }
  for (final raw in (body['query'] as Map)['pages'] as List) {
    final page = raw as Map<String, dynamic>;
    final extract = page['extract'] as String?;
    if (extract == null || extract.trim().isEmpty) continue;
    final title = page['title'] as String;
    into[alias[title] ?? title] = extract.trim();
  }
}

// ----------------------------------------------------------------- Commons

/// Náhled 800 px plus autor a licence. Bez autora a licence se fotka zahodí.
Future<void> _fetchImages(List<String> batch, Map<String, String> into) async {
  final titles = batch.map((f) => 'File:$f').join('|');
  final body = await _getJson(Uri.parse(
      'https://commons.wikimedia.org/w/api.php?action=query&format=json'
      '&formatversion=2&prop=imageinfo&iiprop=url|extmetadata'
      '&iiurlwidth=800&titles=${Uri.encodeQueryComponent(titles)}'));

  for (final name in batch) {
    into[name] = '';
  }
  for (final raw in (body['query'] as Map)['pages'] as List) {
    final page = raw as Map<String, dynamic>;
    final info =
        (page['imageinfo'] as List?)?.firstOrNull as Map<String, dynamic>?;
    if (info == null) continue;
    final meta = (info['extmetadata'] as Map?)?.cast<String, dynamic>() ?? {};

    final fileName = (page['title'] as String).replaceFirst('File:', '');
    into[fileName] = jsonEncode({
      // Special:FilePath místo `thumburl`: ten se u menších snímků nevrací
      // vůbec a spadlo by se na originál — u Kletě 1500 px na mobil.
      // FilePath škáluje vždy a nikdy nepřekročí originál.
      'url': 'https://commons.wikimedia.org/wiki/Special:FilePath/'
          '${Uri.encodeComponent(fileName)}?width=800',
      'pageUrl': _stripTracking(info['descriptionurl'] as String),
      'author': _plain(meta['Artist']?['value'] as String?),
      'license': _plain(meta['LicenseShortName']?['value'] as String?),
      'licenseUrl': meta['LicenseUrl']?['value'],
    });
  }
}

/// Commons vrací autora jako HTML (odkazy, span s jazykem). Do karty patří text.
String? _plain(String? html) {
  if (html == null) return null;
  final text = html
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.isEmpty ? null : text;
}

/// API do URL přilepí utm_* parametry; v aplikaci jen kazí cache klíč.
///
/// Pozor: `Uri.replace(queryParameters: null)` dotaz **nesmaže**, jen ho nechá
/// být — prázdný dotaz se musí předat jako `query: ''`.
String _stripTracking(String url) {
  final uri = Uri.parse(url);
  final kept = {
    for (final e in uri.queryParameters.entries)
      if (!e.key.startsWith('utm_')) e.key: e.value,
  };
  return (kept.isEmpty
          ? uri.replace(query: '')
          : uri.replace(queryParameters: kept))
      .toString()
      .replaceFirst(RegExp(r'\?$'), '');
}

// -------------------------------------------------------------------- HTTP

Future<Map<String, dynamic>> _getJson(Uri uri) async {
  Object? lastError;
  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(seconds: 5 * attempt * attempt));
      stdout.writeln('     ...zkouším znovu');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 60);
    try {
      final req = await client.getUrl(uri);
      // Wikimedia bez rozumného User-Agent odpovídá 403.
      req.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == 429) {
        // Rate limit se nedá „přečkat“ pěti sekundami — server chce, aby se
        // provoz opravdu zastavil. Retry-After je směrodatnější než náš odhad.
        final retryAfter =
            int.tryParse(res.headers.value('retry-after') ?? '') ?? 60;
        stdout.writeln('     rate limit, čekám ${retryAfter}s');
        await Future<void>.delayed(Duration(seconds: retryAfter));
        lastError = 'HTTP 429';
        continue;
      }
      if (res.statusCode != 200) {
        lastError = 'HTTP ${res.statusCode}: '
            '${body.substring(0, body.length.clamp(0, 300))}';
        continue;
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      lastError = e;
    } finally {
      client.close();
    }
  }
  throw StateError('Nepodařilo se stáhnout $uri — $lastError');
}

// -------------------------------------------------------------------- cache

Future<List<_WikiItem>> _cached(
  String path,
  bool fresh,
  Future<List<_WikiItem>> Function() fetch,
) async {
  final file = File(path);
  if (!fresh && file.existsSync()) {
    stdout.writeln('     (z cache $path)');
    return [
      for (final j in jsonDecode(await file.readAsString()) as List)
        _WikiItem.fromJson(j as Map<String, dynamic>),
    ];
  }
  final data = await fetch();
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode([for (final i in data) i.toJson()]));
  return data;
}

/// Stáhne po dávkách to, co ještě není v cache, a **ukládá po každé dávce**.
///
/// Wikimedia po pár stovkách dotazů vrátí 429. Bez průběžného ukládání by
/// každý takový odkop zahodil všechno, co se do té chvíle stáhlo, a další
/// pokus by začínal od nuly — což vede rovnou k dalšímu 429.
Future<Map<String, String>> _cachedBatches(
  String path,
  bool fresh,
  Set<String> keys,
  Future<void> Function(List<String> batch, Map<String, String> into) fetchBatch,
) async {
  final file = File(path);
  final acc = <String, String>{};
  if (!fresh && file.existsSync()) {
    acc.addAll((jsonDecode(await file.readAsString()) as Map<String, dynamic>)
        .cast<String, String>());
  }

  final missing = keys.where((k) => !acc.containsKey(k)).toList();
  if (missing.isEmpty) {
    stdout.writeln('     (vše z cache $path)');
    return acc;
  }
  stdout.writeln('     ${acc.length} z cache, ${missing.length} ke stažení');

  await file.parent.create(recursive: true);
  for (var i = 0; i < missing.length; i += 20) {
    if (i > 0) {
      // Wikimedia chce sériové dotazy s rozumným odstupem, ne dávku najednou.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    await fetchBatch(missing.sublist(i, min(i + 20, missing.length)), acc);
    await file.writeAsString(jsonEncode(acc));
    stdout.writeln('     ${min(i + 20, missing.length)} / ${missing.length}');
  }
  return acc;
}
