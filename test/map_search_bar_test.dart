import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/features/map/map_search_bar.dart';

/// Pole nad mapou je jediná cesta, jak se na konkrétní rozhlednu dostat bez
/// odbočky přes seznam. Testuje se chování, které by se rozbilo tiše: že se
/// nálezy ukážou, že klepnutí něco vrátí a že po výběru zase zmizí.
void main() {
  TowerWithStats t(String name, {String? region}) => TowerWithStats(
        tower: Tower(
          id: 1,
          uuid: name,
          lat: 50,
          lon: 14,
          source: TowerSource.osm,
          userModified: false,
          osmMissing: false,
          deleted: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          name: name,
          region: region,
        ),
        visitCount: 0,
        lastVisit: null,
      );

  Future<void> pumpBar(
    WidgetTester tester, {
    required List<TowerWithStats> towers,
    void Function(TowerWithStats)? onSelected,
  }) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            towers: towers,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ));

  testWidgets('dokud se nepíše, nálezy nejsou', (tester) async {
    await pumpBar(tester, towers: [t('Kleť')]);

    expect(find.text('Kleť'), findsNothing);
    expect(find.text('Hledat rozhlednu…'), findsOneWidget);
  });

  testWidgets('psaní bez diakritiky najde jméno s diakritikou', (tester) async {
    await pumpBar(tester, towers: [t('Kleť'), t('Boubín')]);

    await tester.enterText(find.byType(TextField), 'klet');
    await tester.pump();

    expect(find.text('Kleť'), findsOneWidget);
    expect(find.text('Boubín'), findsNothing);
  });

  testWidgets('u nálezu je vidět kraj', (tester) async {
    await pumpBar(tester, towers: [t('Kleť', region: 'Jihočeský kraj')]);

    await tester.enterText(find.byType(TextField), 'klet');
    await tester.pump();

    expect(find.text('Jihočeský kraj'), findsOneWidget);
  });

  testWidgets('klepnutí na nález ho ohlásí a seznam zavře', (tester) async {
    TowerWithStats? picked;
    await pumpBar(
      tester,
      towers: [t('Kleť')],
      onSelected: (t) => picked = t,
    );

    await tester.enterText(find.byType(TextField), 'klet');
    await tester.pump();
    await tester.tap(find.text('Kleť'));
    await tester.pump();

    expect(picked?.tower.name, 'Kleť');
    expect(find.text('Kleť'), findsNothing, reason: 'nálezy se po výběru zavřou');
  });

  testWidgets('nálezy zmizí, když pole ztratí zaměření', (tester) async {
    // Tak se zavírají po klepnutí do mapy — ta zaměření odebírá. Hledaný
    // text v poli přitom zůstává.
    await pumpBar(tester, towers: [t('Kleť')]);

    await tester.enterText(find.byType(TextField), 'klet');
    await tester.pump();
    expect(find.text('Kleť'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(find.text('Kleť'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'klet');
  });

  testWidgets('po návratu z detailu se hledání samo neotevře', (tester) async {
    // Scope si zaměřené pole pamatuje a po zavření cizí obrazovky mu ho vrací.
    // Kdo klepl do mapy, ať se klávesnice zbaví, ji pak dostal zpátky jen
    // proto, že si mezitím otevřel detail jiné rozhledny.
    await pumpBar(tester, towers: [t('Kleť')]);
    await tester.enterText(find.byType(TextField), 'klet');
    await tester.pump();

    dismissSearchFocus();
    await tester.pump();
    expect(find.text('Kleť'), findsNothing);

    // Detail rozhledny je modální panel, tedy vlastní route.
    final context = tester.element(find.byType(MapSearchBar));
    unawaited(showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('detail')),
    ));
    await tester.pumpAndSettle();
    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    expect(find.text('Kleť'), findsNothing, reason: 'nálezy se vrátit nesmí');
  });

  testWidgets('když nic nesedí, řekne se to', (tester) async {
    await pumpBar(tester, towers: [t('Kleť')]);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();

    expect(find.text('Nic takového tu není'), findsOneWidget);
  });

  testWidgets('křížek hledání zruší', (tester) async {
    await pumpBar(tester, towers: [t('Kleť')]);

    await tester.enterText(find.byType(TextField), 'klet');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('Kleť'), findsNothing);
    expect(find.text('Hledat rozhlednu…'), findsOneWidget);
  });
}
