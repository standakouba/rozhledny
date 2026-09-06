import 'package:flutter/material.dart';

/// Silueta rozhledny — tentýž tvar, jaký má ikona aplikace.
///
/// Proporce jsou přepsané z `tools/make_icon.dart`, aby značka na mapě a ikona
/// v launcheru ukazovaly totéž. Kreslí se kódem, ne z obrázku: v 17 pixelech
/// by se zmenšené PNG rozmazalo a na displeji s jinou hustotou by se rozteklo.
///
/// Bez příček mezi nohami, které ikona má. Ve 48 dp jsou ještě znát, v 17
/// vycházejí na necelý pixel a udělaly by z věže šedý flek.
class TowerGlyph extends StatelessWidget {
  const TowerGlyph({super.key, required this.size, required this.color});

  /// Výška siluety. Šířku si dopočítá z proporcí (ochoz je nejširší prvek).
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Center je tu schválně. Rodič (kolečko značky) má pevnou velikost a
    // předává dítěti těsné constraints — samotný CustomPaint by je poslechl,
    // zadanou velikost zahodil a nakreslil věž přes celý vnitřek kolečka,
    // takže by nohama přetékala ven. Center dítěti constraints uvolní.
    return Center(
      child: SizedBox(
        width: size * _galleryHalf * 2,
        height: size,
        child: CustomPaint(painter: _TowerGlyphPainter(color)),
      ),
    );
  }
}

// Svislé rozvržení věže odshora dolů, v podílech výšky.
//
// Proti ikoně jsou proporce zesílené: ochoz je širší a vyšší, nohy tlustší
// a víc rozkročené. V 48 dp launcheru vychází původní kresba akorát, v 18 px
// na mapě z ní byl zvon — ochoz nebyl znát a nohy vycházely na 1,4 px, tedy
// pod hranici, kde je vyhlazování ještě udrží jako dvě čáry.
const _roofBottom = 0.20;
const _galleryBottom = _roofBottom + 0.15;
const _roofHalf = 0.30;
const _galleryHalf = 0.40;
const _legTopHalf = 0.14;
const _legBottomHalf = 0.36;
const _legThickness = 0.13;

class _TowerGlyphPainter extends CustomPainter {
  const _TowerGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final span = size.height;
    final center = size.width / 2;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Střecha.
    canvas.drawPath(
      Path()
        ..moveTo(center, 0)
        ..lineTo(center + span * _roofHalf, span * _roofBottom)
        ..lineTo(center - span * _roofHalf, span * _roofBottom)
        ..close(),
      paint,
    );

    // Ochoz — nejširší prvek, dělá z věže rozhlednu a ne komín.
    canvas.drawRect(
      Rect.fromLTRB(
        center - span * _galleryHalf,
        span * _roofBottom,
        center + span * _galleryHalf,
        span * _galleryBottom,
      ),
      paint,
    );

    // Nohy: kuželové, nahoře užší než dole.
    for (final side in [-1, 1]) {
      final xTop = center + side * span * _legTopHalf;
      final xBottom = center + side * span * _legBottomHalf;
      final half = span * _legThickness / 2;
      canvas.drawPath(
        Path()
          ..moveTo(xTop - half, span * _galleryBottom)
          ..lineTo(xTop + half, span * _galleryBottom)
          ..lineTo(xBottom + half, span)
          ..lineTo(xBottom - half, span)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TowerGlyphPainter old) => old.color != color;
}
