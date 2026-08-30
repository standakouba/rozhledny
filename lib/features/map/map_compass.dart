import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Kompas na mapě, který zároveň drží zámek otáčení.
///
/// Zámek byl původně přepínač v Nastavení, což je špatné místo: člověk si
/// nechtěného pootočení všimne až v terénu a v tu chvíli hledá tlačítko na
/// mapě, ne v menu. Kompas ho má rovnou pod palcem — jako na mapy.cz.
///
/// Prostý přepínač o dvou stavech:
///
/// | stav | klepnutí |
/// |---|---|
/// | zamčeno (výchozí, střelka na sever) | odemkne otáčení |
/// | odemčeno | zamkne **a zároveň srovná na sever** |
///
/// Srovnání je schválně součástí zamčení, ne samostatná akce. Kdyby se dělalo
/// zvlášť, musel by uživatel nad pootočenou mapou klepnout dvakrát a mezitím
/// by mapa zůstala odemčená — tedy připravená se zase nechtěně otočit.
class MapCompass extends StatelessWidget {
  const MapCompass({
    super.key,
    required this.rotation,
    required this.locked,
    required this.onUnlock,
    required this.onLockToNorth,
  });

  /// Natočení mapy ve stupních, jak ho hlásí `MapCamera.rotation`.
  final double rotation;
  final bool locked;
  final VoidCallback onUnlock;
  final VoidCallback onLockToNorth;

  String get _tooltip => locked
      ? 'Otáčení mapy je zamčené — odemknout'
      : 'Srovnat na sever a zamknout';

  void _onTap() => locked ? onUnlock() : onLockToNorth();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: _tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _onTap,
          child: SizedBox(
            // Stejně velké jako ostatní tlačítka na mapě. Růžice se sem vejde
            // díky tomu, že písmena sedí těsně u okraje — místo se šetří tam,
            // ne na velikosti tlačítka.
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  // Souhlasně s mapou, ne proti ní: flutter_map vykresluje
                  // obsah přes `Transform.rotate(angle: camera.rotationRad)`,
                  // takže sever se na obrazovce posune o +rotation a střelka
                  // musí za ním.
                  //
                  // Pozor na záměnu s markery — ty se otáčejí o -rotationRad,
                  // ale z opačného důvodu: aby zůstaly svisle, ne aby někam
                  // ukazovaly.
                  angle: rotation * math.pi / 180,
                  child: _CompassRose(
                    color: locked
                        ? theme.colorScheme.outline
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (locked)
                  // Na úhlopříčce, kde není žádné písmeno světové strany.
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock,
                          size: 12, color: theme.colorScheme.onSurface),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Růžice: střelka s červenou polovinou na sever a české světové strany
/// S / V / J / Z po obvodu. Otáčí se jako celek s mapou, takže písmena vždycky
/// sedí na skutečné strany — proto S, ne N.
class _CompassRose extends StatelessWidget {
  const _CompassRose({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(40, 40), painter: _CompassRosePainter(color));
}

class _CompassRosePainter extends CustomPainter {
  const _CompassRosePainter(this.color);

  final Color color;

  static const _north = Color(0xFFD32F2F);

  /// Písmena po obvodu ve směru hodinových ručiček od severu.
  static const _labels = ['S', 'V', 'J', 'Z'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Písmena těsně u okraje, střelka zabírá vnitřek. Zbytečná mezera mezi
    // písmeny a okrajem by si vynutila větší tlačítko, než je potřeba.
    final labelRadius = radius - 4;
    final needleLength = radius - 10;

    for (var i = 0; i < _labels.length; i++) {
      final angle = i * math.pi / 2 - math.pi / 2; // 0 = sever, nahoru
      final painter = TextPainter(
        text: TextSpan(
          text: _labels[i],
          style: TextStyle(
            color: i == 0 ? _north : color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        center +
            Offset(math.cos(angle) * labelRadius, math.sin(angle) * labelRadius) -
            Offset(painter.width / 2, painter.height / 2),
      );
    }

    final paint = Paint()..style = PaintingStyle.fill;
    final halfWidth = size.width * 0.10;

    Path triangle(double tipY, double baseY) => Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - halfWidth, baseY)
      ..lineTo(center.dx + halfWidth, baseY)
      ..close();

    paint.color = _north;
    canvas.drawPath(
        triangle(center.dy - needleLength, center.dy + needleLength * 0.15),
        paint);

    paint.color = color;
    canvas.drawPath(
        triangle(center.dy + needleLength, center.dy - needleLength * 0.15),
        paint);
  }

  @override
  bool shouldRepaint(_CompassRosePainter oldDelegate) =>
      oldDelegate.color != color;
}
