import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/database.dart';
import 'package:rozhledny/features/towers/tower_search.dart';

/// Hledání je jediná cesta, jak se v sedmi stovkách rozhleden dobrat jedné
/// konkrétní. Testuje se hlavně to, že diakritika nerozhoduje — na to člověk
/// narazí hned první den a spraví to jen kód, ne návod.
void main() {
  TowerWithStats t(String? name) => TowerWithStats(
        tower: Tower(
          id: 1,
          uuid: name ?? 'bez-jmena',
          lat: 50,
          lon: 14,
          source: TowerSource.osm,
          userModified: false,
          osmMissing: false,
          deleted: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          name: name,
        ),
        visitCount: 0,
        lastVisit: null,
      );

  group('srovnání textu', () {
    test('diakritika mizí', () {
      expect(foldForSearch('Kleť'), 'klet');
      expect(foldForSearch('Naděje'), 'nadeje');
      expect(foldForSearch('Žižkův vrch'), 'zizkuv vrch');
    });

    test('ostré s se rozpadne na dvě písmena', () {
      expect(foldForSearch('Straße'), 'strasse');
    });

    test('co diakritiku nemá, projde beze změny', () {
      expect(foldForSearch('Boiika'), 'boiika');
    });
  });

  group('shoda jména', () {
    test('bez diakritiky se najde jméno s diakritikou', () {
      expect(nameMatchesQuery('Kleť', 'klet'), isTrue);
      expect(nameMatchesQuery('Rozhledna Naděje', 'nadeje'), isTrue);
    });

    test('a s diakritikou taky', () {
      expect(nameMatchesQuery('Kleť', 'Kleť'), isTrue);
    });

    test('co nesedí, nesedí', () {
      expect(nameMatchesQuery('Kleť', 'boubin'), isFalse);
    });

    test('rozhledna bez jména nesedí na nic', () {
      expect(nameMatchesQuery(null, 'klet'), isFalse);
    });

    test('prázdný dotaz projde všem', () {
      expect(nameMatchesQuery('Kleť', '  '), isTrue);
    });
  });

  group('pořadí nálezů', () {
    test('shoda od začátku jména jde první', () {
      // Podle abecedy by vyhrála „Rozhledna nad Kletí“, jenže kdo píše
      // „klet“, myslí Kleť.
      final found = searchTowers(
        [t('Rozhledna nad Kletí'), t('Kleť'), t('U Kleti')],
        'klet',
      );
      expect(found.first.tower.name, 'Kleť');
    });

    test('pak shoda od začátku slova a nakonec uvnitř', () {
      final found = searchTowers(
        [t('Nad Chlumem'), t('Chlum u Třeboně'), t('Vrchlabí')],
        'chlum',
      );
      expect(
        found.map((f) => f.tower.name),
        ['Chlum u Třeboně', 'Nad Chlumem'],
        reason: 'Vrchlabí neobsahuje „chlum“',
      );
    });

    test('prázdný dotaz nenabízí nic', () {
      expect(searchTowers([t('Kleť')], ''), isEmpty);
    });

    test('víc než limit se neposílá', () {
      final many = [for (var i = 0; i < 30; i++) t('Rozhledna $i')];
      expect(searchTowers(many, 'rozhledna', limit: 5), hasLength(5));
    });

    test('rozhledny bez jména se do nálezů nepletou', () {
      expect(searchTowers([t(null), t('Kleť')], 'klet'), hasLength(1));
    });
  });
}
