// Nakreslí ikonu aplikace: siluetu rozhledny.
//
//   dart run tools/make_icon.dart
//   dart run flutter_launcher_icons
//
// Kreslí se kódem, ne v grafickém editoru, aby šla ikona kdykoli přegenerovat
// v jiné barvě nebo velikosti a aby bylo v historii vidět, proč vypadá takhle.
//
// Tvar je schválně hrubý: v launcheru má 48 dp, takže příhradová konstrukce
// ani zábradlí by se slily v šeď. Zůstává střecha, ochoz a dvě kuželové nohy
// se dvěma příčkami — to je při té velikosti ještě rozeznatelné.

import 'dart:io';

import 'package:image/image.dart';

const _size = 1024;

/// Klasická ikona je celá vidět, takže věž potřebuje jen pohledový okraj.
const _legacyScale = 0.62;

/// Popředí adaptivní ikony se kreslí **větší**, protože flutter_launcher_icons
/// mu přidává 16% inset na každé straně. Věž tedy ve výsledku zabere zhruba
/// 0.63 × 0.68 ≈ 43 % ikony — o kus uvnitř bezpečné zóny, kterou Android nechává.
/// Kdyby se použilo totéž měřítko jako u klasické ikony, vyšlo by 42 %
/// a v launcheru by z toho byl malý flek uprostřed zeleného pole.
const _foregroundScale = 0.63;

final _green = ColorRgb8(0x2E, 0x7D, 0x32);
final _white = ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);

void main() {
  final dir = Directory('assets/icon')..createSync(recursive: true);

  // Popředí adaptivní ikony: průhledné, pozadí dodá systém z barvy.
  final foreground = Image(width: _size, height: _size, numChannels: 4);
  _drawTower(foreground, _white, _foregroundScale);
  File('${dir.path}/icon_foreground.png')
      .writeAsBytesSync(encodePng(foreground));

  // Klasická ikona pro starší Androidy: tatáž věž na zeleném poli.
  final legacy = Image(width: _size, height: _size, numChannels: 4);
  fill(legacy, color: _green);
  _drawTower(legacy, _white, _legacyScale);
  File('${dir.path}/icon.png').writeAsBytesSync(encodePng(legacy));

  stdout.writeln('Hotovo -> ${dir.path}/icon.png, icon_foreground.png');
}

void _drawTower(Image img, Color color, double scale) {
  const center = _size / 2;
  final span = _size * scale;
  final top = center - span / 2;
  final bottom = center + span / 2;

  // Svislé rozvržení věže odshora dolů.
  final roofTop = top;
  final roofBottom = top + span * 0.20;
  final galleryTop = roofBottom;
  final galleryBottom = galleryTop + span * 0.11;
  final legsTop = galleryBottom;

  final roofHalf = span * 0.30;
  final galleryHalf = span * 0.34;
  final legTopHalf = span * 0.17;
  final legBottomHalf = span * 0.33;
  final legThickness = span * 0.085;

  Point p(double x, double y) => Point(x, y);

  // Střecha
  fillPolygon(img, color: color, vertices: [
    p(center, roofTop),
    p(center + roofHalf, roofBottom),
    p(center - roofHalf, roofBottom),
  ]);

  // Ochoz — nejširší prvek, dělá z věže rozhlednu a ne komín.
  fillPolygon(img, color: color, vertices: [
    p(center - galleryHalf, galleryTop),
    p(center + galleryHalf, galleryTop),
    p(center + galleryHalf, galleryBottom),
    p(center - galleryHalf, galleryBottom),
  ]);

  // Nohy: kuželové, nahoře užší než dole.
  for (final side in [-1, 1]) {
    final xTop = center + side * legTopHalf;
    final xBottom = center + side * legBottomHalf;
    fillPolygon(img, color: color, vertices: [
      p(xTop - legThickness / 2, legsTop),
      p(xTop + legThickness / 2, legsTop),
      p(xBottom + legThickness / 2, bottom),
      p(xBottom - legThickness / 2, bottom),
    ]);
  }

  // Dvě příčky. Víc jich být nemůže — v malém by se slily do plochy.
  for (final t in [0.34, 0.70]) {
    final y = legsTop + (bottom - legsTop) * t;
    final half = legTopHalf + (legBottomHalf - legTopHalf) * t;
    drawLine(
      img,
      x1: (center - half - legThickness / 2).round(),
      y1: y.round(),
      x2: (center + half + legThickness / 2).round(),
      y2: y.round(),
      color: color,
      thickness: legThickness * 0.62,
      antialias: true,
    );
  }
}
