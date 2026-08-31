import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Úklid po zrušených fotkách u návštěv.
///
/// Fotky se ukládaly jako soubory v adresáři aplikace a v databázi byla jen
/// jména. Migrace na schéma 4 zahodila tabulku, takže na ty soubory už nic
/// neodkazuje — a bez tohohle úklidu by v telefonu ležely až do odinstalace,
/// neviditelné a k ničemu.
///
/// Tenhle soubor je přechodný. Až bude jisté, že všechny instalace prošly
/// migrací, dá se odstranit celý.
Future<void> removeLegacyVisitPhotos() async {
  try {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'photos'));
    if (dir.existsSync()) await dir.delete(recursive: true);
  } catch (_) {
    // Úklid je kosmetický. Když se nepovede, aplikace kvůli tomu spadnout
    // nesmí — pár osiřelých souborů nikomu nevadí.
  }
}
