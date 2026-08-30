import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'database.dart';
import 'ids.dart';

const seedAssetPath = 'assets/data/rozhledny.json';

/// Naplní databázi rozhlednami z OSM zabalenými v APK.
///
/// Spouští se jen při prvním startu (prázdná databáze). Není to aktualizace —
/// ta přijde až jako samostatná funkce; tady jde o výchozí stav místo prázdné mapy.
Future<int> seedFromAsset(AppDatabase db, {String? json}) async {
  final raw = json ?? await rootBundle.loadString(seedAssetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final now = DateTime.now();

  final rows = <TowersCompanion>[
    for (final item in decoded['towers'] as List<dynamic>)
      _towerFromJson(item as Map<String, dynamic>, now),
  ];

  await db.batch((b) => b.insertAll(db.towers, rows, mode: InsertMode.insertOrIgnore));
  return rows.length;
}

TowersCompanion _towerFromJson(Map<String, dynamic> j, DateTime now) {
  final osmType = j['osmType'] as String;
  final osmId = j['osmId'] as int;
  return TowersCompanion.insert(
    uuid: osmTowerUuid(osmType, osmId),
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    source: TowerSource.osm,
    createdAt: now,
    updatedAt: now,
    osmType: Value(osmType),
    osmId: Value(osmId),
    name: Value(j['name'] as String?),
    height: Value((j['height'] as num?)?.toDouble()),
    ele: Value((j['ele'] as num?)?.toDouble()),
    region: Value(j['region'] as String?),
    website: Value(j['website'] as String?),
    openingHours: Value(j['openingHours'] as String?),
    fee: Value(j['fee'] as String?),
    access: Value(j['access'] as String?),
    wikidataId: Value(j['wikidataId'] as String?),
    wikipediaTitle: Value(j['wikipediaTitle'] as String?),
    wikipediaUrl: Value(j['wikipediaUrl'] as String?),
    wikipediaExtract: Value(j['wikipediaExtract'] as String?),
    photoUrl: Value(j['photoUrl'] as String?),
    photoAuthor: Value(j['photoAuthor'] as String?),
    photoLicense: Value(j['photoLicense'] as String?),
    photoLicenseUrl: Value(j['photoLicenseUrl'] as String?),
    photoPageUrl: Value(j['photoPageUrl'] as String?),
  );
}

/// Doplní popisy a fotky k rozhlednám, které v databázi už jsou.
///
/// Volá se z migrace v1→2. Na rozdíl od [seedFromAsset] nic nevkládá ani
/// nemaže — jen aktualizuje wiki sloupce, a to **výhradně u bodů z OSM**.
/// Vlastní rozhledny, návštěvy, fotky ani ručně upravené záznamy se nemění;
/// na telefonu jsou v tu chvíli reálná data, o která nesmíme přijít.
Future<int> applyEnrichmentFromAsset(AppDatabase db, {String? json}) async {
  final raw = json ?? await rootBundle.loadString(seedAssetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;

  var updated = 0;
  await db.batch((b) {
    for (final item in decoded['towers'] as List<dynamic>) {
      final j = item as Map<String, dynamic>;
      // Otevírací doba a vstupné existují nezávisle na tom, jestli rozhledna
      // má článek na Wikipedii — filtrovat podle wikidataId by je u většiny
      // rozhleden zahodilo.
      const enriched = [
        'openingHours', 'fee', 'access', 'wikidataId', 'photoUrl',
      ];
      if (enriched.every((f) => j[f] == null)) continue;

      b.update(
        db.towers,
        TowersCompanion(
          openingHours: Value(j['openingHours'] as String?),
          fee: Value(j['fee'] as String?),
          access: Value(j['access'] as String?),
          wikidataId: Value(j['wikidataId'] as String?),
          wikipediaTitle: Value(j['wikipediaTitle'] as String?),
          wikipediaUrl: Value(j['wikipediaUrl'] as String?),
          wikipediaExtract: Value(j['wikipediaExtract'] as String?),
          photoUrl: Value(j['photoUrl'] as String?),
          photoAuthor: Value(j['photoAuthor'] as String?),
          photoLicense: Value(j['photoLicense'] as String?),
          photoLicenseUrl: Value(j['photoLicenseUrl'] as String?),
          photoPageUrl: Value(j['photoPageUrl'] as String?),
        ),
        where: (t) =>
            t.uuid.equals(osmTowerUuid(j['osmType'] as String, j['osmId'] as int)) &
            t.source.equalsValue(TowerSource.osm),
      );
      updated++;
    }
  });
  return updated;
}
