import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../data/providers.dart';
import 'backup.dart';

/// Příjem zálohy, kterou někdo poslal do aplikace přes systémové sdílení.
///
/// Smysl je zkrátit „přišel mi soubor" na jedno klepnutí. Bez toho musí
/// příjemce soubor uložit, otevřít aplikaci, najít Nastavení a vybrat ho —
/// pět kroků po každém výletu je dost na to, aby to lidi přestali dělat.
class IncomingShare {
  IncomingShare(this._ref);

  final Ref _ref;
  StreamSubscription<List<SharedMediaFile>>? _sub;

  /// Výsledek posledního příjmu, aby ho šlo ukázat uživateli.
  final results = StreamController<MergeReport>.broadcast();

  /// Chyba, kterou má smysl ukázat — cizí ZIP, novější formát zálohy.
  final errors = StreamController<String>.broadcast();

  void start() {
    // Dva různé případy: aplikace už běžela (stream), nebo ji soubor
    // teprve probudil (initialMedia). Bez toho druhého by první sdílení
    // po zavření aplikace nikdo nezpracoval.
    _sub = ReceiveSharingIntent.instance.getMediaStream().listen(_handle);
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handle(files);
      // Bez tohohle by se tentýž soubor zpracoval znovu při každém
      // návratu do aplikace.
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handle(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    for (final f in files) {
      await _import(f.path);
    }
  }

  Future<void> _import(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final report = await restoreBackupArchive(
        zipBytes: bytes,
        db: _ref.read(databaseProvider),
      );
      results.add(report);
    } on FormatException catch (e) {
      // Uživatel může do aplikace poslat jakýkoli soubor. Chceme
      // srozumitelnou hlášku, ne pád ani mlčení.
      errors.add(e.message);
    } catch (e) {
      errors.add('Soubor se nepodařilo načíst: $e');
    }
  }

  void dispose() {
    _sub?.cancel();
    results.close();
    errors.close();
  }
}

final incomingShareProvider = Provider<IncomingShare>((ref) {
  final share = IncomingShare(ref);
  ref.onDispose(share.dispose);
  return share;
});
