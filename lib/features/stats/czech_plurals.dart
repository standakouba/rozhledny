library;

/// Skloňování podstatných jmen po číslovce.
///
/// Čeština má tři tvary — jednička, dvojka až čtyřka, pětka a výš — a žádná
/// z formátovacích knihoven v projektu to neřeší. Vlastní soubor proto, že
/// jde o čistou textovou logiku, kterou má smysl testovat samostatně.

/// „1 návštěva / 2 návštěvy / 5 návštěv“
String visitWord(int n) {
  if (n == 1) return 'návštěva';
  if (n >= 2 && n <= 4) return 'návštěvy';
  return 'návštěv';
}

/// Kolikrát se člověk vrátil někam, kde už byl.
///
/// Jednotné číslo má jinou stavbu věty než množné — „na 1 výlet jste se
/// vraceli“ česky nezní, takže se pro jedničku formuluje zvlášť.
String returnsSentence(int n) {
  if (n == 1) return 'Jednou jste se vrátili někam, kde jste už byli.';
  final word = n >= 2 && n <= 4 ? 'výlety' : 'výletů';
  return 'Na $n $word jste se vraceli někam, kde jste už byli.';
}
