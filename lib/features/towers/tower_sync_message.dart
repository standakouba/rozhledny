import '../../data/seed.dart';
import '../stats/czech_plurals.dart';

/// Věta, kterou aplikace řekne po tiché aktualizaci základních dat.
///
/// Aktualizace běží sama při startu a mění počet rozhleden pod rukama —
/// bez zprávy by to vypadalo, že se čísla mění sama od sebe. Vypisují se jen
/// přírůstky a úbytky: opravený název u rozhledny, která v datech byla už
/// dřív, není nic, co by uživatel potřeboval vědět.
String towerSyncMessage(AssetSyncReport report) {
  final parts = <String>[
    if (report.added > 0)
      '${_verb(report.added, 'přibyla', 'přibyly', 'přibylo')} '
          '${report.added} ${towerWord(report.added)}',
    if (report.removed > 0)
      '${_verb(report.removed, 'zmizela', 'zmizely', 'zmizelo')} '
          '${report.removed} ${towerWord(report.removed)}',
  ];

  // Zbývá případ, kdy se změnily jen údaje u rozhleden, které v datech byly
  // už dřív — počet se nezměnil, ale třeba název nebo popis ano.
  if (parts.isEmpty) return 'Data rozhleden se aktualizovala.';
  return 'Aktualizace dat: ${parts.join(', ')}.';
}

/// Sloveso v minulém čase se po číslovce chová stejně jako podstatné jméno:
/// „přibyla 1“, „přibyly 3“, „přibylo 5“.
String _verb(int n, String one, String few, String many) {
  if (n == 1) return one;
  if (n >= 2 && n <= 4) return few;
  return many;
}
