import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../towers/tower_detail_sheet.dart';
import 'czech_plurals.dart';

final allVisitsProvider = StreamProvider<List<Visit>>(
  (ref) => ref.watch(databaseProvider).watchAllVisits(),
);

/// Přehled pokroku.
///
/// Celá obrazovka stojí na jednom rozlišení: **pokořené rozhledny** je počet
/// různých míst, **návštěvy** je počet výletů. U Kletě, kam se jezdí pravidelně,
/// se ta dvě čísla rozcházejí — a právě to je na tom zajímavé.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final towers = ref.watch(towersProvider);
    final visits = ref.watch(allVisitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiky')),
      body: towers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (all) => _Body(all: all, visits: visits.value ?? const []),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.all, required this.visits});

  final List<TowerWithStats> all;
  final List<Visit> visits;

  @override
  Widget build(BuildContext context) {
    final conquered = all.where((t) => t.isVisited).toList();

    final byRegion = <String, ({int total, int visited})>{};
    for (final t in all) {
      final r = t.tower.region ?? 'Bez kraje';
      final cur = byRegion[r] ?? (total: 0, visited: 0);
      byRegion[r] = (
        total: cur.total + 1,
        visited: cur.visited + (t.isVisited ? 1 : 0),
      );
    }
    final regions = byRegion.entries.toList()
      ..sort((a, b) => b.value.visited.compareTo(a.value.visited));

    // Návštěvy bez data se do rozpadu po letech zařadit nedají, ale zmizet
    // taky nesmí — jinak by se součet přehledu rozešel s celkovým počtem
    // a vypadalo by to jako chyba.
    final byYear = <int, int>{};
    var undated = 0;
    for (final v in visits) {
      final on = v.visitedOn;
      if (on == null) {
        undated++;
        continue;
      }
      byYear[on.year] = (byYear[on.year] ?? 0) + 1;
    }
    final years = byYear.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    final mostVisited = conquered.where((t) => t.visitCount > 1).toList()
      ..sort((a, b) => b.visitCount.compareTo(a.visitCount));
    final bestRated = conquered.where((t) => t.bestRating != null).toList()
      ..sort((a, b) => b.bestRating!.compareTo(a.bestRating!));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Progress(conquered: conquered.length, total: all.length),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Tile(
                value: '${conquered.length}',
                label: 'pokořených rozhleden',
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                value: '${visits.length}',
                label: 'návštěv celkem',
                icon: Icons.hiking,
              ),
            ),
          ],
        ),
        if (visits.length > conquered.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              returnsSentence(visits.length - conquered.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 24),
        _Section(title: 'Podle krajů'),
        for (final e in regions)
          _RegionRow(
            name: e.key,
            visited: e.value.visited,
            total: e.value.total,
          ),
        if (years.isNotEmpty || undated > 0) ...[
          const SizedBox(height: 24),
          _Section(title: 'Návštěvy po letech'),
          for (final y in years)
            _BarRow(
              label: '${y.key}',
              value: y.value,
              max: years.isEmpty
                  ? 1
                  : years.map((e) => e.value).reduce((a, b) => a > b ? a : b),
            ),
          if (undated > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'a $undated ${visitWord(undated)} bez data',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
        if (mostVisited.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Section(title: 'Kam se vracíte'),
          for (final t in mostVisited.take(10))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(t.tower.name ?? 'Rozhledna bez názvu'),
              trailing: Text('${t.visitCount}×'),
              onTap: () => TowerDetailSheet.show(context, t.tower.uuid),
            ),
        ],
        if (bestRated.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Section(title: 'Nejlépe hodnocené'),
          for (final t in bestRated.take(10))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(t.tower.name ?? 'Rozhledna bez názvu'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < t.bestRating!; i++)
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                ],
              ),
              onTap: () => TowerDetailSheet.show(context, t.tower.uuid),
            ),
        ],
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.conquered, required this.total});

  final int conquered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : conquered / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$conquered ze $total rozhleden',
            style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: ratio, minHeight: 12),
        ),
        const SizedBox(height: 4),
        Text('${(ratio * 100).toStringAsFixed(1).replaceAll('.', ',')} %',
            style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.name,
    required this.visited,
    required this.total,
  });

  final String name;
  final int visited;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(name, maxLines: 1)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : visited / total,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text('$visited/$total',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: max == 0 ? 0 : value / max,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
