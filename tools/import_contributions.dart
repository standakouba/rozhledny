// Čtečka návrhů do dat, které chodí e-mailem z aplikace.
//
// Není součástí aplikace — spouští se ručně nad tím, co dorazilo do schránky,
// a nic nezapisuje. Jen srovná návrhy se současným assetem a vypíše, o čem se
// má rozhodnout: co je opravdu nová rozhledna, co je jen nenalezený bod, který
// v datech celou dobu je, a na čem se shodlo víc lidí.
//
//   dart tools/import_contributions.dart navrhy/            (složka)
//   dart tools/import_contributions.dart navrh.json ...     (soubory)
//
// Přijímá jak samotný JSON, tak celý text e-mailu i s tím, co uživatel napsal
// nad blok s daty — z mailu se vybere první úplný objekt za oddělovačem.
//
// Bez závislostí (jen dart:io / dart:convert / dart:math), aby šel spustit
// i bez `pub get`.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _assetPath = 'assets/data/rozhledny.json';

/// Do téhle vzdálenosti se návrh považuje za tentýž bod jako existující
/// rozhledna. Nejčastější důvod, proč si někdo rozhlednu založí ručně, není
/// chybějící rozhledna, ale bezejmenný bod, který v datech je a nejde najít
/// hledáním — těch je v OSM skoro třetina.
const _sameSpotMeters = 150.0;

/// Důvody nahlášení, jak je nabízí aplikace. Klíče musí sedět s enumem
/// `TowerReportReason`; neznámý důvod se vypíše, jak přišel.
const _reasonLabels = <String, String>{
  'gone': 'rozhledna už neexistuje',
  'notATower': 'není to rozhledna',
  'duplicate': 'je v mapě dvakrát',
  'other': 'něco jiného',
};

/// A do téhle se slučují návrhy od různých lidí. Ruční zápich do mapy je
/// nepřesnější než zaměřený bod, takže je práh volnější.
const _clusterMeters = 250.0;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Pouziti: dart tools/import_contributions.dart '
        '<soubor|slozka> ...');
    exitCode = 64;
    return;
  }

  final asset = _loadAsset();
  stdout.writeln('Asset: ${asset.length} rozhleden');

  final files = _collectFiles(args);
  if (files.isEmpty) {
    stderr.writeln('Zadny soubor k precteni.');
    exitCode = 66;
    return;
  }

  final payloads = <_Payload>[];
  for (final file in files) {
    try {
      payloads.add(_Payload.parse(file));
    } on FormatException catch (e) {
      stdout.writeln('  ! ${_short(file)}: ${e.message}');
    }
  }
  stdout
    ..writeln('Nacteno: ${payloads.length} z ${files.length} souboru')
    ..writeln();

  _reportAdded(payloads, asset);
  _reportEdited(payloads, asset);
  _reportDeleted(payloads);
  _reportProblems(payloads, asset);
}

// ------------------------------------------------------------------- vstup

List<File> _collectFiles(List<String> args) {
  final files = <File>[];
  for (final arg in args) {
    final dir = Directory(arg);
    if (dir.existsSync()) {
      files.addAll(dir
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.endsWith('.dart')));
      continue;
    }
    final file = File(arg);
    if (file.existsSync()) {
      files.add(file);
    } else {
      stdout.writeln('  ! $arg neexistuje');
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

class _Payload {
  _Payload(this.source, this.json);

  final String source;
  final Map<String, dynamic> json;

  static _Payload parse(File file) {
    final raw = file.readAsStringSync();

    // Z e-mailu se bere až to, co je za oddělovačem — nad ním bývá text,
    // který uživatel připsal, a ten může obsahovat cokoli včetně závorek.
    const marker = '--- data k importu';
    final markerAt = raw.indexOf(marker);
    final body = markerAt < 0
        ? raw
        : raw.substring(raw.indexOf('\n', markerAt) + 1);

    final start = body.indexOf('{');
    if (start < 0) throw const FormatException('zadny JSON uvnitr');

    // Konec objektu se hledá počítáním závorek, ne posledním `}` v souboru:
    // za blokem s daty bývá podpis a citace předchozího mailu.
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < body.length; i++) {
      final c = body[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == '\\') {
          escaped = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) {
          final decoded =
              jsonDecode(body.substring(start, i + 1)) as Map<String, dynamic>;
          return _Payload(_short(file), decoded);
        }
      }
    }
    throw const FormatException('JSON je useknuty');
  }

  String get label {
    final app = json['app'];
    final at = (json['createdAt'] as String?)?.split('T').first;
    return [source, ?at, if (app != null) 'v$app'].join(' · ');
  }

  List<Map<String, dynamic>> _list(String key, {String? kind}) => [
        for (final e in (json[key] as List? ?? const []))
          if (kind == null || (e as Map)['kind'] == kind)
            (e as Map).cast<String, dynamic>(),
      ];

  List<Map<String, dynamic>> towers(String kind) => _list('towers', kind: kind);

  List<Map<String, dynamic>> get problems => _list('reports');
}

// ------------------------------------------------------------------ asset

class _AssetTower {
  _AssetTower(this.key, this.name, this.lat, this.lon);

  final String key;
  final String? name;
  final double lat;
  final double lon;

  @override
  String toString() => '${name ?? 'bez nazvu'} ($key)';
}

List<_AssetTower> _loadAsset() {
  final decoded =
      jsonDecode(File(_assetPath).readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final item in decoded['towers'] as List<dynamic>)
      _AssetTower(
        '${(item as Map)['osmType']}/${item['osmId']}',
        item['name'] as String?,
        (item['lat'] as num).toDouble(),
        (item['lon'] as num).toDouble(),
      ),
  ];
}

({_AssetTower tower, double meters})? _nearest(
  List<_AssetTower> asset,
  double lat,
  double lon,
) {
  _AssetTower? best;
  var bestMeters = double.infinity;
  for (final t in asset) {
    final d = _distanceMeters(lat, lon, t.lat, t.lon);
    if (d < bestMeters) {
      bestMeters = d;
      best = t;
    }
  }
  return best == null ? null : (tower: best, meters: bestMeters);
}

_AssetTower? _byKey(List<_AssetTower> asset, String? key) {
  if (key == null) return null;
  for (final t in asset) {
    if (t.key == key) return t;
  }
  return null;
}

// ----------------------------------------------------------------- výpisy

/// Návrh na chybějící rozhlednu od jednoho nebo víc lidí.
class _Cluster {
  _Cluster(this.lat, this.lon);

  final double lat;
  final double lon;
  final names = <String>{};
  final sources = <String>[];
  final heights = <double>{};
}

void _reportAdded(List<_Payload> payloads, List<_AssetTower> asset) {
  final clusters = <_Cluster>[];
  for (final p in payloads) {
    for (final t in p.towers('added')) {
      final lat = (t['lat'] as num).toDouble();
      final lon = (t['lon'] as num).toDouble();

      // Tentýž bod od dvou lidí se nikdy netrefí na stejné souřadnice,
      // takže se návrhy shlukují podle vzdálenosti.
      final existing = clusters.firstWhere(
        (c) => _distanceMeters(c.lat, c.lon, lat, lon) < _clusterMeters,
        orElse: () {
          final c = _Cluster(lat, lon);
          clusters.add(c);
          return c;
        },
      );
      if (t['name'] != null) existing.names.add(t['name'] as String);
      if (t['height'] != null) {
        existing.heights.add((t['height'] as num).toDouble());
      }
      existing.sources.add(p.label);
    }
  }

  _header('CHYBEJICI ROZHLEDNY', clusters.length);
  clusters.sort((a, b) => b.sources.length.compareTo(a.sources.length));

  for (final c in clusters) {
    final name = c.names.isEmpty ? 'bez nazvu' : c.names.join(' / ');
    stdout.writeln('  [${c.sources.length}x] $name');
    stdout.writeln('        ${_coords(c.lat, c.lon)}'
        '${c.heights.isEmpty ? '' : '  vyska ${c.heights.join(' / ')} m'}');

    final near = _nearest(asset, c.lat, c.lon);
    if (near == null) continue;
    final d = near.meters;
    if (d < _sameSpotMeters) {
      stdout.writeln('        JE V DATECH: ${near.tower} '
          '${_meters(d)} — nejspis ji jen nenasli');
    } else {
      stdout.writeln('        nejbliz v datech: ${near.tower} ${_meters(d)}');
    }
    stdout.writeln('        navrhli: ${c.sources.join(', ')}');
  }
  stdout.writeln();
}

void _reportEdited(List<_Payload> payloads, List<_AssetTower> asset) {
  final rows = [
    for (final p in payloads)
      for (final t in p.towers('edited')) (payload: p, tower: t),
  ];

  _header('OPRAVENE BODY', rows.length);
  for (final row in rows) {
    final t = row.tower;
    final key = t['osm'] as String?;
    final inAsset = _byKey(asset, key);
    stdout.writeln('  ${t['name'] ?? 'bez nazvu'} (${key ?? 'bez OSM id'})');

    if (inAsset == null) {
      stdout.writeln('        v assetu neni — bod z OSM mezitim zmizel?');
    } else {
      if (inAsset.name != t['name']) {
        stdout.writeln('        nazev: ${inAsset.name ?? '(zadny)'} '
            '-> ${t['name'] ?? '(zadny)'}');
      }
      final moved = _distanceMeters(
        inAsset.lat,
        inAsset.lon,
        (t['lat'] as num).toDouble(),
        (t['lon'] as num).toDouble(),
      );
      if (moved >= 1) {
        stdout.writeln('        poloha: posun o ${_meters(moved)} '
            '-> ${_coords((t['lat'] as num).toDouble(), (t['lon'] as num).toDouble())}');
      }
      if (inAsset.name == t['name'] && moved < 1) {
        stdout.writeln('        beze zmeny proti assetu');
      }
    }
    stdout.writeln('        od: ${row.payload.label}');
  }
  stdout.writeln();
}

void _reportDeleted(List<_Payload> payloads) {
  final rows = [
    for (final p in payloads)
      for (final t in p.towers('deleted')) (payload: p, tower: t),
  ];

  _header('SMAZANE VLASTNI BODY', rows.length);
  for (final row in rows) {
    stdout.writeln('  ${row.tower['name'] ?? 'bez nazvu'}  '
        '${_coords((row.tower['lat'] as num).toDouble(), (row.tower['lon'] as num).toDouble())}');
    stdout.writeln('        od: ${row.payload.label}');
  }
  stdout.writeln();
}

void _reportProblems(List<_Payload> payloads, List<_AssetTower> asset) {
  // Klíčem je bod v OSM: že tutéž věž nahlásili tři lidé, je ta nejsilnější
  // zpráva, jakou odsud jde dostat.
  final byTower = <String, List<({_Payload payload, Map<String, dynamic> row})>>{};
  for (final p in payloads) {
    for (final r in p.problems) {
      final key = (r['osm'] ?? r['tower']) as String;
      byTower.putIfAbsent(key, () => []).add((payload: p, row: r));
    }
  }

  _header('NAHLASENE CHYBY', byTower.length);
  final keys = byTower.keys.toList()
    ..sort((a, b) => byTower[b]!.length.compareTo(byTower[a]!.length));

  for (final key in keys) {
    final rows = byTower[key]!;
    final first = rows.first.row;
    final inAsset = _byKey(asset, key);
    stdout.writeln('  [${rows.length}x] '
        '${first['name'] ?? inAsset?.name ?? 'bez nazvu'} ($key)');
    if (inAsset == null) {
      stdout.writeln('        v assetu uz neni');
    }
    for (final r in rows) {
      final reason = r.row['reason'] as String;
      stdout.writeln('        ${_reasonLabels[reason] ?? reason}'
          '${r.row['note'] == null ? '' : ': ${r.row['note']}'}'
          '   (${r.payload.label})');
    }
  }
  stdout.writeln();
}

void _header(String title, int count) {
  stdout
    ..writeln(title)
    ..writeln(''.padRight(title.length, '-'));
  if (count == 0) stdout.writeln('  nic');
}

String _coords(double lat, double lon) =>
    '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';

String _meters(double m) =>
    m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';

String _short(File f) => f.uri.pathSegments.last;

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}
