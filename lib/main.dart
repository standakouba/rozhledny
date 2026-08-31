import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/map/map_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/towers/tower_list_screen.dart';
import 'services/backup.dart';
import 'services/incoming_share.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DateFormat s českým locale bez tohohle vyhodí výjimku při prvním formátování
  // data návštěvy — a to je hned na detailu rozhledny.
  await initializeDateFormatting('cs');
  runApp(const ProviderScope(child: RozhlednyApp()));
}

class RozhlednyApp extends StatelessWidget {
  const RozhlednyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rozhledny',
      debugShowCheckedModeBanner: false,
      locale: const Locale('cs'),
      supportedLocales: const [Locale('cs'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  final _subscriptions = <StreamSubscription<void>>[];

  @override
  void initState() {
    super.initState();
    // Poslouchá se odsud, ne z obrazovky Nastavení: soubor může aplikaci
    // probudit ve chvíli, kdy Nastavení nikdo neotevřel, a výsledek by
    // se pak neměl kde zobrazit.
    final share = ref.read(incomingShareProvider);
    _subscriptions.addAll([
      share.results.stream.listen(_showReport),
      share.errors.stream.listen(_showError),
    ]);
    share.start();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  void _showReport(MergeReport report) {
    if (!mounted) return;
    final dupes = report.suspectedDuplicates.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data přijata'),
        content: Text(
          dupes == 0
              ? report.summary
              : '${report.summary}\n\nPozor: $dupes× je stejná rozhledna '
                  'zapsaná dvakrát ve stejný den. Nejspíš jste ten výlet '
                  'zapsali oba — přebytečnou návštěvu smažete v detailu '
                  'přejetím doleva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Rozumím'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static const _tabs = <_TabDef>[
    _TabDef('Mapa', Icons.map_outlined, Icons.map),
    _TabDef('Seznam', Icons.list_outlined, Icons.list),
    _TabDef('Statistiky', Icons.bar_chart_outlined, Icons.bar_chart),
    _TabDef('Nastavení', Icons.settings_outlined, Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          MapScreen(),
          TowerListScreen(),
          StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        // Výchozích 80 px ukrajuje z mapy zbytečně moc; 60 stačí na ikonu
        // i popisek a přitom zůstane nad hranicí pohodlného cíle pro prst.
        height: 60,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
