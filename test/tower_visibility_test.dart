import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/ids.dart';
import 'package:rozhledny/features/towers/tower_visibility.dart';

/// Skrývání bezejmenných rozhleden se nesmí dotknout těch navštívených —
/// návštěvy jsou jediné, co si uživatel do aplikace sám nasbíral, a zmizet
/// kvůli nastavení zobrazení nemůžou.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<TowerWithStats> tower({
    String? name,
    bool visited = false,
    TowerSource source = TowerSource.osm,
  }) async {
    final uuid = newUuid();
    final now = DateTime(2026, 1, 1);
    await db.upsertTower(TowersCompanion.insert(
      uuid: uuid,
      lat: 50.0,
      lon: 14.0,
      source: source,
      createdAt: now,
      updatedAt: now,
      name: Value(name),
    ));
    if (visited) {
      await db.upsertVisit(VisitsCompanion.insert(
        uuid: newUuid(),
        towerUuid: uuid,
        createdAt: now,
        updatedAt: now,
      ));
    }
    final all = await db.watchTowersWithStats().first;
    return all.firstWhere((t) => t.tower.uuid == uuid);
  }

  test('zapnuté nastavení nechává všechno', () async {
    final list = [
      await tower(name: 'Kleť'),
      await tower(),
      await tower(visited: true),
    ];
    expect(shownTowers(list, showUnnamed: true), hasLength(3));
  });

  test('vypnuté schová bezejmenné, ale navštívené nechá', () async {
    final named = await tower(name: 'Kleť');
    final anonymous = await tower();
    final anonymousVisited = await tower(visited: true);

    final shown = shownTowers(
      [named, anonymous, anonymousVisited],
      showUnnamed: false,
    );

    expect(shown, contains(named));
    expect(shown, contains(anonymousVisited));
    expect(shown, isNot(contains(anonymous)));
  });

  test('vlastní bod bez názvu zůstává, i když ho ještě nemám navštívený',
      () async {
    // Špendlíkem se rozhledna zapíchne cestou a pojmenuje doma. Mezitím by
    // uživateli zmizela z mapy i ze seznamu, a to je jeho vlastní práce.
    final mine = await tower(source: TowerSource.user);
    expect(shownTowers([mine], showUnnamed: false), hasLength(1));
  });

  test('prázdný název se počítá jako chybějící', () async {
    final blank = await tower(name: '   ');
    expect(shownTowers([blank], showUnnamed: false), isEmpty);
  });
}
