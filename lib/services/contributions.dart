import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/database.dart';

/// Návrh do základních dat: co uživatel do mapy přidal, opravil nebo nahlásil.
///
/// Aplikace nemá server, takže se nic neposílá samo. Tohle jen posbírá, co už
/// v databázi je, ukáže mu to a otevře e-mail. Odesílá **on**, a to až když na
/// to sáhne v Nastavení — stisk tlačítka je jediná cesta, jak se odsud cokoli
/// dostane ven.
///
/// Návštěvy, hodnocení ani poznámka u rozhledny se neposílají nikdy. Poznámka
/// je uživatelův text („byli jsme tam s Bárou“), do dat o rozhlednách nepatří
/// a v cizí schránce nemá co dělat. Jediný text, který jde ven, je ten, který
/// napsal vysloveně jako zprávu: poznámka u nahlášení a co si dopíše do mailu.

/// Formát přílohy. Zvýší se, až se obsah změní tak, že by ho starší import
/// přečetl špatně.
const contributionsFormatVersion = 1;

/// Kam návrhy chodí. Tatáž adresa jako kontakt v Google Play.
const contributionsEmail = 'rozhledny.app@gmail.com';

/// Klíč, pod kterým si aplikace pamatuje, co už uživatel odeslal.
const _keySentAt = 'contributions_sent_at';

/// Nad tuhle délku se tělo mailu do `mailto:` už necpe.
///
/// Android předává odkaz poštovnímu klientu jako intent a dlouhý řetězec
/// někteří klienti tiše uříznou — návrh by dorazil rozpůlený a nepoznala by
/// to ani jedna strana. Delší dávka jde proto přílohou přes sdílení.
const _mailtoBodyLimit = 3500;

/// Čas posledního odeslání, nebo `null`, když se ještě nic neposlalo.
DateTime? lastContributionsSentAt(SharedPreferences prefs) {
  final raw = prefs.getString(_keySentAt);
  return raw == null ? null : DateTime.tryParse(raw);
}

Future<void> markContributionsSent(SharedPreferences prefs, DateTime when) =>
    prefs.setString(_keySentAt, when.toIso8601String());

Future<void> forgetContributionsSent(SharedPreferences prefs) =>
    prefs.remove(_keySentAt);

// ------------------------------------------------------------------- model

enum ContributionKind {
  /// Rozhledna, kterou uživatel v datech nenašel a založil si ji sám.
  added,

  /// Bod z OSM, kterému opravil název nebo polohu.
  edited,

  /// Vlastní bod, který zase smazal.
  deleted,
}

class TowerContribution {
  const TowerContribution(this.kind, this.tower);

  final ContributionKind kind;
  final Tower tower;
}

/// Nahlášení i s rozhlednou, ke které patří — v mailu má být vidět jméno
/// a poloha, ne jen UUID.
class ReportContribution {
  const ReportContribution(this.report, this.tower);

  final TowerReport report;
  final Tower? tower;
}

class ContributionSet {
  const ContributionSet({
    this.towers = const [],
    this.reports = const [],
    this.since,
  });

  final List<TowerContribution> towers;
  final List<ReportContribution> reports;

  /// Od kdy se sbíralo. `null` = od začátku, ještě se nic neposílalo.
  final DateTime? since;

  List<TowerContribution> of(ContributionKind kind) => [
        for (final t in towers)
          if (t.kind == kind) t,
      ];

  int count(ContributionKind kind) => of(kind).length;

  int get length => towers.length + reports.length;

  bool get isEmpty => length == 0;

  /// Krátký přehled do řádku v Nastavení.
  String get summary {
    if (isEmpty) return 'Zatím není co posílat';
    return [
      if (count(ContributionKind.added) > 0)
        '${count(ContributionKind.added)} přidaných',
      if (count(ContributionKind.edited) > 0)
        '${count(ContributionKind.edited)} opravených',
      if (count(ContributionKind.deleted) > 0)
        '${count(ContributionKind.deleted)} smazaných',
      if (reports.isNotEmpty) '${reports.length} nahlášených',
    ].join(' · ');
  }
}

// ------------------------------------------------------------------- sběr

/// Posbírá, co uživatel od [since] do dat přispěl.
///
/// Se `since == null` se posílá všechno, co v telefonu je — to je stav před
/// prvním odesláním a po „poslat všechno znovu“.
Future<ContributionSet> collectContributions(
  AppDatabase db, {
  DateTime? since,
}) async {
  bool isNew(DateTime at) => since == null || at.isAfter(since);

  final towers = <TowerContribution>[];
  for (final t in await db.contributedTowers()) {
    // Bod, který si uživatel nechal pro sebe. V mapě zůstává, jen se
    // o něm nikam nepíše — proto se vyřazuje tady, a ne mazáním.
    if (t.keepPrivate == true) continue;
    if (!isNew(t.updatedAt)) continue;

    if (t.deleted) {
      // Bod, který uživatel založil a zase smazal, aniž by mezitím cokoli
      // odeslal, byl jeho překlep — o tom vědět nepotřebujeme. Smazání se
      // posílá jen u bodu, který mohl v některé dřívější dávce dorazit, aby
      // se nad ním pak nerozhodovalo o něčem, co už neplatí.
      if (since != null && t.createdAt.isBefore(since)) {
        towers.add(TowerContribution(ContributionKind.deleted, t));
      }
      continue;
    }

    towers.add(TowerContribution(
      t.source == TowerSource.user
          ? ContributionKind.added
          : ContributionKind.edited,
      t,
    ));
  }

  final reports = <ReportContribution>[];
  for (final r in await db.allReports()) {
    if (!isNew(r.createdAt)) continue;
    reports.add(ReportContribution(r, await db.towerByUuid(r.towerUuid)));
  }

  return ContributionSet(towers: towers, reports: reports, since: since);
}

// ------------------------------------------------------------ serializace

/// Souřadnice na šest desetinných míst. Přesnost na decimetr je víc, než
/// zvládne telefon i ruka v mapě; delší číslo je jen šum navíc.
double _coord(double v) => double.parse(v.toStringAsFixed(6));

String? _osmKey(Tower? t) => (t?.osmType != null && t?.osmId != null)
    ? '${t!.osmType}/${t.osmId}'
    : null;

Map<String, dynamic> _towerJson(TowerContribution c) {
  final t = c.tower;
  return {
    'kind': c.kind.name,
    'uuid': t.uuid,
    if (_osmKey(t) != null) 'osm': _osmKey(t),
    if (t.name != null) 'name': t.name,
    'lat': _coord(t.lat),
    'lon': _coord(t.lon),
    if (t.height != null) 'height': t.height,
    'createdAt': t.createdAt.toIso8601String(),
    'updatedAt': t.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> _reportJson(ReportContribution c) {
  final t = c.tower;
  return {
    'uuid': c.report.uuid,
    'tower': c.report.towerUuid,
    if (_osmKey(t) != null) 'osm': _osmKey(t),
    if (t?.name != null) 'name': t!.name,
    if (t != null) 'lat': _coord(t.lat),
    if (t != null) 'lon': _coord(t.lon),
    'reason': c.report.reason.name,
    // Poznámka u nahlášení jde ven schválně — je to jediné pole, do kterého
    // uživatel píše vysloveně nám.
    if (c.report.note != null) 'note': c.report.note,
    'createdAt': c.report.createdAt.toIso8601String(),
  };
}

/// Data k importu. Nese i otisk assetu, proti kterému návrh vznikl — bez něj
/// by u telefonu s neaktualizovanou aplikací nešlo poznat, jestli „chybějící
/// rozhledna“ v datech mezitím dávno není.
Map<String, dynamic> encodeContributions(
  ContributionSet set, {
  String? appVersion,
  String? dataset,
  DateTime? now,
}) =>
    {
      'formatVersion': contributionsFormatVersion,
      'createdAt': (now ?? DateTime.now()).toIso8601String(),
      'app': ?appVersion,
      'dataset': ?dataset,
      'towers': [for (final t in set.towers) _towerJson(t)],
      'reports': [for (final r in set.reports) _reportJson(r)],
    };

// -------------------------------------------------------------- text mailu

const _reasonLabels = <TowerReportReason, String>{
  TowerReportReason.gone: 'rozhledna už neexistuje',
  TowerReportReason.notATower: 'není to rozhledna',
  TowerReportReason.duplicate: 'je v mapě dvakrát',
  TowerReportReason.other: 'něco jiného',
};

String reasonLabel(TowerReportReason reason) => _reasonLabels[reason]!;

String _towerLine(Tower t) {
  final name = t.name?.trim();
  final osm = _osmKey(t);
  return ' · ${name == null || name.isEmpty ? 'bez názvu' : name} — '
      '${_coord(t.lat)}, ${_coord(t.lon)}${osm == null ? '' : ' ($osm)'}';
}

/// Hotový mail: co je v předmětu, co v těle a co v příloze, kdyby se tělo
/// do odkazu nevešlo.
class ContributionMessage {
  const ContributionMessage({
    required this.subject,
    required this.body,
    required this.json,
  });

  final String subject;
  final String body;
  final String json;
}

/// Sestaví mail. Nahoře čitelný výpis pro člověka, dole blok k importu —
/// ať uživatel vidí, co odesílá, a nemusí tomu věřit.
ContributionMessage buildContributionMessage(
  ContributionSet set, {
  String? appVersion,
  String? dataset,
  DateTime? now,
}) {
  final json = const JsonEncoder.withIndent('  ').convert(
    encodeContributions(
      set,
      appVersion: appVersion,
      dataset: dataset,
      now: now,
    ),
  );

  final b = StringBuffer()
    ..writeln('Návrh do dat aplikace Rozhledny.')
    ..writeln();

  void section(String title, List<String> lines) {
    if (lines.isEmpty) return;
    b.writeln('$title (${lines.length}):');
    lines.forEach(b.writeln);
    b.writeln();
  }

  section('Chybějící rozhledny', [
    for (final c in set.of(ContributionKind.added)) _towerLine(c.tower),
  ]);
  section('Opravené body', [
    for (final c in set.of(ContributionKind.edited)) _towerLine(c.tower),
  ]);
  section('Smazané vlastní body', [
    for (final c in set.of(ContributionKind.deleted)) _towerLine(c.tower),
  ]);
  section('Nahlášené chyby', [
    for (final c in set.reports)
      '${c.tower == null ? ' · neznámý bod' : _towerLine(c.tower!)}\n'
          '   ${reasonLabel(c.report.reason)}'
          '${c.report.note == null ? '' : ': ${c.report.note}'}',
  ]);

  b
    ..writeln('Sem můžete připsat cokoli dalšího — čím víc toho o rozhledně '
        'víme, tím líp se rozhoduje, jestli do dat patří.')
    ..writeln()
    ..writeln('--- data k importu, tenhle blok neupravujte ---')
    ..writeln(json);

  return ContributionMessage(
    subject: 'Rozhledny: návrh do dat (${set.length})',
    body: b.toString(),
    json: json,
  );
}

// --------------------------------------------------------------- odeslání

/// Jak návrh odešel.
enum ContributionOutcome {
  /// Otevřel se poštovní klient s předvyplněnou adresou.
  mail,

  /// Nabídka sdílení s přílohou — adresu si uživatel doplní sám.
  shared,
}

/// Předá návrh ven z aplikace.
///
/// Přednost má `mailto:`, protože jen tam se předvyplní správná adresa — ze
/// sdílení se dá poslat kamkoli a návrh by skončil kdovíkde. Na sdílení
/// s přílohou se spadne, teprve když se tělo do odkazu nevejde nebo v telefonu
/// žádný poštovní klient není.
Future<ContributionOutcome> sendContributions(ContributionMessage m) async {
  if (m.body.length <= _mailtoBodyLimit) {
    final uri = Uri.parse('mailto:$contributionsEmail'
        '?subject=${Uri.encodeComponent(m.subject)}'
        '&body=${Uri.encodeComponent(m.body)}');
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return ContributionOutcome.mail;
    }
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/rozhledny-navrh.json');
  await file.writeAsString(m.json);

  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'application/json')],
    subject: m.subject,
    text: 'Návrh do dat aplikace Rozhledny — pošlete prosím '
        'na $contributionsEmail',
  ));
  return ContributionOutcome.shared;
}
