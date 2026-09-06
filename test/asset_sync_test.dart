import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
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

  group('body, které z dat zmizely', () {
    test('prázdný bod z OSM se smaže', () async {
      // Vzniká, když slučování duplicit dá při dalším běhu generátoru
      // přednost jinému ze dvou zápisů téhož místa. Nechat ho v databázi
      // znamená dva puntíky pár metrů od sebe, z toho jeden mrtvý.
      await addTower(1, name: 'Duplicita');

      final report = await syncTowersFromAsset(db, json: asset([osm(2)]));

      expect(report.removed, 1);
      expect(report.missing, 0);
      expect(await tower(1), isNull);
    });

    test('bod se smazanou návštěvou zůstává', () async {
      // Tombstone návštěvy může znamenat, že na druhém telefonu je pořád
      // živá. Po importu odtamtud by neměla na co navázat.
      await addTower(1, name: 'Kleť');
      final visitUuid = newUuid();
      await db.upsertVisit(VisitsCompanion.insert(
        uuid: visitUuid,
        towerUuid: osmTowerUuid('node', 1),
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ));
      await db.softDeleteVisit(visitUuid);

      final report = await syncTowersFromAsset(db, json: asset([osm(2)]));

      expect(report.removed, 0);
      expect(report.missing, 1);
      expect((await tower(1))?.osmMissing, isTrue);
    });

    test('ručně upravený bod zůstává', () async {
      await addTower(1, name: 'Moje jméno', userModified: true);

      final report = await syncTowersFromAsset(db, json: asset([osm(2)]));

      expect(report.removed, 0);
      expect(await tower(1), isNotNull);
    });

    test('tombstone se nemaže, jinak by ho import vzkřísil', () async {
      await addTower(1, name: 'Smazaná');
      await db.softDeleteTower(osmTowerUuid('node', 1));

      final report = await syncTowersFromAsset(db, json: asset([osm(2)]));

      expect(report.removed, 0);
      expect((await tower(1))?.deleted, isTrue);
    });

    test('vlastní bod se nemaže, i když v assetu nikdy nebyl', () async {
      await addTower(1, name: 'Moje vlastní', source: TowerSource.user);

      final report = await syncTowersFromAsset(db, json: asset([osm(2)]));

      expect(report.removed, 0);
      expect(await tower(1), isNotNull);
    });
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
    // Držet ji naživu musí návštěva; bez ní by se bod z assetu rovnou smazal
    // a nebylo by co odznačovat.
    await addTower(1, name: 'Kleť');
    await db.upsertVisit(VisitsCompanion.insert(
      uuid: newUuid(),
      towerUuid: osmTowerUuid('node', 1),
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    ));
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
