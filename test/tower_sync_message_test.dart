import 'package:flutter_test/flutter_test.dart';
import 'package:rozhledny/data/seed.dart';
import 'package:rozhledny/features/towers/tower_sync_message.dart';

/// Hláška se skládá z číslovek, a čeština po nich skloňuje i slovesa.
/// „Zmizely 5 rozhledny“ by z aktualizace udělalo cizí text.
void main() {
  test('jedna přibylá rozhledna', () {
    expect(
      towerSyncMessage(const AssetSyncReport(added: 1)),
      'Aktualizace dat: přibyla 1 rozhledna.',
    );
  });

  test('dvě až čtyři mají vlastní tvar', () {
    expect(
      towerSyncMessage(const AssetSyncReport(added: 3)),
      'Aktualizace dat: přibyly 3 rozhledny.',
    );
  });

  test('pět a víc', () {
    expect(
      towerSyncMessage(const AssetSyncReport(added: 27)),
      'Aktualizace dat: přibylo 27 rozhleden.',
    );
  });

  test('úbytek se pojmenuje jako úbytek', () {
    expect(
      towerSyncMessage(const AssetSyncReport(removed: 3)),
      'Aktualizace dat: zmizely 3 rozhledny.',
    );
  });

  test('přírůstek i úbytek najednou', () {
    expect(
      towerSyncMessage(const AssetSyncReport(added: 5, removed: 1)),
      'Aktualizace dat: přibylo 5 rozhleden, zmizela 1 rozhledna.',
    );
  });

  test('když se počet nezměnil, mluví se jen o datech', () {
    // Opravený název u rozhledny, která v datech byla už dřív. Vypisovat
    // „aktualizováno 699“ by znamenalo číslo, které nikomu nic neřekne.
    expect(
      towerSyncMessage(const AssetSyncReport(updated: 699)),
      'Data rozhleden se aktualizovala.',
    );
  });
}
