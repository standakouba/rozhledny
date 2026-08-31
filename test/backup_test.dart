import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/services/backup.dart';

/// Slučování je jediné místo, kde se dají data ztratit nebo zdvojit,
/// a ručně se testuje mizerně — na dva telefony a týden výletů.
void main() {
  late AppDatabase mine;
  late AppDatabase theirs;

  final klet = osmTowerUuid('node', 1);
  final bezdez = osmTowerUuid('node', 2);

  setUp(() {
    mine = AppDatabase(NativeDatabase.memory());
    theirs = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await mine.close();
    await theirs.close();
  });

  Future<void> addTower(AppDatabase db, String uuid,
      {String? name, TowerSource source = TowerSource.osm}) async {
    final now = DateTime(2026, 1, 1);
    await db.upsertTower(TowersCompanion.insert(
      uuid: uuid,
      lat: 48.86,
      lon: 14.29,
      source: source,
      createdAt: now,
      updatedAt: now,
      name: Value(name),
    ));
  }

  Future<String> addVisit(
    AppDatabase db,
    String towerUuid, {
    required DateTime day,
    String? uuid,
    int? rating,
    String? note,
    DateTime? updatedAt,
  }) async {
    final id = uuid ?? newUuid();
    await db.upsertVisit(VisitsCompanion.insert(
      uuid: id,
      towerUuid: towerUuid,
      visitedOn: Value(day),
      createdAt: day,
      updatedAt: updatedAt ?? day,
      rating: Value(rating),
      note: Value(note),
    ));
    return id;
  }

  Future<BackupPayload> payloadOf(AppDatabase db) async => BackupPayload(
        towers: await db.exportableTowers(),
        visits: await db.allVisitsForExport(),
      );

  /// Projde serializací, aby test chytil i rozbitý formát, ne jen merge.
  Future<BackupPayload> roundTrip(AppDatabase db) async =>
      decodeBackup(encodeBackup(await payloadOf(db)));

  group('export', () {
    test('rozhledny z OSM se neposílají — druhá strana je má z assetu',
        () async {
      await addTower(mine, klet, name: 'Kleť');
      await addTower(mine, 'vlastni-1',
          name: 'Naše tajná', source: TowerSource.user);

      final payload = await payloadOf(mine);
      expect(payload.towers.map((t) => t.uuid), ['vlastni-1']);
    });

    test('ručně upravená rozhledna z OSM se poslat musí', () async {
      await addTower(mine, klet, name: 'Kleť');
      await (mine.update(mine.towers)..where((t) => t.uuid.equals(klet)))
          .write(const TowersCompanion(userModified: Value(true)));

      final payload = await payloadOf(mine);
      expect(payload.towers.map((t) => t.uuid), contains(klet));
    });
  });

  group('slučování', () {
    test('návštěvy z druhého telefonu se navěsí na správnou rozhlednu',
        () async {
      // Obě zařízení mají tutéž rozhlednu z assetu pod stejným UUID,
      // i když ji žádné z nich neposílá.
      await addTower(mine, klet, name: 'Kleť');
      await addTower(theirs, klet, name: 'Kleť');
      await addVisit(theirs, klet, day: DateTime(2026, 5, 1));

      final report = await mergeBackup(mine, await roundTrip(theirs));

      expect(report.visitsAdded, 1);
      expect(report.towersAdded, 0);
      final stats = (await mine.watchTowersWithStats().first).single;
      expect(stats.visitCount, 1);
    });

    test('opakovaný import nic nezduplikuje', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      await addVisit(theirs, klet, day: DateTime(2026, 5, 1));

      final backup = await roundTrip(theirs);
      await mergeBackup(mine, backup);
      final second = await mergeBackup(mine, await roundTrip(theirs));

      expect(second.visitsAdded, 0);
      expect(second.changedAnything, isFalse);
      expect((await mine.watchTowersWithStats().first).single.visitCount, 1);
    });

    test('při kolizi vyhrává novější updatedAt', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      const shared = 'navsteva-1';

      await addVisit(mine, klet,
          uuid: shared,
          day: DateTime(2026, 5, 1),
          note: 'moje starší',
          updatedAt: DateTime(2026, 5, 2));
      await addVisit(theirs, klet,
          uuid: shared,
          day: DateTime(2026, 5, 1),
          note: 'jejich novější',
          rating: 5,
          updatedAt: DateTime(2026, 6, 1));

      final report = await mergeBackup(mine, await roundTrip(theirs));

      expect(report.visitsUpdated, 1);
      final visit = (await mine.watchVisits(klet).first).single;
      expect(visit.note, 'jejich novější');
      expect(visit.rating, 5);
    });

    test('starší záznam z protějšku můj novější nepřepíše', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      const shared = 'navsteva-1';

      await addVisit(mine, klet,
          uuid: shared,
          day: DateTime(2026, 5, 1),
          note: 'moje novější',
          updatedAt: DateTime(2026, 6, 1));
      await addVisit(theirs, klet,
          uuid: shared,
          day: DateTime(2026, 5, 1),
          note: 'jejich starší',
          updatedAt: DateTime(2026, 5, 2));

      await mergeBackup(mine, await roundTrip(theirs));

      expect((await mine.watchVisits(klet).first).single.note, 'moje novější');
    });

    test('smazaná návštěva se importem nevzkřísí', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      const shared = 'navsteva-1';

      await addVisit(theirs, klet,
          uuid: shared,
          day: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 1));
      await mergeBackup(mine, await roundTrip(theirs));

      // Smažu ji u sebe — tombstone dostane novější updatedAt než protějšek.
      await mine.softDeleteVisit(shared);
      await mergeBackup(mine, await roundTrip(theirs));

      expect(await mine.watchVisits(klet).first, isEmpty);
    });

    test('vlastní rozhledna protějšku přibude i s návštěvami', () async {
      await addTower(theirs, 'vlastni-1',
          name: 'Nová u chaty', source: TowerSource.user);
      await addVisit(theirs, 'vlastni-1', day: DateTime(2026, 7, 1));

      final report = await mergeBackup(mine, await roundTrip(theirs));

      expect(report.towersAdded, 1);
      expect(report.visitsAdded, 1);
      final stats = (await mine.watchTowersWithStats().first).single;
      expect(stats.tower.name, 'Nová u chaty');
      expect(stats.visitCount, 1);
    });

    test('opakované návštěvy téže rozhledny se přenesou všechny', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      for (final year in [2024, 2025, 2026]) {
        await addVisit(theirs, klet, day: DateTime(year, 5, 1));
      }

      await mergeBackup(mine, await roundTrip(theirs));

      expect((await mine.watchTowersWithStats().first).single.visitCount, 3);
    });
  });

  group('podezřelé duplicity', () {
    test('stejný výlet zapsaný oběma telefony se ohlásí', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      // Různé uuid, stejná rozhledna, stejný den — merge je nespojí.
      await addVisit(mine, klet, day: DateTime(2026, 5, 1), note: 'já');
      await addVisit(theirs, klet, day: DateTime(2026, 5, 1), note: 'ty');

      final report = await mergeBackup(mine, await roundTrip(theirs));

      expect(report.visitsAdded, 1);
      expect(report.suspectedDuplicates, hasLength(1));
      expect(report.suspectedDuplicates.single, hasLength(2));
    });

    test('návštěvy v různé dny se za duplicity nepovažují', () async {
      await addTower(mine, klet);
      await addTower(theirs, klet);
      await addVisit(mine, klet, day: DateTime(2026, 5, 1));
      await addVisit(theirs, klet, day: DateTime(2026, 5, 2));

      final report = await mergeBackup(mine, await roundTrip(theirs));
      expect(report.suspectedDuplicates, isEmpty);
    });

    test('stejný den na různých rozhlednách je běžný výlet, ne duplicita',
        () async {
      await addTower(mine, klet);
      await addTower(mine, bezdez);
      await addTower(theirs, bezdez);
      await addVisit(mine, klet, day: DateTime(2026, 5, 1));
      await addVisit(theirs, bezdez, day: DateTime(2026, 5, 1));

      final report = await mergeBackup(mine, await roundTrip(theirs));
      expect(report.suspectedDuplicates, isEmpty);
    });
  });

  group('archiv', () {
    test('návštěva projde celým řetězem export → ZIP → import', () async {
      await addTower(mine, klet, name: 'Kleť');
      await addVisit(mine, klet, day: DateTime(2026, 5, 1), rating: 5);

      final zip = await buildBackupArchive(payload: await payloadOf(mine));

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      // Rozhledny z OSM se v záloze neposílají, protože je druhá strana má
      // z assetu — test to musí napodobit, jinak by návštěva dorazila
      // k neexistujícímu bodu.
      await addTower(restored, klet, name: 'Kleť');

      await restoreBackupArchive(zipBytes: zip, db: restored);

      expect((await restored.watchTowersWithStats().first).single.visitCount, 1);
    });

    test('záloha ze starší verze s fotkami se přečte, fotky se zahodí',
        () async {
      // Druhý telefon může mít ještě verzi, která fotky u návštěv posílala.
      // Návštěvy z ní musí dorazit — jinak by aktualizace jednoho telefonu
      // přenos mezi nimi rozbila.
      await addTower(mine, klet, name: 'Kleť');
      final visitUuid = await addVisit(mine, klet, day: DateTime(2026, 5, 1));
      final visit = await mine.visitByUuid(visitUuid);

      final legacy = jsonEncode({
        'formatVersion': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'towers': const [],
        'visits': [visit!.toJson()],
        'photos': [
          {
            'id': 1,
            'uuid': 'foto-1',
            'visitUuid': visitUuid,
            'fileName': 'foto.jpg',
            'createdAt': DateTime(2026, 5, 1).millisecondsSinceEpoch ~/ 1000,
            'deleted': false,
          }
        ],
      });

      final archive = Archive();
      final json = utf8.encode(legacy);
      archive.addFile(ArchiveFile('data.json', json.length, json));
      final photo = List.filled(2048, 7);
      archive.addFile(ArchiveFile('photos/foto.jpg', photo.length, photo));

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await addTower(restored, klet, name: 'Kleť');

      final report = await restoreBackupArchive(
        zipBytes: ZipEncoder().encode(archive),
        db: restored,
      );

      expect(report.visitsAdded, 1);
      expect((await restored.watchTowersWithStats().first).single.visitCount, 1);
    });
  });

  group('formát zálohy', () {
    test('novější verze formátu se odmítne se srozumitelnou hláškou', () {
      expect(
        () => decodeBackup({'formatVersion': backupFormatVersion + 1}),
        throwsA(isA<FormatException>()),
      );
    });

    test('soubor bez verze se odmítne', () {
      expect(() => decodeBackup({'towers': []}),
          throwsA(isA<FormatException>()));
    });
  });
}
