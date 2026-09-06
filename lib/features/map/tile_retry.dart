import 'dart:async';

/// Opakování dlaždic, které se nenačetly.
///
/// flutter_map nepovedenou dlaždici sám nikdy nezkusí znovu — nechá na jejím
/// místě roztažený podklad z nižšího zoomu (`EvictErrorTileStrategy.none`).
/// Po startu telefonu se první dávka dlaždic trefí do chvíle, kdy síť ještě
/// není nahoře, a mapa pak zůstane rozmazaná, i když síť mezitím naskočí.
///
/// Pokusy jsou schválně omezené: bez signálu by se jinak opakovalo donekonečna
/// a mapa by na mobilních datech ožrala baterku dotazy, které nemají šanci
/// projít. Posun mapy pokusy vrací zpátky — je to nový výřez, nové dlaždice
/// a nejspíš i jiná chvíle.
class TileRetry {
  TileRetry({
    required this.onRetry,
    this.attempts = 3,
    this.delay = const Duration(seconds: 3),
  });

  /// Co se má stát, když je čas zkusit dlaždice znovu.
  final void Function() onRetry;

  /// Kolikrát po sobě se opakuje, než to nad jedním výřezem vzdá.
  final int attempts;

  /// Odstup mezi nepovedenou dlaždicí a dalším pokusem.
  final Duration delay;

  Timer? _timer;
  late int _left = attempts;
  bool _disposed = false;

  /// Ohlásí dlaždici, která se nenačetla.
  ///
  /// Nepovede se obvykle celá obrazovka najednou, takže z celé dávky vzejde
  /// jediné opakování — ne dvacet.
  void failed() {
    if (_disposed || _timer != null || _left <= 0) return;
    _timer = Timer(delay, () {
      _timer = null;
      _left--;
      if (!_disposed) onRetry();
    });
  }

  /// Mapa se posunula nebo přiblížila: pokusy začínají nanovo.
  void viewChanged() => _left = attempts;

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
