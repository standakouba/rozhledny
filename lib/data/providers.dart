import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Naplní prázdnou databázi rozhlednami z assetu. Doběhne jen při prvním startu;
/// potom je to jeden dotaz na počet řádků.
final seedProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  if (!await db.isEmpty) return 0;
  return seedFromAsset(db);
});

/// Zdroj pravdy pro mapu i seznam. Seed se počká, aby první snímek nebyl prázdný.
final towersProvider = StreamProvider<List<TowerWithStats>>((ref) async* {
  await ref.watch(seedProvider.future);
  yield* ref.watch(databaseProvider).watchTowersWithStats();
});

final towerProvider =
    StreamProvider.family<TowerWithStats?, String>((ref, uuid) async* {
  await ref.watch(seedProvider.future);
  yield* ref.watch(databaseProvider).watchTowerWithStats(uuid);
});

final visitsProvider =
    StreamProvider.family<List<Visit>, String>((ref, towerUuid) {
  return ref.watch(databaseProvider).watchVisits(towerUuid);
});

final photosProvider =
    StreamProvider.family<List<Photo>, String>((ref, visitUuid) {
  return ref.watch(databaseProvider).watchPhotos(visitUuid);
});
