import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/services/backup.dart';
import 'package:rozhledny/services/photos.dart';

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
        photos: await db.allPhotosForExport(),
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

  group('sdílení návštěv vs. úplná záloha', () {
    late Directory tempDir;
    late PhotoStorage storage;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('rozhledny-fotky');
      storage = PhotoStorage(tempDir);
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    Future<BackupPayload> payloadWithPhoto() async {
      await addTower(mine, klet, name: 'Kleť');
      final visitUuid = await addVisit(mine, klet, day: DateTime(2026, 5, 1));
      await storage.saveBytes('foto.jpg', List.filled(2048, 7));
      await mine.insertPhoto(PhotosCompanion.insert(
        uuid: 'foto-1',
        visitUuid: visitUuid,
        fileName: 'foto.jpg',
        createdAt: DateTime.now(),
      ));
      return payloadOf(mine);
    }

    test('sdílení nepošle fotky ani jejich záznamy', () async {
      // Záznam bez souboru by na druhém telefonu udělal prázdné okno
      // v galerii — data musí odpovídat tomu, co je v archivu.
      final zip = await buildBackupArchive(
        payload: await payloadWithPhoto(),
        storage: storage,
        includePhotos: false,
      );

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      // Rozhledny z OSM se v záloze neposílají, protože je druhá strana má
      // z assetu — test to musí napodobit, jinak by návštěva dorazila
      // k neexistujícímu bodu.
      await addTower(restored, klet, name: 'Kleť');
      final emptyDir = Directory.systemTemp.createTempSync('prazdne');
      addTearDown(() => emptyDir.deleteSync(recursive: true));

      await restoreBackupArchive(
        zipBytes: zip,
        db: restored,
        storage: PhotoStorage(emptyDir),
      );

      expect(await restored.allPhotosForExport(), isEmpty,
          reason: 'bez souborů nesmí přijít ani záznamy');
      expect((await restored.watchTowersWithStats().first).single.visitCount, 1,
          reason: 'návštěva se přenést musí');
    });

    test('úplná záloha fotku přenese včetně souboru', () async {
      final zip = await buildBackupArchive(
        payload: await payloadWithPhoto(),
        storage: storage,
        includePhotos: true,
      );

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await addTower(restored, klet, name: 'Kleť');
      final target = Directory.systemTemp.createTempSync('cil');
      addTearDown(() => target.deleteSync(recursive: true));
      final targetStorage = PhotoStorage(target);

      await restoreBackupArchive(
        zipBytes: zip,
        db: restored,
        storage: targetStorage,
      );

      expect(await restored.allPhotosForExport(), hasLength(1));
      expect(targetStorage.file('foto.jpg').existsSync(), isTrue);
    });

    test('sdílení je řádově menší než úplná záloha', () async {
      final payload = await payloadWithPhoto();
      final small = await buildBackupArchive(
          payload: payload, storage: storage, includePhotos: false);
      final full = await buildBackupArchive(
          payload: payload, storage: storage, includePhotos: true);

      expect(small.length, lessThan(full.length),
          reason: 'kvůli tomuhle rozdílu to celé vzniklo');
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
