import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/features/map/tile_retry.dart';

/// Opakování běží na časovači, takže testy pracují s odstupem v milisekundách
/// místo vteřin. Jde o počítání pokusů, ne o konkrétní prodlevu.
void main() {
  const delay = Duration(milliseconds: 10);
  Future<void> wait() => Future<void>.delayed(const Duration(milliseconds: 40));

  test('po nepovedené dlaždici se načtení zopakuje', () async {
    var retries = 0;
    final retry = TileRetry(onRetry: () => retries++, delay: delay);
    addTearDown(retry.dispose);

    retry.failed();
    await wait();

    expect(retries, 1);
  });

  test('z celé nepovedené obrazovky vzejde jediné opakování', () async {
    // Nepovede se obvykle všechno naráz, protože je telefon mimo síť, ne
    // jedna dlaždice. Dvacet časovačů na dvacet dlaždic nedává smysl.
    var retries = 0;
    final retry = TileRetry(onRetry: () => retries++, delay: delay);
    addTearDown(retry.dispose);

    for (var i = 0; i < 20; i++) {
      retry.failed();
    }
    await wait();

    expect(retries, 1);
  });

  test('nad jedním výřezem se pokusy vyčerpají', () async {
    // Bez signálu nemá cenu zkoušet donekonečna — na mobilních datech by to
    // jen ožíralo baterku dotazy, které nemají šanci projít.
    var retries = 0;
    final retry = TileRetry(onRetry: () => retries++, attempts: 2, delay: delay);
    addTearDown(retry.dispose);

    for (var i = 0; i < 5; i++) {
      retry.failed();
      await wait();
    }

    expect(retries, 2);
  });

  test('posun mapy vrátí pokusy zpátky', () async {
    var retries = 0;
    final retry = TileRetry(onRetry: () => retries++, attempts: 1, delay: delay);
    addTearDown(retry.dispose);

    retry.failed();
    await wait();
    retry.failed();
    await wait();
    expect(retries, 1, reason: 'jeden pokus je vyčerpaný');

    retry.viewChanged();
    retry.failed();
    await wait();

    expect(retries, 2);
  });

  test('po opuštění mapy se naplánované opakování nespustí', () async {
    // Časovač přežije odchod z obrazovky a sáhl by na widget, který už není.
    var retries = 0;
    final retry = TileRetry(onRetry: () => retries++, delay: delay);

    retry.failed();
    retry.dispose();
    await wait();

    expect(retries, 0);
  });
}
