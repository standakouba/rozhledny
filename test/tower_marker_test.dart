import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rozhledny/features/map/tower_marker.dart';

/// Jmenovka pod značkou mění její rozměry, a tím i dvě věci, které se snadno
/// rozbijí a špatně se všímají: kde přesně značka na mapě sedí a kam až sahá
/// citlivá plocha na klepnutí.
void main() {
  const point = LatLng(50.0, 14.5);

  late int taps;

  Future<Offset> pump(WidgetTester tester, {String? label}) async {
    taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 400,
            child: FlutterMap(
              options: const MapOptions(initialCenter: point, initialZoom: 14),
              children: [
                MarkerLayer(
                  markers: [
                    towerMarker(
                      point: point,
                      visitCount: 1,
                      compact: false,
                      selected: false,
                      rotate: false,
                      label: label,
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return tester.getCenter(find.byType(FlutterMap));
  }

  testWidgets('jméno se vypíše pod značku', (tester) async {
    await pump(tester, label: 'Boubín');
    expect(find.text('Boubín'), findsOneWidget);
  });

  testWidgets('bez jména zůstane jen značka', (tester) async {
    await pump(tester);
    expect(find.byType(TowerLabel), findsNothing);
  });

  testWidgets('ikona sedí na souřadnici i s jmenovkou pod sebou',
      (tester) async {
    // Kotva se počítá z rozměrů značky. Kdyby se spletla, puntík by u
    // pojmenovaných rozhleden ležel o půl jmenovky vedle skutečného místa.
    final center = await pump(tester, label: 'Boubín');
    final icon = tester.getCenter(find.byType(TowerMarker));
    expect((icon - center).distance, lessThan(1));
  });

  testWidgets('klepnutí na značku otevírá detail', (tester) async {
    await pump(tester, label: 'Boubín');
    await tester.tap(find.byType(TowerMarker));
    expect(taps, 1);
  });

  testWidgets('klepnutí na jmenovku detail neotevírá', (tester) async {
    // Jmenovka je třikrát širší než značka. Kdyby brala klepnutí, otevírala
    // by detail i tam, kam uživatel mířil na mapu pod ní.
    final center = await pump(tester, label: 'Boubín');
    await tester.tapAt(center + const Offset(0, markerSize / 2 + 8));
    // Klepnutí projde na mapu pod jmenovkou a ta si nastartuje časovač
    // dvojkliku — bez dopumpování by test spadl na nedoběhlém časovači.
    await tester.pump(const Duration(seconds: 1));
    expect(taps, 0);
  });

  test('bez jmenovky zůstává značka v původních rozměrech', () {
    final plain = towerMarker(
      point: point,
      visitCount: 0,
      compact: false,
      selected: false,
      rotate: false,
      onTap: () {},
    );
    expect(plain.width, markerSize);
    expect(plain.height, markerSize);
    expect(plain.alignment, Alignment.center);
  });
}
