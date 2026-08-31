import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/database.dart';
import '../../data/providers.dart';
import '../../services/location.dart';
import '../visits/visit_editor.dart';
import 'tower_colors.dart';
import 'tower_detail_sheet.dart';

enum TowerFilter { all, visited, unvisited, mine }

enum TowerSort { distance, name, lastVisit, visitCount }

/// Seznam rozhleden s hledáním, filtry a řazením.
///
/// Doplněk mapy pro chvíle, kdy člověk neví, kam se dívat — třeba „co mi ještě
/// chybí v Jihočeském kraji“ nebo „kam jsme jeli naposledy“.
class TowerListScreen extends ConsumerStatefulWidget {
  const TowerListScreen({super.key});

  @override
  ConsumerState<TowerListScreen> createState() => _TowerListScreenState();
}

class _TowerListScreenState extends ConsumerState<TowerListScreen> {
  final _search = TextEditingController();
  TowerFilter _filter = TowerFilter.all;
  TowerSort _sort = TowerSort.distance;
  String? _region;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(TowerWithStats t) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final name = t.tower.name?.toLowerCase() ?? '';
      if (!name.contains(q)) return false;
    }
    if (_region != null && t.tower.region != _region) return false;
    return switch (_filter) {
      TowerFilter.all => true,
      TowerFilter.visited => t.isVisited,
      TowerFilter.unvisited => !t.isVisited,
      TowerFilter.mine => t.tower.source == TowerSource.user,
    };
  }

  List<TowerWithStats> _apply(List<TowerWithStats> all, Position? me) {
    final list = all.where(_matches).toList();

    int byName(TowerWithStats a, TowerWithStats b) =>
        (a.tower.name ?? 'ž').toLowerCase().compareTo(
            (b.tower.name ?? 'ž').toLowerCase());

    switch (_sort) {
      // Bez polohy nemá řazení podle vzdálenosti co počítat, tak spadne
      // na abecedu místo toho, aby seznam vypadal náhodně zamíchaný.
      case TowerSort.distance when me != null:
        list.sort((a, b) => distanceMeters(
                    me.latitude, me.longitude, a.tower.lat, a.tower.lon)
            .compareTo(distanceMeters(
                me.latitude, me.longitude, b.tower.lat, b.tower.lon)));
      case TowerSort.distance:
      case TowerSort.name:
        list.sort(byName);
      case TowerSort.lastVisit:
        list.sort((a, b) {
          final av = a.lastVisit, bv = b.lastVisit;
          if (av == null && bv == null) return byName(a, b);
          if (av == null) return 1;
          if (bv == null) return -1;
          return bv.compareTo(av);
        });
      case TowerSort.visitCount:
        list.sort((a, b) {
          final c = b.visitCount.compareTo(a.visitCount);
          return c != 0 ? c : byName(a, b);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final towers = ref.watch(towersProvider);
    final me = ref.watch(currentPositionProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Hledat rozhlednu…',
            border: InputBorder.none,
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _search.clear()),
                  ),
          ),
        ),
      ),
      body: towers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (all) {
          final list = _apply(all, me);
          final regions = (all
                .map((t) => t.tower.region)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort());

          return Column(
            children: [
              _FilterBar(
                filter: _filter,
                sort: _sort,
                region: _region,
                regions: regions,
                hasLocation: me != null,
                onFilter: (f) => setState(() => _filter = f),
                onSort: (s) => setState(() => _sort = s),
                onRegion: (r) => setState(() => _region = r),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('${list.length} z ${all.length}',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Nic neodpovídá.'))
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) => _TowerTile(
                          stats: list[i],
                          me: me,
                          onTap: () =>
                              TowerDetailSheet.show(context, list[i].tower.uuid),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.sort,
    required this.region,
    required this.regions,
    required this.hasLocation,
    required this.onFilter,
    required this.onSort,
    required this.onRegion,
  });

  final TowerFilter filter;
  final TowerSort sort;
  final String? region;
  final List<String> regions;
  final bool hasLocation;
  final ValueChanged<TowerFilter> onFilter;
  final ValueChanged<TowerSort> onSort;
  final ValueChanged<String?> onRegion;

  static const _filterLabels = {
    TowerFilter.all: 'Vše',
    TowerFilter.visited: 'Navštívené',
    TowerFilter.unvisited: 'Chybí',
    TowerFilter.mine: 'Moje',
  };

  static const _sortLabels = {
    TowerSort.distance: 'Nejbližší',
    TowerSort.name: 'Abecedně',
    TowerSort.lastVisit: 'Naposledy',
    TowerSort.visitCount: 'Nejčastěji',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final f in TowerFilter.values) ...[
            ChoiceChip(
              label: Text(_filterLabels[f]!),
              selected: filter == f,
              onSelected: (_) => onFilter(f),
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 6),
          PopupMenuButton<TowerSort>(
            initialValue: sort,
            onSelected: onSort,
            itemBuilder: (_) => [
              for (final s in TowerSort.values)
                PopupMenuItem(
                  value: s,
                  // Bez polohy je „nejbližší“ jen matoucí nabídka.
                  enabled: s != TowerSort.distance || hasLocation,
                  child: Text(_sortLabels[s]!),
                ),
            ],
            child: Chip(
              avatar: const Icon(Icons.sort, size: 18),
              label: Text(_sortLabels[sort]!),
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String?>(
            initialValue: region,
            onSelected: onRegion,
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Všechny kraje')),
              for (final r in regions) PopupMenuItem(value: r, child: Text(r)),
            ],
            child: Chip(
              avatar: const Icon(Icons.place_outlined, size: 18),
              label: Text(region ?? 'Kraj'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TowerTile extends StatelessWidget {
  const _TowerTile({required this.stats, required this.me, required this.onTap});

  final TowerWithStats stats;
  final Position? me;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = stats.tower;
    final theme = Theme.of(context);

    final subtitle = <String>[
      if (t.region != null) t.region!,
      if (me != null)
        formatDistance(
            distanceMeters(me!.latitude, me!.longitude, t.lat, t.lon)),
      if (stats.lastVisit != null) dateFormat.format(stats.lastVisit!),
    ];

    return ListTile(
      onTap: onTap,
      leading: Icon(
        stats.isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
        color: stats.isVisited
            ? visitedColor
            : theme.colorScheme.outline,
      ),
      title: Text(t.name ?? 'Rozhledna bez názvu',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty ? null : Text(subtitle.join(' · ')),
      trailing: stats.visitCount > 1
          ? Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${stats.visitCount}×'),
            )
          : null,
    );
  }
}
