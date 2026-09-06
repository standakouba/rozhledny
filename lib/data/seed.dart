import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'ids.dart';

const seedAssetPath = 'assets/data/rozhledny.json';

/// Naplní databázi rozhlednami z OSM zabalenými v APK.
///
/// Spouští se jen při prvním startu (prázdná databáze). Aktualizaci už
/// naplněné databáze řeší [syncTowersFromAsset]; tady jde o výchozí stav
/// místo prázdné mapy, a proto stačí jeden hromadný insert.
Future<int> seedFromAsset(AppDatabase db, {String? json}) async {
  final raw = json ?? await rootBundle.loadString(seedAssetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final now = DateTime.now();

  final rows = <TowersCompanion>[
    for (final item in decoded['towers'] as List<dynamic>)
      _towerFromJson(item as Map<String, dynamic>, now),
  ];

  await db.batch(
    (b) => b.insertAll(db.towers, rows, mode: InsertMode.insertOrIgnore),
  );
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
        'openingHours',
        'fee',
        'access',
        'wikidataId',
        'photoUrl',
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
            t.uuid.equals(
              osmTowerUuid(j['osmType'] as String, j['osmId'] as int),
            ) &
            t.source.equalsValue(TowerSource.osm),
      );
      updated++;
    }
  });
  return updated;
}

// ------------------------------------------------------- aktualizace dat

/// Co srovnání databáze s assetem udělalo.
class AssetSyncReport {
  const AssetSyncReport({
    this.added = 0,
    this.updated = 0,
    this.missing = 0,
    this.kept = 0,
  });

  /// Rozhledny, které v assetu přibyly.
  final int added;

  /// Rozhledny, kterým se přepsala data z OSM.
  final int updated;

  /// Rozhledny, které z assetu zmizely. Nemažou se, jen se označí.
  final int missing;

  /// Body, na které se nesahalo: vlastní, ručně upravené a smazané.
  final int kept;

  bool get changedAnything => added + updated + missing > 0;

  @override
  String toString() =>
      'přidáno $added, aktualizováno $updated, '
      'chybí v OSM $missing, beze změny $kept';
}

/// Klíč, pod kterým si aplikace pamatuje, který asset už do dat promítla.
const _keyAssetDigest = 'seed_asset_digest';

/// Srovná základní data rozhleden s assetem, ale jen když se asset změnil.
///
/// Rozhoduje otisk obsahu, ne číslo verze aplikace. Asset se opravuje i bez
/// vydání (ručně přepsaný název z OSM) a při vývoji se aplikace přeinstaluje
/// pod stejným buildem — verze by takovou změnu prospala. Otisk čtyřsetkilo-
/// bajtového souboru stojí pár milisekund a ušetří rozparsování celého JSONu
/// při každém dalším startu.
Future<AssetSyncReport> syncFromAssetIfChanged(
  AppDatabase db,
  SharedPreferences prefs, {
  String? json,
}) async {
  final digest = json != null
      ? sha1.convert(utf8.encode(json)).toString()
      : await _assetDigest();

  // Prázdná databáze se plní i tehdy, když otisk sedí: data se můžou ztratit
  // (vymazání dat aplikace), zatímco nastavení zůstane.
  final empty = await db.isEmpty;
  if (!empty && prefs.getString(_keyAssetDigest) == digest) {
    return const AssetSyncReport();
  }

  final report = empty
      ? AssetSyncReport(added: await seedFromAsset(db, json: json))
      : await syncTowersFromAsset(db, json: json);

  await prefs.setString(_keyAssetDigest, digest);
  return report;
}

Future<String> _assetDigest() async {
  // Načtou se syrové bajty, ne řetězec: dekódovat UTF-8 a rozparsovat JSON
  // má smysl teprve ve chvíli, kdy je z otisku vidět, že se asset změnil.
  final bytes = await rootBundle.load(seedAssetPath);
  return sha1
      .convert(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      )
      .toString();
}

/// Srovná základní data rozhleden v databázi s assetem.
///
/// Seed běží jen do prázdné databáze, takže na telefonu, kde aplikace jednou
/// byla, by oprava názvu ani nově přibylá rozhledna nikdy nedorazily. Tohle je
/// ta chybějící cesta.
///
/// **Nesahá** na vlastní rozhledny, na ručně upravené body z OSM (od toho je
/// `userModified`) ani na smazané — tam jsou na telefonu data, o která
/// uživatel přijít nesmí. Z polí přepisuje jen ta, která pocházejí z OSM;
/// poznámka u rozhledny je uživatelova a zůstává.
///
/// Nic nemaže. Rozhledna, která z assetu zmizela, se jen označí `osmMissing`,
/// protože na ní můžou viset návštěvy — a ty jsou to jediné, co si uživatel
/// do aplikace sám nasbíral.
Future<AssetSyncReport> syncTowersFromAsset(
  AppDatabase db, {
  String? json,
}) async {
  final raw = json ?? await rootBundle.loadString(seedAssetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final now = DateTime.now();

  final existing = {for (final t in await db.allTowers()) t.uuid: t};
  final inAsset = <String>{};
  var added = 0, updated = 0, missing = 0, kept = 0;

  await db.batch((b) {
    for (final item in decoded['towers'] as List<dynamic>) {
      final j = item as Map<String, dynamic>;
      final uuid = osmTowerUuid(j['osmType'] as String, j['osmId'] as int);
      inAsset.add(uuid);

      final row = existing[uuid];
      if (row == null) {
        b.insert(db.towers, _towerFromJson(j, now));
        added++;
      } else if (row.source != TowerSource.osm ||
          row.userModified ||
          row.deleted) {
        kept++;
      } else {
        b.update(
          db.towers,
          _osmFieldsFromJson(j, now),
          where: (t) => t.uuid.equals(uuid),
        );
        updated++;
      }
    }

    for (final row in existing.values) {
      if (row.source != TowerSource.osm ||
          row.osmMissing ||
          inAsset.contains(row.uuid)) {
        continue;
      }
      b.update(
        db.towers,
        TowersCompanion(osmMissing: const Value(true), updatedAt: Value(now)),
        where: (t) => t.uuid.equals(row.uuid),
      );
      missing++;
    }
  });

  return AssetSyncReport(
    added: added,
    updated: updated,
    missing: missing,
    kept: kept,
  );
}

/// Pole, která vlastní OSM. Co tady schází, patří uživateli: poznámka,
/// příznak ruční úpravy, tombstone i čas vzniku záznamu.
TowersCompanion _osmFieldsFromJson(Map<String, dynamic> j, DateTime now) =>
    TowersCompanion(
      osmType: Value(j['osmType'] as String),
      osmId: Value(j['osmId'] as int),
      name: Value(j['name'] as String?),
      lat: Value((j['lat'] as num).toDouble()),
      lon: Value((j['lon'] as num).toDouble()),
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
      // Rozhledna, která se do OSM vrátila, přestává být zmizelá.
      osmMissing: const Value(false),
      updatedAt: Value(now),
    );
