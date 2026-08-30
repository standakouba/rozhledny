import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/data/seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('UUID rozhleden', () {
    test('z OSM je deterministické — jinak by import zdvojil body', () {
      expect(osmTowerUuid('node', 123), osmTowerUuid('node', 123));
      expect(osmTowerUuid('node', 123), isNot(osmTowerUuid('way', 123)));
      expect(osmTowerUuid('node', 123), isNot(osmTowerUuid('node', 124)));
    });

    test('vlastní rozhledny dostanou pokaždé jiné', () {
      expect(newUuid(), isNot(newUuid()));
    });
  });

  group('seed', () {
    const json = '''
{
  "count": 2,
  "towers": [
    {"osmType":"node","osmId":1,"name":"Kleť","lat":48.86,"lon":14.29,
     "height":25.0,"region":"Jihočeský kraj"},
    {"osmType":"way","osmId":2,"lat":50.1,"lon":14.4}
  ]
}''';

    test('naplní databázi a unese opakované spuštění', () async {
      expect(await db.isEmpty, isTrue);
      expect(await seedFromAsset(db, json: json), 2);
      expect(await db.isEmpty, isFalse);

      // Druhý seed nesmí přidat duplicity — párování drží unique uuid.
      await seedFromAsset(db, json: json);
      final all = await db.watchTowersWithStats().first;
      expect(all, hasLength(2));
    });

    test('unese rozhlednu bez názvu a bez nepovinných polí', () async {
      await seedFromAsset(db, json: json);
      final all = await db.watchTowersWithStats().first;
      final unnamed = all.firstWhere((t) => t.tower.osmId == 2);
      expect(unnamed.tower.name, isNull);
      expect(unnamed.tower.region, isNull);
      expect(unnamed.tower.source, TowerSource.osm);
    });
  });

  group('úpravy záznamů', () {
    // Editor formuláře zná jen uuid, ne autoincrement id. Když upsert míří
    // na primární klíč, úprava spadne na unikátním uuid a tiše se neuloží.
    test('přepsání názvu rozhledny se uloží a nezaloží druhou', () async {
      final uuid = osmTowerUuid('node', 1);
      final now = DateTime.now();

      await db.upsertTower(TowersCompanion.insert(
        uuid: uuid,
        lat: 48.86,
        lon: 14.29,
        source: TowerSource.osm,
        createdAt: now,
        updatedAt: now,
        name: const Value('Kleť'),
      ));

      // Přesně to, co posílá TowerEditorSheet: žádné id, jen uuid.
      await db.upsertTower(TowersCompanion.insert(
        uuid: uuid,
        lat: 48.86,
        lon: 14.29,
        source: TowerSource.osm,
        createdAt: now,
        updatedAt: DateTime.now(),
        name: const Value('Josefova věž'),
        userModified: const Value(true),
      ));

      final all = await db.watchTowersWithStats().first;
      expect(all, hasLength(1), reason: 'nesmí vzniknout druhý záznam');
      expect(all.single.tower.name, 'Josefova věž');
      expect(all.single.tower.userModified, isTrue);
    });

    test('úprava návštěvy se uloží', () async {
      final towerUuid = osmTowerUuid('node', 1);
      final now = DateTime.now();
      await db.upsertTower(TowersCompanion.insert(
        uuid: towerUuid,
        lat: 48.86,
        lon: 14.29,
        source: TowerSource.osm,
        createdAt: now,
        updatedAt: now,
      ));

      const visitUuid = 'navsteva-1';
      await db.upsertVisit(VisitsCompanion.insert(
        uuid: visitUuid,
        towerUuid: towerUuid,
        visitedOn: Value(DateTime(2026, 5, 1)),
        createdAt: now,
        updatedAt: now,
        rating: const Value(3),
      ));

      await db.upsertVisit(VisitsCompanion.insert(
        uuid: visitUuid,
        towerUuid: towerUuid,
        visitedOn: Value(DateTime(2026, 5, 2)),
        createdAt: now,
        updatedAt: DateTime.now(),
        rating: const Value(5),
        note: const Value('opraveno'),
      ));

      final visits = await db.watchVisits(towerUuid).first;
      expect(visits, hasLength(1), reason: 'úprava nesmí založit druhou návštěvu');
      expect(visits.single.rating, 5);
      expect(visits.single.note, 'opraveno');
      expect(visits.single.visitedOn, DateTime(2026, 5, 2));
    });
  });

  group('opakované návštěvy', () {
    late String towerUuid;

    setUp(() async {
      towerUuid = osmTowerUuid('node', 1);
      final now = DateTime.now();
      await db.upsertTower(TowersCompanion.insert(
        uuid: towerUuid,
        lat: 48.86,
        lon: 14.29,
        source: TowerSource.osm,
        createdAt: now,
        updatedAt: now,
        name: const Value('Kleť'),
      ));
    });

    Future<String> addVisit(DateTime day, {int? rating}) async {
      final uuid = newUuid();
      await db.upsertVisit(VisitsCompanion.insert(
        uuid: uuid,
        towerUuid: towerUuid,
        visitedOn: Value(day),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rating: Value(rating),
      ));
      return uuid;
    }

    test('rozhledna se počítá jednou, návštěvy třikrát', () async {
      await addVisit(DateTime(2024, 5, 1), rating: 3);
      await addVisit(DateTime(2025, 6, 2), rating: 5);
      await addVisit(DateTime(2026, 7, 3), rating: 4);

      final all = await db.watchTowersWithStats().first;
      expect(all, hasLength(1), reason: 'pokořená rozhledna je pořád jedna');

      final klet = all.single;
      expect(klet.visitCount, 3);
      expect(klet.isVisited, isTrue);
      expect(klet.firstVisit, DateTime(2024, 5, 1));
      expect(klet.lastVisit, DateTime(2026, 7, 3));
      expect(klet.bestRating, 5);
    });

    test('smazání poslední návštěvy vrátí rozhlednu mezi nenavštívené',
        () async {
      final only = await addVisit(DateTime(2026, 7, 3));
      expect((await db.watchTowersWithStats().first).single.isVisited, isTrue);

      await db.softDeleteVisit(only);

      final after = (await db.watchTowersWithStats().first).single;
      expect(after.visitCount, 0);
      expect(after.isVisited, isFalse);
      expect(after.lastVisit, isNull);
    });

    test('smazaná návštěva nesnižuje počet ostatních', () async {
      await addVisit(DateTime(2024, 5, 1));
      final second = await addVisit(DateTime(2025, 6, 2));
      await db.softDeleteVisit(second);

      expect((await db.watchTowersWithStats().first).single.visitCount, 1);
    });

    test('nenavštívená rozhledna je v seznamu s nulovým počtem', () async {
      final all = await db.watchTowersWithStats().first;
      expect(all.single.visitCount, 0);
      expect(all.single.isVisited, isFalse);
    });

    test('smazání vlastní rozhledny schová i její návštěvy', () async {
      await addVisit(DateTime(2026, 7, 3));
      await db.softDeleteTower(towerUuid);

      expect(await db.watchTowersWithStats().first, isEmpty);
      expect(await db.watchVisits(towerUuid).first, isEmpty);
    });
  });

  group('návštěvy bez data', () {
    late String towerUuid;

    setUp(() async {
      towerUuid = osmTowerUuid('node', 1);
      final now = DateTime.now();
      await db.upsertTower(TowersCompanion.insert(
        uuid: towerUuid,
        lat: 48.86,
        lon: 14.29,
        source: TowerSource.osm,
        createdAt: now,
        updatedAt: now,
        name: const Value('Kleť'),
      ));
    });

    Future<String> addVisit({DateTime? day}) async {
      final uuid = newUuid();
      await db.upsertVisit(VisitsCompanion.insert(
        uuid: uuid,
        towerUuid: towerUuid,
        visitedOn: Value(day),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      return uuid;
    }

    test('rozhledna je pokořená i bez data návštěvy', () async {
      await addVisit();

      final klet = (await db.watchTowersWithStats().first).single;
      expect(klet.isVisited, isTrue,
          reason: 'zpětně zapsaná návštěva se musí počítat');
      expect(klet.visitCount, 1);
      // MIN/MAX v SQL prázdné hodnoty přeskakují, takže tady vyjde null
      // i u navštívené rozhledny — na to musí být UI připravené.
      expect(klet.lastVisit, isNull);
      expect(klet.firstVisit, isNull);
    });

    test('datované a nedatované návštěvy se sčítají dohromady', () async {
      await addVisit();
      await addVisit(day: DateTime(2026, 5, 1));
      await addVisit();

      final klet = (await db.watchTowersWithStats().first).single;
      expect(klet.visitCount, 3);
      expect(klet.lastVisit, DateTime(2026, 5, 1),
          reason: 'poslední známé datum se nesmí ztratit mezi prázdnými');
    });

    test('nedatované návštěvy se nehlásí jako duplicity', () async {
      // Dvě návštěvy bez data můžou být dva výlety stejně dobře jako jeden
      // zapsaný dvakrát. Hádat za uživatele by znamenalo mazat mu záznamy.
      await addVisit();
      await addVisit();

      expect(await db.duplicateVisitGroups(), isEmpty);
    });

    test('datum jde k návštěvě doplnit dodatečně', () async {
      final uuid = await addVisit();
      final visit = (await db.watchVisits(towerUuid).first).single;
      expect(visit.visitedOn, isNull);

      await db.upsertVisit(VisitsCompanion.insert(
        uuid: uuid,
        towerUuid: towerUuid,
        visitedOn: Value(DateTime(2026, 5, 1)),
        createdAt: visit.createdAt,
        updatedAt: DateTime.now(),
      ));

      final after = (await db.watchVisits(towerUuid).first).single;
      expect(after.visitedOn, DateTime(2026, 5, 1));
      expect((await db.watchTowersWithStats().first).single.visitCount, 1,
          reason: 'doplnění data nesmí založit druhou návštěvu');
    });
  });
}
