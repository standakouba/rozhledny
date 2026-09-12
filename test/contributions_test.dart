import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/services/contributions.dart';

/// Návrh do dat je jediná cesta, kterou se z telefonu dostane ven něco jiného
/// než záloha. Testuje se hlavně to, co se ručně ověřuje špatně: že tam
/// nepropadne nic soukromého a že se dvakrát neodešle totéž.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final kletUuid = osmTowerUuid('node', 1);

  Future<void> addOsmTower({
    required String uuid,
    String? name,
    int osmId = 1,
    bool userModified = false,
    DateTime? updatedAt,
  }) =>
      db.upsertTower(TowersCompanion.insert(
        uuid: uuid,
        lat: 48.86,
        lon: 14.29,
        source: TowerSource.osm,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: updatedAt ?? DateTime(2026, 1, 1),
        osmType: const Value('node'),
        osmId: Value(osmId),
        name: Value(name),
        userModified: Value(userModified),
      ));

  Future<void> addOwnTower({
    required String uuid,
    String name = 'Naše tajná',
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool deleted = false,
  }) =>
      db.upsertTower(TowersCompanion.insert(
        uuid: uuid,
        lat: 49.5,
        lon: 16.5,
        source: TowerSource.user,
        createdAt: createdAt ?? DateTime(2026, 5, 1),
        updatedAt: updatedAt ?? createdAt ?? DateTime(2026, 5, 1),
        name: Value(name),
        note: Value(note),
        deleted: Value(deleted),
      ));

  group('sběr', () {
    test('vezme vlastní bod i opravený bod z OSM, běžný bod z OSM ne',
        () async {
      await addOwnTower(uuid: 'vlastni');
      await addOsmTower(uuid: kletUuid, name: 'Kleť', userModified: true);
      await addOsmTower(uuid: osmTowerUuid('node', 2), name: 'Nedotčená');

      final set = await collectContributions(db);

      expect(set.count(ContributionKind.added), 1);
      expect(set.count(ContributionKind.edited), 1);
      expect(set.length, 2);
    });

    test('podruhé se posílá jen to, co přibylo', () async {
      final sentAt = DateTime(2026, 6, 1);
      await addOwnTower(uuid: 'stara', updatedAt: DateTime(2026, 5, 1));
      await addOwnTower(uuid: 'nova', updatedAt: DateTime(2026, 6, 5));

      final set = await collectContributions(db, since: sentAt);

      expect(set.towers, hasLength(1));
      expect(set.towers.single.tower.uuid, 'nova');
    });

    test('vlastní bod, který vznikl a zmizel mezi odesláními, se neposílá',
        () async {
      // Založit a hned smazat je překlep uživatele, ne zpráva pro nás.
      await addOwnTower(
        uuid: 'preklep',
        createdAt: DateTime(2026, 6, 10),
        updatedAt: DateTime(2026, 6, 11),
        deleted: true,
      );

      final set = await collectContributions(db, since: DateTime(2026, 6, 1));
      expect(set.isEmpty, isTrue);
    });

    test('smazání bodu, který už jednou odešel, se posílá', () async {
      await addOwnTower(
        uuid: 'odeslana',
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 6, 11),
        deleted: true,
      );

      final set = await collectContributions(db, since: DateTime(2026, 6, 1));
      expect(set.count(ContributionKind.deleted), 1);
    });

    test('bod, který si uživatel nechává pro sebe, se nenabízí', () async {
      await addOwnTower(uuid: 'vlastni');
      await addOsmTower(uuid: kletUuid, name: 'Kleť', userModified: true);

      await db.setTowerKeepPrivate('vlastni', true);
      final set = await collectContributions(db);

      expect(set.count(ContributionKind.added), 0);
      expect(set.count(ContributionKind.edited), 1, reason: 'oprava zůstává');

      // Vyřazení z návrhu není smazání: bod v mapě zůstává i s tím, co na
      // něm visí, a na druhý telefon se přenáší dál.
      final tower = await db.towerByUuid('vlastni');
      expect(tower!.deleted, isFalse);
      expect(await db.exportableTowers(), hasLength(2));
    });

    test('vrácené mezi nabídnuté se zase posílá', () async {
      await addOwnTower(uuid: 'vlastni');
      await db.setTowerKeepPrivate('vlastni', true);
      await db.setTowerKeepPrivate('vlastni', false);

      final set = await collectContributions(db);
      expect(set.count(ContributionKind.added), 1);
    });

    test('nahlášení nese i rozhlednu, ke které patří', () async {
      await addOsmTower(uuid: kletUuid, name: 'Kleť');
      await db.upsertReport(TowerReportsCompanion.insert(
        uuid: newUuid(),
        towerUuid: kletUuid,
        reason: TowerReportReason.gone,
        note: const Value('Zbourali ji loni na podzim.'),
        createdAt: DateTime(2026, 6, 5),
      ));

      final set = await collectContributions(db);

      expect(set.reports, hasLength(1));
      expect(set.reports.single.tower?.name, 'Kleť');
    });
  });

  group('nahlášení', () {
    test('druhé nahlášení téže rozhledny to první přepíše', () async {
      await addOsmTower(uuid: kletUuid, name: 'Kleť');
      for (final reason in [
        TowerReportReason.gone,
        TowerReportReason.notATower,
      ]) {
        await db.upsertReport(TowerReportsCompanion.insert(
          uuid: newUuid(),
          towerUuid: kletUuid,
          reason: reason,
          createdAt: DateTime(2026, 6, 5),
        ));
      }

      final all = await db.allReports();
      expect(all, hasLength(1));
      expect(all.single.reason, TowerReportReason.notATower);
    });

    test('zrušení jednoho nahlášení se nedotkne ostatních', () async {
      // Tabulka má unique index na `tower_uuid`, takže zápis jednoho hlášení
      // sahá na řádek druhého skrz `ON CONFLICT`. Že si přitom nešlapou po
      // datech, se ručně pozná těžko — a ztracené hlášení nikdo nepostrádá,
      // protože o něm ví jen ten, kdo ho psal.
      final bezdezUuid = osmTowerUuid('node', 2);
      await addOsmTower(uuid: kletUuid, name: 'Kleť');
      await addOsmTower(uuid: bezdezUuid, name: 'Bezděz', osmId: 2);

      for (final (uuid, reason) in [
        (kletUuid, TowerReportReason.gone),
        (bezdezUuid, TowerReportReason.duplicate),
      ]) {
        await db.upsertReport(TowerReportsCompanion.insert(
          uuid: newUuid(),
          towerUuid: uuid,
          reason: reason,
          createdAt: DateTime(2026, 6, 5),
        ));
      }
      expect(await db.allReports(), hasLength(2));

      await db.deleteReport(kletUuid);

      final left = await db.allReports();
      expect(left, hasLength(1));
      expect(left.single.towerUuid, bezdezUuid);
      expect(left.single.reason, TowerReportReason.duplicate);
    });

    test('zrušené nahlášení zmizí doopravdy', () async {
      await addOsmTower(uuid: kletUuid, name: 'Kleť');
      await db.upsertReport(TowerReportsCompanion.insert(
        uuid: newUuid(),
        towerUuid: kletUuid,
        reason: TowerReportReason.duplicate,
        createdAt: DateTime(2026, 6, 5),
      ));

      await db.deleteReport(kletUuid);
      expect(await db.allReports(), isEmpty);
      expect(await db.reportForTower(kletUuid), isNull);
    });
  });

  group('obsah zprávy', () {
    test('poznámka u rozhledny ven nejde, poznámka u nahlášení ano', () async {
      await addOwnTower(
        uuid: 'vlastni',
        name: 'Na Skalce',
        note: 'Byli jsme tam s Bárou, hezký výhled na přehradu.',
      );
      await addOsmTower(uuid: kletUuid, name: 'Kleť');
      await db.upsertReport(TowerReportsCompanion.insert(
        uuid: newUuid(),
        towerUuid: kletUuid,
        reason: TowerReportReason.gone,
        note: const Value('Zbourali ji loni na podzim.'),
        createdAt: DateTime(2026, 6, 5),
      ));

      final message = buildContributionMessage(await collectContributions(db));

      expect(message.body, contains('Na Skalce'));
      expect(message.body, isNot(contains('Bárou')));
      expect(message.body, contains('Zbourali ji loni na podzim.'));
      expect(message.json, isNot(contains('Bárou')));
    });

    test('návštěvy ani hodnocení se neposílají', () async {
      await addOwnTower(uuid: 'vlastni');
      await db.upsertVisit(VisitsCompanion.insert(
        uuid: newUuid(),
        towerUuid: 'vlastni',
        visitedOn: Value(DateTime(2026, 5, 20)),
        rating: const Value(5),
        note: const Value('Nahoře byl vítr.'),
        createdAt: DateTime(2026, 5, 20),
        updatedAt: DateTime(2026, 5, 20),
      ));

      final message = buildContributionMessage(await collectContributions(db));

      expect(message.json, isNot(contains('Nahoře byl vítr.')));
      expect(message.json, isNot(contains('rating')));
      expect(message.json, isNot(contains('visit')));
    });

    test('u opraveného bodu je vidět, kterého objektu v OSM se týká',
        () async {
      await addOsmTower(
          uuid: kletUuid, name: 'Josefova věž', userModified: true);

      final message = buildContributionMessage(
        await collectContributions(db),
        appVersion: '0.17.0+29',
        dataset: '2:abcdef',
      );

      expect(message.json, contains('"osm": "node/1"'));
      expect(message.json, contains('"kind": "edited"'));
      expect(message.json, contains('"app": "0.17.0+29"'));
      expect(message.json, contains('"dataset": "2:abcdef"'));
    });

    test('prázdný návrh se pozná', () async {
      final set = await collectContributions(db);
      expect(set.isEmpty, isTrue);
      expect(set.summary, 'Zatím není co posílat');
    });
  });
}
