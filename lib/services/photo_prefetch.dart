import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// Stažení všech fotek rozhleden dopředu, aby fungovaly i bez signálu.
///
/// Fotky se jinak stahují až při otevření detailu, což v lese bez signálu
/// nepomůže. Tohle je „připravit se před výletem“ — pustí se na Wi-Fi doma.
class PrefetchProgress {
  const PrefetchProgress({
    required this.done,
    required this.total,
    required this.failed,
  });

  final int done;
  final int total;
  final int failed;

  bool get finished => done >= total;
  double get ratio => total == 0 ? 1 : done / total;
}

class PhotoPrefetcher extends StateNotifier<PrefetchProgress?> {
  PhotoPrefetcher(this._ref) : super(null);

  final Ref _ref;
  bool _cancelled = false;

  /// Používá stejnou cache jako `CachedNetworkImage` v detailu — proto
  /// `DefaultCacheManager` a ne vlastní adresář. Stažené fotky se pak
  /// v detailu vezmou z disku, ne ze sítě.
  final _cache = DefaultCacheManager();

  void cancel() => _cancelled = true;

  Future<void> run() async {
    _cancelled = false;
    final towers = await _ref.read(towersProvider.future);
    final urls = [
      for (final t in towers)
        if (t.tower.photoUrl != null) t.tower.photoUrl!,
    ];

    var done = 0, failed = 0;
    state = PrefetchProgress(done: 0, total: urls.length, failed: 0);

    for (final url in urls) {
      if (_cancelled) break;
      try {
        // Už stažené soubory se nestahují znovu, takže opakované spuštění
        // je levné a dá se jím dohnat, co minule spadlo na výpadku sítě.
        await _cache.downloadFile(url);
      } catch (_) {
        failed++;
      }
      done++;
      state = PrefetchProgress(done: done, total: urls.length, failed: failed);
    }
  }

  Future<void> clear() async {
    await _cache.emptyCache();
    state = null;
  }
}

final photoPrefetchProvider =
    StateNotifierProvider<PhotoPrefetcher, PrefetchProgress?>(
  PhotoPrefetcher.new,
);

/// Kolik rozhleden vůbec nějakou fotku má — bez toho by tlačítko nešlo popsat.
final photoCountProvider = Provider<int>((ref) {
  final towers = ref.watch(towersProvider).value ?? const [];
  return towers.where((t) => t.tower.photoUrl != null).length;
});
