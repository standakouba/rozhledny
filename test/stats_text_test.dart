import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/features/stats/czech_plurals.dart';

/// Čeština skloňuje jinak jedničku, jinak dvojku až čtyřku a jinak pětku a výš.
/// Bez toho vzniká „Na 3 výletů“ — drobnost, která je ale na hlavní obrazovce
/// a okamžitě z aplikace udělá nedodělek.
void main() {
  group('návštěvy', () {
    test('jednotné číslo', () => expect(visitWord(1), 'návštěva'));
    test('dvě až čtyři', () {
      for (final n in [2, 3, 4]) {
        expect(visitWord(n), 'návštěvy', reason: 'pro $n');
      }
    });
    test('pět a víc', () {
      for (final n in [0, 5, 11, 27, 100]) {
        expect(visitWord(n), 'návštěv', reason: 'pro $n');
      }
    });
  });

  group('návraty na už navštívené rozhledny', () {
    test('jeden návrat má vlastní stavbu věty', () {
      // „Na 1 výlet jste se vraceli“ česky nezní, proto zvláštní tvar.
      expect(returnsSentence(1),
          'Jednou jste se vrátili někam, kde jste už byli.');
    });

    test('dva až čtyři používají „výlety“', () {
      for (final n in [2, 3, 4]) {
        expect(returnsSentence(n), contains('$n výlety'), reason: 'pro $n');
      }
    });

    test('pět a víc používá „výletů“', () {
      for (final n in [5, 11, 27]) {
        expect(returnsSentence(n), contains('$n výletů'), reason: 'pro $n');
      }
    });
  });
}
