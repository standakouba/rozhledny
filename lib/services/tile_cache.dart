import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cache dlaždic, aby mapa fungovala i tam, kde není signál.
///
/// Klíčovaná adresářem podle id podkladu — po přepnutí Mapy.com ↔ OSM se jinak
/// míchají dlaždice z různých zdrojů pod stejnými souřadnicemi.
final tileCacheStoreProvider =
    FutureProvider.family<CacheStore, String>((ref, basemapId) async {
  final base = await getApplicationCacheDirectory();
  final dir = p.join(base.path, 'tiles', basemapId);
  return FileCacheStore(dir);
});

/// Dlaždice se v OSM ani na Mapy.com nemění po hodinách; měsíc je rozumný
/// kompromis mezi aktuálností a tím, aby výlet bez signálu fungoval.
const tileMaxStale = Duration(days: 30);
