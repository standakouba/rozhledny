/// Hledání rozhledny podle jména.
///
/// Diakritika se ignoruje. Psát na mobilní klávesnici háčky a čárky je
/// zdržení a při hledání je nikdo řešit nechce — „nadeje“ musí najít Naději
/// a „klet“ Kleť. Obráceně to platí taky: kdo diakritiku napíše, najde totéž.
library;

import '../../data/database.dart';

/// Písmena, která se při hledání srovnávají na základní tvar.
///
/// V datech je dnes jen česká diakritika (17 znaků), ale vlastní rozhlednu si
/// uživatel pojmenuje, jak chce, a v pohraničí se německé názvy nabízejí samy.
/// Tabulka proto bere i sousední jazyky; přebytečný řádek nic nestojí.
const _folded = <String, String>{
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
  'ç': 'c', 'č': 'c', 'ć': 'c',
  'ď': 'd', 'đ': 'd',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ě': 'e', 'ę': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ĺ': 'l', 'ľ': 'l', 'ł': 'l',
  'ň': 'n', 'ń': 'n', 'ñ': 'n',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o',
  'ř': 'r', 'ŕ': 'r',
  'š': 's', 'ś': 's', 'ş': 's',
  // Ostré s se rozpadá na dvě písmena, proto je tabulka String -> String
  // a ne mapa znaků: „Straße“ musí jít najít i jako „strasse“.
  'ß': 'ss',
  'ť': 't', 'ţ': 't',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
};

/// Text srovnaný na tvar, ve kterém se porovnává: malá písmena bez diakritiky.
String foldForSearch(String value) {
  final out = StringBuffer();
  // Velká písmena s diakritikou řeší `toLowerCase` (Č -> č), takže tabulka
  // stačí jen v malé variantě.
  for (final ch in value.toLowerCase().split('')) {
    out.write(_folded[ch] ?? ch);
  }
  return out.toString();
}

/// Sedí jméno na hledaný text?
bool nameMatchesQuery(String? name, String query) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return true;
  if (name == null) return false;
  return foldForSearch(name).contains(q);
}

/// Jak dobře jméno odpovídá dotazu; nižší je lepší, `null` znamená nesedí.
///
/// Kdo napíše „klet“, myslí Kleť — ne „Rozhlednu nad Kletí“, která by při
/// řazení podle abecedy vyšla dřív. Proto jde napřed shoda od začátku jména,
/// pak od začátku některého slova a teprve nakonec shoda kdekoli uvnitř.
int? _rank(String? name, String foldedQuery) {
  if (name == null) return null;
  final folded = foldForSearch(name);
  if (!folded.contains(foldedQuery)) return null;
  if (folded.startsWith(foldedQuery)) return 0;
  // Mezera i tečka a pomlčka dělí slova: „Rozhledna U Jakuba“ i „Boiika-věž“.
  for (final word in folded.split(RegExp(r'[\s./\-–—()]+'))) {
    if (word.startsWith(foldedQuery)) return 1;
  }
  return 2;
}

/// Rozhledny odpovídající dotazu, od nejlepší shody, nejvýš [limit] kusů.
///
/// Prázdný dotaz nevrací nic — nabízet pod polem sedm set rozhleden
/// v abecedním pořadí nikomu nepomůže.
List<TowerWithStats> searchTowers(
  List<TowerWithStats> towers,
  String query, {
  int limit = 8,
}) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return const [];

  final hits = <(int, TowerWithStats)>[];
  for (final t in towers) {
    final rank = _rank(t.tower.name, q);
    if (rank != null) hits.add((rank, t));
  }
  hits.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    if (byRank != 0) return byRank;
    return foldForSearch(a.$2.tower.name!).compareTo(
      foldForSearch(b.$2.tower.name!),
    );
  });
  return [for (final h in hits.take(limit)) h.$2];
}
