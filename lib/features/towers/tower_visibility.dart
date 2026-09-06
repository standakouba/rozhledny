import '../../data/database.dart';

/// Které rozhledny se mají vůbec ukazovat.
///
/// V OSM nemá název skoro třetina rozhleden a na mapě z nich jsou bezejmenné
/// puntíky, které se nedají odlišit jeden od druhého. Kdo je vypne, uvidí jen
/// místa, která se dají pojmenovat.
///
/// **Vlastní práce se neschovává nikdy** — ani navštívená rozhledna, ani bod,
/// který si uživatel sám založil. To jediné si do aplikace nasbíral sám a kvůli
/// nastavení zobrazení zmizet nesmí. Vlastní bod přitom nemusí mít jméno hned:
/// zapíchne se špendlíkem cestou a pojmenuje doma, a mezitím by se ztratil.
///
/// Sídlí to tady, a ne v mapě nebo ve statistikách, protože obě obrazovky musí
/// počítat s toutéž množinou. Jinak by se stalo, že bod na mapě není, ale do
/// „X ze všech“ se počítá.
List<TowerWithStats> shownTowers(
  List<TowerWithStats> all, {
  required bool showUnnamed,
}) {
  if (showUnnamed) return all;
  return [
    for (final t in all)
      if (hasName(t) || t.isVisited || t.tower.source == TowerSource.user) t,
  ];
}

bool hasName(TowerWithStats t) => t.tower.name?.trim().isNotEmpty ?? false;
