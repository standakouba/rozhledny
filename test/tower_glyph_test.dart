import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/features/map/tower_glyph.dart';

/// Silueta sedí uvnitř kolečka značky, které má pevných 28 px. Takový rodič
/// posílá dítěti těsné constraints a widget, který si je nepohlídá, se roztáhne
/// přes celý vnitřek — věž pak nohama přeteče ven z kolečka.
void main() {
  Finder glyphBox() => find.descendant(
        of: find.byType(TowerGlyph),
        matching: find.byType(CustomPaint),
      );

  testWidgets('drží si zadanou velikost i v těsném rodiči', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          // Přesně to, co dělá kolečko značky: pevný rozměr bez odsazení.
          child: SizedBox(
            width: 24,
            height: 24,
            child: TowerGlyph(size: 14, color: Colors.white),
          ),
        ),
      ),
    ));

    final size = tester.getSize(glyphBox());
    expect(size.height, 14);
    expect(size.width, closeTo(14 * 0.8, 0.01),
        reason: 'šířku určuje ochoz, nejširší prvek věže');
  });

  testWidgets('vejde se do kolečka i s rezervou', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: Key('krouzek'),
            width: 24,
            height: 24,
            child: TowerGlyph(size: 14, color: Colors.white),
          ),
        ),
      ),
    ));

    final glyph = tester.getRect(glyphBox());
    final circle = tester.getRect(find.byKey(const Key('krouzek')));
    // Kolem věže musí zbýt vzduch, jinak se opře o obrys kolečka a z celku
    // je oblouk místo rozhledny.
    expect(glyph.top - circle.top, greaterThanOrEqualTo(3));
    expect(circle.bottom - glyph.bottom, greaterThanOrEqualTo(3));
    expect(glyph.left - circle.left, greaterThanOrEqualTo(3));
  });
}
