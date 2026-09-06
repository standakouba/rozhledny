import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings.dart';
import 'database.dart';
import 'seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Postará se o to, aby v databázi byla aktuální základní data rozhleden.
///
/// Při prvním startu je tam nasype z assetu, potom je s ním po každé jeho
/// změně srovná — opravený název nebo nově přibylá rozhledna se tak dostanou
/// i do telefonu, kde aplikace už dávno běží. Když se asset nezměnil, stojí
/// to jen otisk souboru a dotaz na počet řádků.
final seedProvider = FutureProvider<AssetSyncReport>((ref) async {
  final db = ref.watch(databaseProvider);
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return syncFromAssetIfChanged(db, prefs);
});

/// Zdroj pravdy pro mapu i seznam. Seed se počká, aby první snímek nebyl prázdný.
final towersProvider = StreamProvider<List<TowerWithStats>>((ref) async* {
  await ref.watch(seedProvider.future);
  yield* ref.watch(databaseProvider).watchTowersWithStats();
});

final towerProvider = StreamProvider.family<TowerWithStats?, String>((
  ref,
  uuid,
) async* {
  await ref.watch(seedProvider.future);
  yield* ref.watch(databaseProvider).watchTowerWithStats(uuid);
});

final visitsProvider = StreamProvider.family<List<Visit>, String>((
  ref,
  towerUuid,
) {
  return ref.watch(databaseProvider).watchVisits(towerUuid);
});
