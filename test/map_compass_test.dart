import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/features/map/map_compass.dart';

/// Kompas je přepínač o dvou stavech. Podstatné je, že zamčení a srovnání
/// na sever je **jedna** akce — jinak by nad pootočenou mapou bylo potřeba
/// klepnout dvakrát a mezitím by mapa zůstala odemčená.
void main() {
  late List<String> actions;

  Future<void> pump(
    WidgetTester tester, {
    required double rotation,
    required bool locked,
  }) async {
    actions = [];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MapCompass(
          rotation: rotation,
          locked: locked,
          onUnlock: () => actions.add('unlock'),
          onLockToNorth: () => actions.add('lockToNorth'),
        ),
      ),
    ));
  }

  Future<void> tap(WidgetTester tester) async {
    await tester.tap(find.byType(MapCompass));
    await tester.pump();
  }

  testWidgets('zamčený kompas odemyká', (tester) async {
    await pump(tester, rotation: 0, locked: true);
    await tap(tester);
    expect(actions, ['unlock']);
  });

  testWidgets('zamčený zůstane zamčený i když je mapa pootočená',
      (tester) async {
    // Může nastat po vypnutí rotace nad pootočenou mapou.
    await pump(tester, rotation: 45, locked: true);
    await tap(tester);
    expect(actions, ['unlock'],
        reason: 'v zamčeném stavu má tlačítko jedinou roli — odemknout');
  });

  testWidgets('odemčený a pootočený se srovná i zamkne najednou',
      (tester) async {
    await pump(tester, rotation: 137, locked: false);
    await tap(tester);
    expect(actions, ['lockToNorth'],
        reason: 'jedno klepnutí, ne dvě');
  });

  testWidgets('odemčený na severu zamkne', (tester) async {
    await pump(tester, rotation: 0, locked: false);
    await tap(tester);
    expect(actions, ['lockToNorth']);
  });

  testWidgets('dvě klepnutí vrátí mapu do výchozího stavu', (tester) async {
    // Kompas je bezstavový, `locked` mu dodává mapa. Test tedy musí ten stav
    // držet za ni, jinak by druhé klepnutí dopadlo na tentýž stav jako první.
    final log = <String>[];
    var locked = true;
    var rotation = 0.0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => MapCompass(
            rotation: rotation,
            locked: locked,
            onUnlock: () => setState(() {
              log.add('unlock');
              locked = false;
              rotation = 137; // uživatel mapu pootočí
            }),
            onLockToNorth: () => setState(() {
              log.add('lockToNorth');
              locked = true;
              rotation = 0;
            }),
          ),
        ),
      ),
    ));

    await tap(tester);
    await tap(tester);

    expect(log, ['unlock', 'lockToNorth']);
    expect(locked, isTrue);
    expect(rotation, 0, reason: 'mapa musí skončit srovnaná na sever');
  });

  testWidgets('střelka se otáčí souhlasně s mapou, ne proti ní', (tester) async {
    // Znaménko je tu snadné splést: flutter_map otáčí obsah mapy o
    // +rotationRad, takže sever se na obrazovce posune stejným směrem a
    // střelka musí za ním. Markery se naopak otáčejí o -rotationRad, ale
    // z opačného důvodu — aby zůstaly svisle.
    await pump(tester, rotation: 90, locked: false);

    final transform = tester.widget<Transform>(
      find.ancestor(
        of: find.byType(CustomPaint).last,
        matching: find.byType(Transform),
      ).first,
    );
    // Rotace o 90° kolem osy Z: matice [0 -1; 1 0], tedy m[0] = cos = 0
    // a m[1] = sin = +1. Opačné znaménko by dalo -1.
    expect(transform.transform.storage[1], closeTo(1, 0.001),
        reason: 'sin(+90°) = +1; kdyby střelka šla proti mapě, vyjde -1');
  });

  testWidgets('zámek je vidět jako ikona', (tester) async {
    await pump(tester, rotation: 0, locked: true);
    expect(find.byIcon(Icons.lock), findsOneWidget);

    await pump(tester, rotation: 0, locked: false);
    expect(find.byIcon(Icons.lock), findsNothing);
  });
}
