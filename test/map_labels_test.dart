import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/features/map/tower_marker.dart';

/// Jmenovky u značek se rozhodují na pixelech, ne na souřadnicích, a chyba
/// se pozná až na mapě v terénu — proto na to test.
void main() {
  ({String uuid, Offset pixel}) at(String uuid, double dx, double dy) =>
      (uuid: uuid, pixel: Offset(dx, dy));

  test('daleko od sebe dostanou jmenovku všechny', () {
    final result = labelledMarkers([
      at('a', 0, 0),
      at('b', 300, 0),
      at('c', 0, 300),
    ]);
    expect(result, {'a', 'b', 'c'});
  });

  test('ze dvou blízkých si jméno nechá jen jeden', () {
    final result = labelledMarkers([
      at('a', 100, 100),
      at('b', 110, 105),
    ]);
    expect(result, {'a'});
  });

  test('výběr nezávisí na pořadí vstupu', () {
    // Pořadí bodů se mění s tím, jak je vrací databáze a ořez výřezem.
    // Kdyby na něm výběr závisel, jmenovka by při posunu mapy poskakovala
    // mezi sousedy.
    final forward = labelledMarkers([at('a', 100, 100), at('b', 110, 105)]);
    final backward = labelledMarkers([at('b', 110, 105), at('a', 100, 100)]);
    expect(forward, backward);
  });

  test('body nad sebou si taky stíní', () {
    // Jmenovka visí pod značkou, takže bod kousek níž je zakrytý textem
    // toho nad ním, i když jsou na stejné svislici.
    final result = labelledMarkers([
      at('a', 100, 100),
      at('b', 100, 120),
    ]);
    expect(result.length, 1);
  });

  test('vedle sebe s dostatečnou mezerou se vejdou oba', () {
    final result = labelledMarkers([
      at('a', 100, 100),
      at('b', 100 + labelWidth, 100),
    ]);
    expect(result, {'a', 'b'});
  });

  test('bod bez sousedů uprostřed shluku o jmenovku nepřijde', () {
    final result = labelledMarkers([
      at('a', 0, 0),
      at('b', 8, 4),
      at('c', 500, 500),
    ]);
    expect(result, contains('c'));
    expect(result.length, 2);
  });
}
