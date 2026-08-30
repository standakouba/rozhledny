import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';

part 'database.g.dart';

/// Odkud rozhledna pochází. Rozlišení je podstatné pro export (posílají se jen
/// vlastní body, ty z OSM má druhý telefon taky) i pro pozdější aktualizaci dat.
enum TowerSource { osm, user }

/// Rozhledna. `uuid` je párovací klíč napříč telefony — u bodů z OSM je
/// odvozený z `osmType/osmId`, takže na obou zařízeních vyjde stejně.
class Towers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();

  TextColumn get osmType => text().nullable()();
  IntColumn get osmId => integer().nullable()();

  TextColumn get name => text().nullable()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get height => real().nullable()();
  RealColumn get ele => real().nullable()();
  TextColumn get region => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get note => text().nullable()();

  // Praktické údaje z OSM. V assetu byly od začátku, jen se nikam nedostaly.
  TextColumn get openingHours => text().nullable()();
  TextColumn get fee => text().nullable()();
  TextColumn get access => text().nullable()();

  // Popis a fotka z Wikidat / Wikipedie / Commons. Doplňuje je generátor
  // tools/fetch_wiki.dart do assetu, aplikace je jen zobrazuje.
  //
  // Fotka se ukládá jako URL, ne jako soubor: 325 snímků by v APK zabralo
  // ~10 MB a stejně by zastaraly. Stahují se na vyžádání a zůstávají v cache.
  //
  // Autor a licence jsou povinné k zobrazení, ne volitelný detail — snímky
  // na Commons mají AttributionRequired.
  TextColumn get wikidataId => text().nullable()();
  TextColumn get wikipediaTitle => text().nullable()();
  TextColumn get wikipediaUrl => text().nullable()();
  TextColumn get wikipediaExtract => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get photoAuthor => text().nullable()();
  TextColumn get photoLicense => text().nullable()();
  TextColumn get photoLicenseUrl => text().nullable()();
  TextColumn get photoPageUrl => text().nullable()();

  TextColumn get source => textEnum<TowerSource>()();

  /// Ručně upravený záznam z OSM. Pozdější aktualizace dat ho nesmí přepsat.
  BoolColumn get userModified => boolean().withDefault(const Constant(false))();

  /// Rozhledna, která z OSM zmizela. Nemaže se — můžou na ní viset návštěvy.
  BoolColumn get osmMissing => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Tombstone místo skutečného smazání, jinak by import záznam vzkřísil.
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

/// Jedna návštěva rozhledny. Vztah k [Towers] je 1:N — na Kleť se jezdí opakovaně
/// a každá cesta je samostatný záznam. Vědomě žádný unique index na [towerUuid].
class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get towerUuid => text()();

  /// Jen datum, bez času — zapisuje se i zpětně z papírové mapy.
  ///
  /// Nepovinné schválně: u rozhleden nasbíraných před aplikací si po letech
  /// nikdo nevzpomene, kdy tam byl. Vynucené datum by vedlo k vymýšlení,
  /// a smyšlený údaj je horší než přiznané „nevím“ — zaneřádil by statistiky
  /// po letech a nešel by odlišit od skutečného.
  ///
  /// Návštěva bez data se tedy počítá do celkového počtu i do pokořených
  /// rozhleden, ale do rozpadu po letech ne.
  DateTimeColumn get visitedOn => dateTime().nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

/// Fotka patří konkrétní návštěvě. V databázi je jen jméno souboru,
/// samotný obrázek leží v adresáři aplikace.
class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get visitUuid => text()();
  TextColumn get fileName => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
}

/// Rozhledna spolu s agregací jejích návštěv.
///
/// Agregace se počítá dotazem, ne uloženým příznakem na [Towers] — příznak by se
/// rozešel s realitou při importu z druhého telefonu.
class TowerWithStats {
  const TowerWithStats({
    required this.tower,
    required this.visitCount,
    this.firstVisit,
    this.lastVisit,
    this.bestRating,
  });

  final Tower tower;
  final int visitCount;
  final DateTime? firstVisit;
  final DateTime? lastVisit;
  final int? bestRating;

  bool get isVisited => visitCount > 0;
}

@DriftDatabase(tables: [Towers, Visits, Photos])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'rozhledny'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async {
          await m.createAll();
          // Návštěvy se čtou skoro vždy přes rozhlednu, ať už kvůli detailu
          // nebo kvůli počtu na markeru.
          await customStatement(
              'CREATE INDEX idx_visits_tower ON visits (tower_uuid)');
          await customStatement(
              'CREATE INDEX idx_photos_visit ON photos (visit_uuid)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            for (final column in [
              towers.openingHours,
              towers.fee,
              towers.access,
              towers.wikidataId,
              towers.wikipediaTitle,
              towers.wikipediaUrl,
              towers.wikipediaExtract,
              towers.photoUrl,
              towers.photoAuthor,
              towers.photoLicense,
              towers.photoLicenseUrl,
              towers.photoPageUrl,
            ]) {
              await m.addColumn(towers, column);
            }
            // Seed běží jen do prázdné databáze, takže na telefonu, kde už
            // aplikace jednou byla, by nová pole zůstala navždy prázdná.
            // Doplní je proto migrace — a sahá výhradně na wiki sloupce
            // rozhleden z OSM, aby se návštěv a vlastních bodů ani nedotkla.
            await applyEnrichmentFromAsset(this);
          }
          if (from < 3) {
            // SQLite neumí u sloupce zrušit NOT NULL, takže se tabulka musí
            // přestavět. `alterTable` ji vytvoří podle nového schématu
            // a data překopíruje podle jmen sloupců — zapsané návštěvy
            // tedy zůstávají, jen u nich datum smí být prázdné.
            await m.alterTable(TableMigration(visits));
          }
        },
      );

  // ------------------------------------------------------------- rozhledny

  /// Všechny rozhledny s agregací návštěv. Používá mapa i seznam; při ~700
  /// řádcích je jeden dotaz levnější než počítat návštěvy pro každý marker.
  Stream<List<TowerWithStats>> watchTowersWithStats() {
    final count = visits.uuid.count();
    final first = visits.visitedOn.min();
    final last = visits.visitedOn.max();
    final best = visits.rating.max();

    final query = select(towers).join([
      leftOuterJoin(
        visits,
        visits.towerUuid.equalsExp(towers.uuid) & visits.deleted.equals(false),
        useColumns: false,
      ),
    ])
      ..where(towers.deleted.equals(false))
      ..addColumns([count, first, last, best])
      ..groupBy([towers.id]);

    return query.watch().map((rows) => [
          for (final row in rows)
            TowerWithStats(
              tower: row.readTable(towers),
              visitCount: row.read(count) ?? 0,
              firstVisit: row.read(first),
              lastVisit: row.read(last),
              bestRating: row.read(best),
            ),
        ]);
  }

  Stream<TowerWithStats?> watchTowerWithStats(String uuid) =>
      watchTowersWithStats().map((all) {
        for (final t in all) {
          if (t.tower.uuid == uuid) return t;
        }
        return null;
      });

  /// Vloží, nebo přepíše rozhlednu se stejným `uuid`.
  ///
  /// Cíl konfliktu musí být `uuid`, ne primární klíč: `insertOnConflictUpdate`
  /// míří na `id`, které volající (editor formuláře) nezná ani nemá znát.
  /// Bez `id` ke kolizi na primárním klíči nedojde, vložení projde dál
  /// a rozbije se až o unikátní `uuid` — úprava názvu pak tiše spadne.
  Future<void> upsertTower(TowersCompanion tower) => into(towers).insert(
        tower,
        onConflict: DoUpdate((_) => tower, target: [towers.uuid]),
      );

  /// Vlastní rozhlednu jen označí za smazanou a totéž udělá s jejími
  /// návštěvami — jinak by import vrátil obojí zpátky.
  Future<void> softDeleteTower(String uuid) async {
    final now = DateTime.now();
    await transaction(() async {
      await (update(towers)..where((t) => t.uuid.equals(uuid)))
          .write(TowersCompanion(deleted: const Value(true), updatedAt: Value(now)));
      await (update(visits)..where((v) => v.towerUuid.equals(uuid)))
          .write(VisitsCompanion(deleted: const Value(true), updatedAt: Value(now)));
    });
  }

  // -------------------------------------------------------------- návštěvy

  /// Návštěvy jedné rozhledny, od nejnovější.
  Stream<List<Visit>> watchVisits(String towerUuid) => (select(visits)
        ..where((v) => v.towerUuid.equals(towerUuid) & v.deleted.equals(false))
        ..orderBy([
          (v) => OrderingTerm.desc(v.visitedOn),
          (v) => OrderingTerm.desc(v.createdAt),
        ]))
      .watch();

  /// Všechny návštěvy napříč rozhlednami — pro statistiky po letech.
  Stream<List<Visit>> watchAllVisits() =>
      (select(visits)..where((v) => v.deleted.equals(false))).watch();

  /// Totéž co [upsertTower] — párování podle `uuid`, ne podle `id`.
  Future<void> upsertVisit(VisitsCompanion visit) => into(visits).insert(
        visit,
        onConflict: DoUpdate((_) => visit, target: [visits.uuid]),
      );

  Future<void> softDeleteVisit(String uuid) =>
      (update(visits)..where((v) => v.uuid.equals(uuid))).write(
        VisitsCompanion(deleted: const Value(true), updatedAt: Value(DateTime.now())),
      );

  // ----------------------------------------------------------------- fotky

  Stream<List<Photo>> watchPhotos(String visitUuid) => (select(photos)
        ..where((p) => p.visitUuid.equals(visitUuid) & p.deleted.equals(false))
        ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
      .watch();

  Future<void> insertPhoto(PhotosCompanion photo) => into(photos).insert(photo);

  Future<void> softDeletePhoto(String uuid) =>
      (update(photos)..where((p) => p.uuid.equals(uuid)))
          .write(const PhotosCompanion(deleted: Value(true)));

  // -------------------------------------------------- záloha a slučování

  Future<Tower?> towerByUuid(String uuid) =>
      (select(towers)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();

  Future<Visit?> visitByUuid(String uuid) =>
      (select(visits)..where((v) => v.uuid.equals(uuid))).getSingleOrNull();

  Future<Photo?> photoByUuid(String uuid) =>
      (select(photos)..where((p) => p.uuid.equals(uuid))).getSingleOrNull();

  /// Co se posílá na druhý telefon.
  ///
  /// Rozhledny z OSM se neposílají — druhá strana je má ze stejného assetu
  /// pod stejným UUID. Výjimkou je ručně upravený bod z OSM, kde by se jinak
  /// oprava názvu nebo polohy nepřenesla.
  Future<List<Tower>> exportableTowers() => (select(towers)
        ..where((t) =>
            t.source.equalsValue(TowerSource.user) | t.userModified.equals(true)))
      .get();

  Future<List<Visit>> allVisitsForExport() => select(visits).get();

  Future<List<Photo>> allPhotosForExport() => select(photos).get();

  /// Návštěvy téže rozhledny ve stejný den pod různým UUID.
  ///
  /// Vznikají, když stejný výlet zapíšou oba telefony zvlášť — slučování podle
  /// UUID je nespojí a počet návštěv by se tichounce nafukoval s každým
  /// importem. Rozhodnutí necháváme na uživateli, protože dvě návštěvy jednoho
  /// místa v jednom dni jsou teoreticky legitimní.
  Future<List<List<Visit>>> duplicateVisitGroups() async {
    final all = await (select(visits)..where((v) => v.deleted.equals(false)))
        .get();
    final byKey = <String, List<Visit>>{};
    for (final v in all) {
      // Návštěvy bez data se neporovnávají. Dvě takové na téže rozhledně
      // můžou stejně dobře být dva různé výlety jako jeden zapsaný dvakrát,
      // a hádat za uživatele by tu znamenalo mazat mu záznamy.
      final on = v.visitedOn;
      if (on == null) continue;
      final day = DateTime(on.year, on.month, on.day);
      byKey.putIfAbsent('${v.towerUuid}@${day.toIso8601String()}', () => [])
          .add(v);
    }
    return [
      for (final group in byKey.values)
        if (group.length > 1) group,
    ];
  }

  Future<bool> get isEmpty async {
    final row = await (selectOnly(towers)..addColumns([towers.id.count()]))
        .getSingle();
    return (row.read(towers.id.count()) ?? 0) == 0;
  }
}
