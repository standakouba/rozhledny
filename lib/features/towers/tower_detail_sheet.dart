import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/photos.dart';
import '../visits/visit_editor.dart';
import 'tower_info_card.dart';
import 'tower_editor_sheet.dart';

/// Detail rozhledny se seznamem všech návštěv.
///
/// Otevírá se z mapy i ze seznamu jako spodní panel s vlastním rolováním —
/// u často navštěvované rozhledny je historie dlouhá.
class TowerDetailSheet extends ConsumerWidget {
  const TowerDetailSheet({super.key, required this.towerUuid});

  final String towerUuid;

  static Future<void> show(BuildContext context, String towerUuid) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TowerDetailSheet(towerUuid: towerUuid),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tower = ref.watch(towerProvider(towerUuid));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) => tower.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (t) => t == null
            ? const Center(child: Text('Rozhledna už neexistuje'))
            : _Content(stats: t, scrollController: scrollController),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.stats, required this.scrollController});

  final TowerWithStats stats;
  final ScrollController scrollController;

  String get _name => stats.tower.name ?? 'Rozhledna bez názvu';

  Future<void> _navigate() async {
    final t = stats.tower;
    // `geo:` nechá volbu na uživateli — nabídne Mapy.cz, Google Maps i cokoli
    // dalšího, co má v telefonu. Souřadnice v query kvůli tomu, aby cíl dostal
    // i jméno místa, ne jen bod.
    final uri = Uri.parse('geo:${t.lat},${t.lon}?q=${t.lat},${t.lon}'
        '(${Uri.encodeComponent(_name)})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addVisit(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VisitEditorSheet(
        towerUuid: stats.tower.uuid,
        towerName: _name,
      ),
    );
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, String action) async {
    if (action == 'edit') {
      await TowerEditorSheet.show(context, existing: stats.tower);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Smazat $_name?'),
        content: Text(stats.isVisited
            ? 'Přijdete i o ${stats.visitCount} zapsaných návštěv.'
            : 'Rozhlednu i její záznamy odstraníme.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(databaseProvider).softDeleteTower(stats.tower.uuid);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _editVisit(BuildContext context, Visit visit) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VisitEditorSheet(
        towerUuid: stats.tower.uuid,
        towerName: _name,
        existing: visit,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(visitsProvider(stats.tower.uuid));
    final theme = Theme.of(context);
    final t = stats.tower;

    final facts = <String>[
      if (t.region != null) t.region!,
      if (t.height != null) '${t.height!.round()} m vysoká',
      if (t.ele != null) '${t.ele!.round()} m n. m.',
    ];

    return ListView(
      controller: scrollController,
      // Spodní odsazení musí přičíst systémovou lištu telefonu — modální
      // panel bezpečnou zónu sám neřeší a poslední návštěva by se schovala
      // pod navigaci. `paddingOf` je proti `viewPaddingOf` správně: při
      // otevřené klávesnici klesne na nulu, takže se odsazení nesčítá dvakrát.
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(_name, style: theme.textTheme.headlineSmall)),
            PopupMenuButton<String>(
              onSelected: (action) => _onAction(context, ref, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Upravit'),
                  ),
                ),
                // Smazat jde jen vlastní bod. Rozhlednu z OSM by smazání
                // rozhodilo proti druhému telefonu, kde v datech pořád je.
                if (t.source == TowerSource.user)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Smazat'),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (facts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(facts.join(' · '),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
        const SizedBox(height: 12),
        TowerInfoCard(tower: t),
        if (t.wikipediaExtract != null || t.photoUrl != null)
          const SizedBox(height: 16),
        // Praktické údaje z OSM, které v datech byly, ale nikde se neukazovaly.
        _OsmFacts(tower: t),
        _VisitSummary(stats: stats),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _addVisit(context),
                icon: Icon(stats.isVisited ? Icons.add : Icons.check),
                label: Text(stats.isVisited ? 'Další návštěva' : 'Byl jsem tu'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _navigate,
              icon: const Icon(Icons.directions),
              tooltip: 'Navigovat',
            ),
            if (t.website != null)
              IconButton.filledTonal(
                onPressed: () => launchUrl(Uri.parse(t.website!),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.public),
                tooltip: 'Web',
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Návštěvy', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        visits.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Návštěvy se nenačetly: $e'),
          data: (list) => list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Zatím nenavštíveno.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                )
              : Column(
                  children: [
                    for (final v in list)
                      _VisitTile(
                        visit: v,
                        onEdit: () => _editVisit(context, v),
                        onDelete: () =>
                            ref.read(databaseProvider).softDeleteVisit(v.uuid),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Údaje z OSM, které se hodí před výjezdem: otevírací doba, vstupné,
/// přístupnost a vlastní popis mapera.
class _OsmFacts extends StatelessWidget {
  const _OsmFacts({required this.tower});

  final Tower tower;

  static const _accessLabels = {
    'yes': 'volně přístupná',
    'no': 'nepřístupná',
    'private': 'soukromá',
    'customers': 'jen pro hosty',
    'permissive': 'přístupná se svolením',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(IconData, String)>[
      if (tower.note != null) (Icons.notes, tower.note!),
      if (tower.openingHours != null)
        (Icons.schedule, tower.openingHours!),
      if (tower.fee != null)
        (Icons.payments_outlined,
            tower.fee == 'yes' ? 'Vstupné se platí' : 'Vstup zdarma'),
      if (tower.access != null)
        (Icons.lock_open, _accessLabels[tower.access] ?? tower.access!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, text) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(text, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shrnutí nad seznamem. Schválně odděluje „kolikrát“ od „kdy naposledy“ —
/// u pravidelně navštěvované rozhledny je zajímavé obojí.
class _VisitSummary extends StatelessWidget {
  const _VisitSummary({required this.stats});

  final TowerWithStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!stats.isVisited) {
      return Row(
        children: [
          Icon(Icons.radio_button_unchecked, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text('Nenavštíveno', style: theme.textTheme.titleSmall),
        ],
      );
    }

    final n = stats.visitCount;
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            n == 1
                ? 'Navštíveno ${dateFormat.format(stats.lastVisit!)}'
                : 'Navštíveno $n×, naposledy '
                    '${dateFormat.format(stats.lastVisit!)}',
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (stats.bestRating != null) ...[
          const Icon(Icons.star, size: 16, color: Colors.amber),
          Text('${stats.bestRating}'),
        ],
      ],
    );
  }
}

class _VisitTile extends ConsumerWidget {
  const _VisitTile({
    required this.visit,
    required this.onEdit,
    required this.onDelete,
  });

  final Visit visit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photosProvider(visit.uuid)).value ?? const [];
    final storage = ref.watch(photoStorageProvider).value;

    return Dismissible(
      key: ValueKey(visit.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return true;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(dateFormat.format(visit.visitedOn),
                        style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    if (visit.rating != null)
                      Row(
                        children: [
                          for (var i = 0; i < visit.rating!; i++)
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                        ],
                      ),
                  ],
                ),
                if (visit.note != null) ...[
                  const SizedBox(height: 4),
                  Text(visit.note!),
                ],
                if (photos.isNotEmpty && storage != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final p in photos)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                File(storage.file(p.fileName).path),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
