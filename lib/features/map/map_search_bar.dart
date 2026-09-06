import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/database.dart';
import '../../services/location.dart';
import '../towers/tower_search.dart';

/// Hledání rozhledny přímo nad mapou.
///
/// Bez něj vedla cesta ke konkrétní rozhledně přes záložku Seznam a zpátky na
/// mapu přes její detail — čtyři klepnutí za to, aby se člověk podíval, kde
/// ta věž vlastně je. Nálezy se ukazují pod polem a klepnutí na jeden z nich
/// mapu přesune; pole zůstane vyplněné, ať je vidět, co se hledalo.
/// Sklopí klávesnici tak, aby se sama nevrátila.
///
/// `FocusScope.of(context).unfocus()` vypadá jako totéž, ale odebírá zaměření
/// scope, ne poli — a scope si přitom pole drží jako svoje poslední zaměřené.
/// Jakmile se pak zavře detail rozhledny, scope zaměření dostane zpátky
/// a poslušně ho předá poli: klávesnice i nálezy naskočí znovu, aniž by o to
/// kdo stál. Odebrat zaměření přímo poli tuhle paměť scope vyčistí.
void dismissSearchFocus() => FocusManager.instance.primaryFocus?.unfocus();

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    super.key,
    required this.towers,
    required this.onSelected,
    this.me,
  });

  /// Rozhledny, ze kterých se vybírá. Bezejmenné se do nálezů nedostanou,
  /// takže nastavení „skrýt bez názvu“ na hledání nic nemění.
  final List<TowerWithStats> towers;

  /// Poloha uživatele. Když je známá, u nálezu se ukáže vzdálenost —
  /// „Chlum“ je v Česku pětkrát a jinak se nedá poznat který.
  final Position? me;

  final void Function(TowerWithStats tower) onSelected;

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Nálezy visí nad mapou, takže musí zmizet ve chvíli, kdy člověk klepne
    // jinam. Řídí se proto zaměřením pole: mapa ho při klepnutí do ní odebírá
    // a tím seznam zavře. Text v poli zůstává, ať je vidět, co se hledalo.
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    setState(_controller.clear);
    _focus.unfocus();
  }

  void _select(TowerWithStats tower) {
    _focus.unfocus();
    widget.onSelected(tower);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _controller.text.trim();
    final showResults = _focus.hasFocus && query.isNotEmpty;
    final found = showResults
        ? searchTowers(widget.towers, query)
        : const <TowerWithStats>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Hledat rozhlednu…',
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Zrušit hledání',
                    onPressed: _clear,
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        if (showResults)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              // Strop, aby nálezy nepřekryly celou mapu — pod nimi má být
              // pořád vidět, kam se člověk dívá.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 264),
                child: found.isEmpty
                    ? const ListTile(
                        dense: true,
                        title: Text('Nic takového tu není'),
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final t in found) _result(context, t),
                        ],
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _result(BuildContext context, TowerWithStats t) {
    final me = widget.me;
    final parts = <String>[
      if (t.tower.region != null) t.tower.region!,
      if (me != null)
        _distance(
          distanceMeters(me.latitude, me.longitude, t.tower.lat, t.tower.lon),
        ),
    ];

    return ListTile(
      dense: true,
      title: Text(t.tower.name!, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
      trailing: t.isVisited
          ? const Icon(Icons.check, size: 18)
          : null,
      onTap: () => _select(t),
    );
  }

  /// Do deseti kilometrů na desetinu přesně, dál už celé kilometry — na
  /// „73,4 km“ se nikdo nedívá.
  String _distance(double meters) {
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }
}
