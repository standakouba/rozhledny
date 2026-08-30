import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/data/seed.dart';
import 'package:sqlite3/sqlite3.dart';

/// Migrace v1 → v2 běží na telefonu, kde jsou už zapsané výlety.
///
/// Když se pokazí, ztratí se historie návštěv — a to je jediná věc v téhle
/// aplikaci, která se nedá znovu vygenerovat. Proto se testuje proti skutečně
/// postavené databázi ve starém schématu, ne proti odhadu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;

  final kletUuid = osmTowerUuid('node', 1);
  const ownUuid = 'vlastni-rozhledna';

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('rozhledny-migrace');
    dbPath = '${tempDir.path}/rozhledny.sqlite';
    _createV1Database(dbPath, kletUuid: kletUuid, ownUuid: ownUuid);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  const enrichment = '''
{
  "towers": [
    {"osmType":"node","osmId":1,"name":"Kleť","lat":48.86,"lon":14.29,
     "wikidataId":"Q29044153","wikipediaTitle":"Josefova věž",
     "wikipediaUrl":"https://cs.wikipedia.org/wiki/Josefova_v%C4%9B%C5%BE",
     "wikipediaExtract":"Josefova věž je kamenná rozhledna na vrcholu Kletě.",
     "photoUrl":"https://commons.wikimedia.org/wiki/Special:FilePath/K.jpg?width=800",
     "photoAuthor":"Marzper","photoLicense":"CC BY-SA 3.0",
     "photoLicenseUrl":"https://creativecommons.org/licenses/by-sa/3.0",
     "photoPageUrl":"https://commons.wikimedia.org/wiki/File:K.jpg"}
  ]
}''';

  test('upgrade přidá sloupce a nezahodí návštěvy ani vlastní body', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    // Otevření spustí migraci; teprve pak má smysl se ptát na data.
    await db.applyEnrichmentForTest(enrichment);

    final all = await db.watchTowersWithStats().first;
    expect(all, hasLength(2), reason: 'obě rozhledny musí přežít');

    final klet = all.firstWhere((t) => t.tower.uuid == kletUuid);
    expect(klet.visitCount, 2, reason: 'zapsané návštěvy se nesmí ztratit');
    expect(klet.lastVisit, DateTime(2026, 5, 20));
    expect(klet.bestRating, 5);

    final own = all.firstWhere((t) => t.tower.uuid == ownUuid);
    expect(own.tower.name, 'Naše tajná');
    expect(own.tower.source, TowerSource.user);
  });

  test('obohacení doplní wiki pole rozhledně z OSM', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);
    await db.applyEnrichmentForTest(enrichment);

    final klet = await db.towerByUuid(kletUuid);
    expect(klet!.wikidataId, 'Q29044153');
    expect(klet.wikipediaExtract, contains('kamenná rozhledna'));
    expect(klet.photoAuthor, 'Marzper');
    expect(klet.photoLicense, 'CC BY-SA 3.0');
    // Původní pole zůstávají beze změny.
    expect(klet.name, 'Kleť');
    expect(klet.region, 'Jihočeský kraj');
  });

  test('obohacení se nedotkne vlastních rozhleden', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);
    await db.applyEnrichmentForTest(enrichment);

    final own = await db.towerByUuid(ownUuid);
    expect(own!.wikidataId, isNull);
    expect(own.photoUrl, isNull);
  });

  test('po upgradu jde zapsat návštěva bez data', () async {
    // Přechod na verzi 3 přestavuje tabulku návštěv, aby datum smělo být
    // prázdné. Když se přestavba nepovede, projeví se to až tady.
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);
    await db.applyEnrichmentForTest(enrichment);

    await db.upsertVisit(VisitsCompanion.insert(
      uuid: 'bez-data',
      towerUuid: kletUuid,
      visitedOn: const Value(null),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    final visits = await db.watchVisits(kletUuid).first;
    expect(visits, hasLength(3), reason: 'dvě původní plus nová');
    expect(visits.where((v) => v.visitedOn == null), hasLength(1));

    final klet = (await db.watchTowersWithStats().first)
        .firstWhere((t) => t.tower.uuid == kletUuid);
    expect(klet.visitCount, 3);
    expect(klet.lastVisit, DateTime(2026, 5, 20),
        reason: 'původní data se přestavbou tabulky nesmí ztratit');
  });

  test('opakované obohacení nic nerozbije', () async {
    final db = AppDatabase(NativeDatabase(File(dbPath)));
    addTearDown(db.close);

    await db.applyEnrichmentForTest(enrichment);
    await db.applyEnrichmentForTest(enrichment);

    expect(await db.watchTowersWithStats().first, hasLength(2));
    expect((await db.towerByUuid(kletUuid))!.photoAuthor, 'Marzper');
  });
}

extension on AppDatabase {
  /// Migrace v aplikaci si asset načte sama z rootBundle; v testu se předává
  /// napevno, aby test nezávisel na tom, co je zrovna v assets/.
  Future<void> applyEnrichmentForTest(String json) =>
      applyEnrichmentFromAsset(this, json: json);
}

/// Postaví databázi přesně ve schématu verze 1, tedy bez wiki sloupců,
/// a naplní ji tím, co by na telefonu měl uživatel po pár výletech.
void _createV1Database(
  String path, {
  required String kletUuid,
  required String ownUuid,
}) {
  final db = sqlite3.open(path);
  db.execute('''
    CREATE TABLE towers (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      uuid TEXT NOT NULL UNIQUE,
      osm_type TEXT NULL,
      osm_id INTEGER NULL,
      name TEXT NULL,
      lat REAL NOT NULL,
      lon REAL NOT NULL,
      height REAL NULL,
      ele REAL NULL,
      region TEXT NULL,
      website TEXT NULL,
      note TEXT NULL,
      source TEXT NOT NULL,
      user_modified INTEGER NOT NULL DEFAULT 0,
      osm_missing INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0
    );
    CREATE TABLE visits (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      uuid TEXT NOT NULL UNIQUE,
      tower_uuid TEXT NOT NULL,
      visited_on INTEGER NOT NULL,
      rating INTEGER NULL,
      note TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0
    );
    CREATE TABLE photos (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      uuid TEXT NOT NULL UNIQUE,
      visit_uuid TEXT NOT NULL,
      file_name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      deleted INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX idx_visits_tower ON visits (tower_uuid);
    CREATE INDEX idx_photos_visit ON photos (visit_uuid);
  ''');

  int stamp(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
  final now = stamp(DateTime(2026, 1, 1));

  db.execute(
    'INSERT INTO towers (uuid, osm_type, osm_id, name, lat, lon, region, '
    'source, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?)',
    [kletUuid, 'node', 1, 'Kleť', 48.86, 14.29, 'Jihočeský kraj', 'osm', now, now],
  );
  db.execute(
    'INSERT INTO towers (uuid, name, lat, lon, source, created_at, updated_at) '
    'VALUES (?,?,?,?,?,?,?)',
    [ownUuid, 'Naše tajná', 49.0, 15.0, 'user', now, now],
  );

  for (final visit in [
    ('navsteva-1', DateTime(2025, 8, 3), 4),
    ('navsteva-2', DateTime(2026, 5, 20), 5),
  ]) {
    db.execute(
      'INSERT INTO visits (uuid, tower_uuid, visited_on, rating, created_at, '
      'updated_at) VALUES (?,?,?,?,?,?)',
      [visit.$1, kletUuid, stamp(visit.$2), visit.$3, now, now],
    );
  }

  db.execute('PRAGMA user_version = 1');
  db.dispose();
}
