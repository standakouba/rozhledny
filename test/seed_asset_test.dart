import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/data/seed.dart';

/// Testy proti skutečnému vygenerovanému assetu, ne proti vzorku.
///
/// Chrání dvě věci najednou: že se formát z tools/fetch_osm.dart nerozešel se
/// seedem v aplikaci, a že v datech nezůstala hrubá chyba (rozhledna mimo ČR,
/// duplicitní OSM id, prázdný soubor).
void main() {
  final file = File('assets/data/rozhledny.json');

  test('asset existuje a je neprázdný', () {
    expect(file.existsSync(), isTrue,
        reason: 'chybí assets/data/rozhledny.json — pusť dart tools/fetch_osm.dart');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(data['towers'], isA<List>());
    expect((data['towers'] as List).length, greaterThan(500),
        reason: 'v ČR je kolem 670 rozhleden; výrazně méně znamená ořezaná data');
  });

  test('seed nakrmí databázi celým assetem', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final count = await seedFromAsset(db, json: file.readAsStringSync());
    final all = await db.watchTowersWithStats().first;

    expect(all, hasLength(count));
    expect(all.every((t) => t.visitCount == 0), isTrue,
        reason: 'čerstvě naseedovaná databáze nemá žádné návštěvy');
  });

  group('kvalita dat', () {
    late List<Map<String, dynamic>> towers;

    setUpAll(() {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      towers = (data['towers'] as List).cast<Map<String, dynamic>>();
    });

    test('všechny souřadnice leží v ČR', () {
      for (final t in towers) {
        final lat = t['lat'] as num, lon = t['lon'] as num;
        expect(lat, inInclusiveRange(48.5, 51.1), reason: '${t['name']}');
        expect(lon, inInclusiveRange(12.0, 18.9), reason: '${t['name']}');
      }
    });

    test('OSM identifikátory jsou jedinečné', () {
      final keys = towers.map((t) => '${t['osmType']}/${t['osmId']}').toList();
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('kraj chybí nanejvýš u hrstky bodů na hranici', () {
      final missing = towers.where((t) => t['region'] == null).length;
      expect(missing, lessThan(5),
          reason: 'hodně bodů bez kraje = rozbité přiřazení přes QLever');
    });

    test('většina rozhleden má název', () {
      final named = towers.where((t) => t['name'] != null).length;
      expect(named / towers.length, greaterThan(0.6));
    });
  });

  group('obohacení z Wikipedie a Commons', () {
    late List<Map<String, dynamic>> towers;

    setUpAll(() {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      towers = (data['towers'] as List).cast<Map<String, dynamic>>();
    });

    test('žádná fotka bez autora a licence', () {
      // Snímky na Commons mají AttributionRequired. Publikovat je bez uvedení
      // autora a licence by bylo porušení licence, ne kosmetický nedostatek —
      // proto to hlídá test, ne jen dobrý úmysl v generátoru.
      final withPhoto = towers.where((t) => t['photoUrl'] != null).toList();
      expect(withPhoto, isNotEmpty);
      for (final t in withPhoto) {
        expect(t['photoAuthor'], isNotNull, reason: '${t['name']}');
        expect(t['photoLicense'], isNotNull, reason: '${t['name']}');
        expect(t['photoPageUrl'], isNotNull, reason: '${t['name']}');
      }
    });

    test('popis vždy doprovází odkaz na článek', () {
      for (final t in towers.where((t) => t['wikipediaExtract'] != null)) {
        expect(t['wikipediaUrl'], isNotNull, reason: '${t['name']}');
      }
    });

    test('fotky vedou na Wikimedia, ne někam jinam', () {
      for (final t in towers.where((t) => t['photoUrl'] != null)) {
        expect(t['photoUrl'], startsWith('https://commons.wikimedia.org/'));
        // utm_* parametry z API jen kazí klíč do cache.
        expect(t['photoUrl'], isNot(contains('utm_')));
      }
    });

    test('obohacení pokrývá rozumnou část rozhleden', () {
      final withPhoto = towers.where((t) => t['photoUrl'] != null).length;
      final withText =
          towers.where((t) => t['wikipediaExtract'] != null).length;
      expect(withPhoto, greaterThan(250),
          reason: 'ověřeno 325; výrazný propad znamená rozbité párování');
      expect(withText, greaterThan(200), reason: 'ověřeno 257');
    });

    test('výtahy se vejdou do karty', () {
      for (final t in towers.where((t) => t['wikipediaExtract'] != null)) {
        expect((t['wikipediaExtract'] as String).length, lessThanOrEqualTo(701));
      }
    });
  });
}
