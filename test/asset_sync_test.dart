import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/data/seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Aktualizace základních dat sahá na řádky, na kterých už uživatel může mít
/// vlastní práci. Testuje se proto hlavně to, na co sahat **nesmí** — tam se
/// chyba pozná až ve chvíli, kdy jsou data nenávratně přepsaná.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Map<String, dynamic> osm(int id, {String? name, double lat = 50.0}) => {
        'osmType': 'node',
        'osmId': id,
        'name': name,
        'lat': lat,
        'lon': 14.0,
      };

  String asset(List<Map<String, dynamic>> towers) =>
      jsonEncode({'towers': towers});

  Future<void> addTower(
    int osmId, {
    String? name,
    TowerSource source = TowerSource.osm,
    bool userModified = false,
    String? note,
  }) async {
    final now = DateTime(2026, 1, 1);
    await db.upsertTower(TowersCompanion.insert(
      uuid: osmTowerUuid('node', osmId),
      lat: 50.0,
      lon: 14.0,
      source: source,
      createdAt: now,
      updatedAt: now,
      osmType: const Value('node'),
      osmId: Value(osmId),
      name: Value(name),
      note: Value(note),
      userModified: Value(userModified),
    ));
  }

  Future<Tower?> tower(int osmId) => db.towerByUuid(osmTowerUuid('node', osmId));

  test('rozhledna, která v assetu přibyla, se doplní', () async {
    await addTower(1, name: 'Kleť');

    final report = await syncTowersFromAsset(db,
        json: asset([osm(1, name: 'Kleť'), osm(2, name: 'Boubín')]));

    expect(report.added, 1);
    expect((await tower(2))?.name, 'Boubín');
  });

  test('opravený název se propíše do už uložené rozhledny', () async {
    await addTower(1, name: 'Rozhledna Hostovice');

    final report =
        await syncTowersFromAsset(db, json: asset([osm(1, name: 'Rozhledna Hoslovice')]));

    expect(report.updated, 1);
    expect((await tower(1))?.name, 'Rozhledna Hoslovice');
  });

  test('ručně upravená rozhledna z OSM se nepřepíše', () async {
    // Uživatel si název opravil sám dřív, než dorazila oprava v datech.
    // Jeho verze má přednost, jinak by mu ji aktualizace tiše přemazala.
    await addTower(1, name: 'Moje jméno', userModified: true);

    final report =
        await syncTowersFromAsset(db, json: asset([osm(1, name: 'Jméno z OSM')]));

    expect(report.kept, 1);
    expect(report.updated, 0);
    expect((await tower(1))?.name, 'Moje jméno');
  });

  test('vlastní rozhledna se nepřepíše, ani když na ni sedí OSM id', () async {
    await addTower(1, name: 'Moje vlastní', source: TowerSource.user);

    await syncTowersFromAsset(db, json: asset([osm(1, name: 'Jméno z OSM')]));

    expect((await tower(1))?.name, 'Moje vlastní');
    expect((await tower(1))?.source, TowerSource.user);
  });

  test('smazaná rozhledna se aktualizací nevzkřísí', () async {
    await addTower(1, name: 'Kleť');
    await db.softDeleteTower(osmTowerUuid('node', 1));

    final report = await syncTowersFromAsset(db, json: asset([osm(1, name: 'Kleť')]));

    expect(report.kept, 1);
    expect((await tower(1))?.deleted, isTrue);
  });

  test('poznámka u rozhledny je uživatelova a zůstává', () async {
    await addTower(1, name: 'Kleť', note: 'zavřeno v zimě');

    await syncTowersFromAsset(db, json: asset([osm(1, name: 'Kleť')]));

    expect((await tower(1))?.note, 'zavřeno v zimě');
  });

  test('rozhledna, která z dat zmizela, se označí a návštěva na ní přežije',
      () async {
    await addTower(1, name: 'Zaniklá');
    await db.upsertVisit(VisitsCompanion.insert(
      uuid: newUuid(),
      towerUuid: osmTowerUuid('node', 1),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    ));

    final report = await syncTowersFromAsset(db, json: asset([osm(2)]));

    expect(report.missing, 1);
    final row = await tower(1);
    expect(row?.osmMissing, isTrue);
    expect(row?.deleted, isFalse, reason: 'mazat ji nesmíme, visí na ní návštěva');
    expect((await db.allVisitsForExport()).length, 1);
  });

  test('rozhledna, která se do dat vrátila, přestane být označená', () async {
    await addTower(1, name: 'Kleť');
    await syncTowersFromAsset(db, json: asset([]));
    expect((await tower(1))?.osmMissing, isTrue);

    await syncTowersFromAsset(db, json: asset([osm(1, name: 'Kleť')]));
    expect((await tower(1))?.osmMissing, isFalse);
  });

  test('druhý běh nad stejnými daty už nic nemění', () async {
    await addTower(1, name: 'Kleť');
    final json = asset([osm(1, name: 'Kleť'), osm(2, name: 'Boubín')]);

    await syncTowersFromAsset(db, json: json);
    final after = await syncTowersFromAsset(db, json: json);

    expect(after.added, 0);
    expect(after.missing, 0);
    expect((await db.allTowers()).length, 2);
  });

  group('spouštění podle otisku assetu', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('prázdná databáze se naplní a otisk se zapamatuje', () async {
      final prefs = await SharedPreferences.getInstance();
      final json = asset([osm(1, name: 'Kleť')]);

      final first = await syncFromAssetIfChanged(db, prefs, json: json);
      expect(first.added, 1);

      // Beze změny assetu se podruhé nesmí sáhnout na nic — jinak by každý
      // start aplikace zbytečně přepisoval sedm stovek řádků.
      final second = await syncFromAssetIfChanged(db, prefs, json: json);
      expect(second.changedAnything, isFalse);
      expect(second.updated, 0);
    });

    test('změna assetu spustí srovnání i nad naplněnou databází', () async {
      final prefs = await SharedPreferences.getInstance();
      await syncFromAssetIfChanged(db, prefs, json: asset([osm(1, name: 'Staré')]));

      final report = await syncFromAssetIfChanged(db, prefs,
          json: asset([osm(1, name: 'Nové')]));

      expect(report.updated, 1);
      expect((await tower(1))?.name, 'Nové');
    });
  });
}
