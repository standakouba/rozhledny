import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/seed.dart';
import '../../services/contributions.dart';
import '../../services/settings.dart';
import '../visits/visit_editor.dart' show dateFormat;

/// Odeslání návrhu do základních dat.
///
/// Sedí v Nastavení schválně, a ne u přidávání rozhledny: v terénu, kde se
/// bod zapichuje, stejně nemusí být signál, a vyskakovací nabídka v tu chvíli
/// jen překáží. Tady se návrhy sejdou a odejdou jednou dávkou.
class ContributionTiles extends ConsumerStatefulWidget {
  const ContributionTiles({super.key});

  @override
  ConsumerState<ContributionTiles> createState() => _ContributionTilesState();
}

class _ContributionTilesState extends ConsumerState<ContributionTiles> {
  bool _busy = false;

  Future<void> _open() async {
    setState(() => _busy = true);
    try {
      final prefs = await ref.read(sharedPrefsProvider.future);
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;

      // Náhled vrací zprávu, kterou uživatel opravdu viděl. Sestavit ji až tady
      // by znamenalo poslat i to, co si v náhledu mezitím vyřadil.
      final message = await showModalBottomSheet<ContributionMessage>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _PreviewSheet(
          appVersion: '${info.version}+${info.buildNumber}',
          dataset: syncedAssetStamp(prefs),
        ),
      );
      if (message == null || !mounted) return;

      final outcome = await sendContributions(message);
      // Jestli uživatel mail v poštovním klientu opravdu odeslal, se odsud
      // zjistit nedá — aplikace ho jen předala dál. Bere se to jako odeslané
      // a od toho je řádek „poslat i to, co už odešlo“: raději občas poslat
      // něco dvakrát než tichounce přijít o návrh, o kterém nikdo neví.
      await markContributionsSent(prefs, DateTime.now());
      ref.invalidate(contributionsProvider);
      if (!mounted) return;
      _tell(outcome == ContributionOutcome.mail
          ? 'Návrh je připravený v e-mailu — zbývá ho odeslat.'
          : 'Návrh je v příloze. Pošlete ji prosím na $contributionsEmail.');
    } catch (e) {
      _tell('Nepovedlo se to: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await forgetContributionsSent(prefs);
    ref.invalidate(contributionsProvider);
    _tell('Do návrhu se vrátilo všechno, co v telefonu je.');
  }

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = ref.watch(contributionsProvider).valueOrNull;
    final sentAt = set?.since;
    final ready = set != null && !set.isEmpty;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.forward_to_inbox_outlined),
          title: const Text('Poslat návrh do dat'),
          subtitle: Text(
            set == null
                ? '…'
                : set.isEmpty
                    ? 'Zatím není co posílat. Sejde se sem rozhledna, kterou '
                        'v datech nenajdete a přidáte si ji, oprava názvu '
                        'nebo polohy a nahlášená chyba.'
                    : '${set.summary}. Otevře se e-mail — odesíláte ho vy.',
          ),
          trailing: ready ? Text('${set.length}') : null,
          enabled: !_busy && ready,
          onTap: ready ? _open : null,
        ),
        if (sentAt != null)
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Poslat i to, co už odešlo'),
            subtitle: Text('Naposledy odesláno ${dateFormat.format(sentAt)}.'),
            enabled: !_busy,
            onTap: _resend,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Návštěvy, hodnocení ani poznámky u rozhleden se neodesílají '
            'nikdy. Před odesláním uvidíte přesně, co v e-mailu bude, '
            'a jednotlivé položky z něj můžete vyřadit.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}

/// Náhled před odesláním. Ukazuje totéž, co půjde v mailu — nahoře čitelně,
/// dole doslova — a dovolí jednotlivé položky vyřadit.
///
/// Vyřazení se ukládá hned, ne až při odeslání: „tohle posílat nechci“ má
/// platit i pro člověka, který náhled zavře křížkem. Vrátit to jde ze
/// snackbaru a u rozhledny pak i z nabídky v jejím detailu.
class _PreviewSheet extends ConsumerStatefulWidget {
  const _PreviewSheet({required this.appVersion, required this.dataset});

  final String appVersion;
  final String? dataset;

  @override
  ConsumerState<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends ConsumerState<_PreviewSheet> {
  /// Rozhledna se nemaže — jen přestane být nabízená. Bod v mapě i s návštěvami
  /// zůstává, protože „nechci to posílat“ neznamená „nechci to mít“.
  Future<void> _dropTower(TowerContribution c) async {
    final db = ref.read(databaseProvider);
    await db.setTowerKeepPrivate(c.tower.uuid, true);
    _undo(
      c.kind == ContributionKind.edited
          ? 'Oprava zůstane jen vám.'
          : 'Rozhledna zůstane jen vám.',
      () => db.setTowerKeepPrivate(c.tower.uuid, false),
    );
  }

  /// Nahlášení se naopak maže doopravdy — jinou funkci než dojít k autorovi
  /// nemá, takže po „nechci to posílat“ nemá co zbýt.
  Future<void> _dropReport(ReportContribution c) async {
    final db = ref.read(databaseProvider);
    final r = c.report;
    await db.deleteReport(r.towerUuid);
    _undo(
      'Nahlášení zrušeno.',
      () => db.upsertReport(TowerReportsCompanion.insert(
        uuid: r.uuid,
        towerUuid: r.towerUuid,
        reason: r.reason,
        note: Value(r.note),
        createdAt: r.createdAt,
      )),
    );
  }

  void _undo(String message, Future<void> Function() restore) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: SnackBarAction(label: 'Vrátit', onPressed: () => restore()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = ref.watch(contributionsProvider).valueOrNull;
    final message = set == null
        ? null
        : buildContributionMessage(
            set,
            appVersion: widget.appVersion,
            dataset: widget.dataset,
          );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          Text('Co se odešle', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Na adresu $contributionsEmail. Co posílat nechcete, vyřaďte '
            'křížkem; do e-mailu si pak můžete ještě cokoli dopsat.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
          if (set == null)
            const Center(child: CircularProgressIndicator())
          else if (set.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nezbylo nic k odeslání.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else ...[
            for (final kind in ContributionKind.values)
              _Group(
                title: switch (kind) {
                  ContributionKind.added => 'Chybějící rozhledny',
                  ContributionKind.edited => 'Opravené body',
                  ContributionKind.deleted => 'Smazané vlastní body',
                },
                items: [
                  for (final c in set.of(kind))
                    _Row(
                      title: c.tower.name ?? 'Rozhledna bez názvu',
                      subtitle: '${c.tower.lat.toStringAsFixed(5)}, '
                          '${c.tower.lon.toStringAsFixed(5)}',
                      onDrop: () => _dropTower(c),
                    ),
                ],
              ),
            _Group(
              title: 'Nahlášené chyby',
              items: [
                for (final c in set.reports)
                  _Row(
                    title: c.tower?.name ?? 'Rozhledna bez názvu',
                    subtitle: reasonLabel(c.report.reason) +
                        (c.report.note == null ? '' : ' — ${c.report.note}'),
                    onDrop: () => _dropReport(c),
                  ),
              ],
            ),
            Theme(
              // ExpansionTile si jinak nakreslí vlastní dělicí linky, které
              // v seznamu bez dělítek vypadají jako omyl.
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Data k importu'),
                subtitle: const Text('Přesné znění, které se přiloží'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      message!.json,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zrušit'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: set == null || set.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(message),
                icon: const Icon(Icons.send),
                label: const Text('Otevřít e-mail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        ...items,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.onDrop,
  });

  final String title;
  final String subtitle;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      // Viditelný křížek, ne přejetí doleva jako u návštěv: do náhledu se jde
      // jednou před odesláním a schované gesto by tam bylo hádankou.
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Neposílat',
        onPressed: onDrop,
      ),
    );
  }
}
