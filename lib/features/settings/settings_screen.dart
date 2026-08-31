import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers.dart';
import '../map/basemap.dart';
import '../../services/backup.dart';
import '../../services/photo_prefetch.dart';
import '../../services/photos.dart';
import '../../services/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení')),
      body: prefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Chyba: $e')),
        data: (_) => const _Body(),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final towers = ref.watch(towersProvider).value;

    return ListView(
      children: [
        const _Header('Mapa'),
        RadioGroup<String>(
          groupValue: settings.basemap.id,
          onChanged: (v) => notifier.setBasemap(v!),
          child: Column(
            children: [
              for (final b in basemaps)
                RadioListTile<String>(
                  value: b.id,
                  // Podklad bez klíče se nabízet může, ale vybrat nejde —
                  // jinak by se mapa po přepnutí jen tiše vyprázdnila.
                  enabled: b.isUsable(settings.mapyApiKey),
                  title: Text(b.label),
                  subtitle: b.isUsable(settings.mapyApiKey)
                      ? null
                      : const Text('Vyžaduje API klíč Mapy.com'),
                ),
            ],
          ),
        ),
        // Zámek otáčení se ovládá kompasem přímo na mapě: nechtěného pootočení
        // si člověk všimne v terénu a v tu chvíli hledá tlačítko pod palcem,
        // ne položku v menu. Přepínač tady by se s kompasem jen rozcházel.
        const Divider(),
        const _Header('API klíč Mapy.com'),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Nepovinné. Turistická a letecká mapa Mapy.com vyžadují vlastní '
            'klíč — v aplikaci žádný není, aby se nedal zneužít. Klíč zůstává '
            'jen ve vašem telefonu.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        _ApiKeyField(
          value: settings.mapyApiKey,
          onSave: notifier.setMapyApiKey,
        ),
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: const Text('Získat klíč na developer.mapy.com'),
          subtitle: const Text('Zdarma, 250 tisíc dlaždic měsíčně'),
          onTap: () => launchUrl(
            Uri.parse('https://developer.mapy.com/en/my-account/'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const Divider(),
        const _Header('Data'),
        ListTile(
          leading: const Icon(Icons.travel_explore),
          title: const Text('Rozhledny v databázi'),
          trailing: Text(towers == null ? '…' : '${towers.length}'),
        ),
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Z toho navštívených'),
          trailing: Text(towers == null
              ? '…'
              : '${towers.where((t) => t.isVisited).length}'),
        ),
        const _PhotoPrefetchTile(),
        const Divider(),
        const _Header('Přenos na druhý telefon'),
        const _BackupTiles(),
        const Divider(),
        const _Header('O aplikaci'),
        const _VersionTile(),
        const ListTile(
          leading: Icon(Icons.copyright),
          title: Text('Rozhledny'),
          subtitle: Text('© 2026 Stanislav Kouba'),
        ),
        // Copyright výše se týká aplikace. Data uvnitř mají vlastní autory
        // a licence, takže se uvádějí odděleně — smíchat obojí do jednoho
        // řádku by tvrdilo něco, co není pravda.
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Zdroje dat'),
          subtitle: Text(
            'Rozhledny © OpenStreetMap contributors (ODbL)\n'
            'Popisy z Wikipedie (CC BY-SA), fotky z Wikimedia Commons\n'
            'Mapové podklady © Seznam.cz a.s. a další',
          ),
          isThreeLine: true,
        ),
      ],
    );
  }
}

/// Fotky rozhleden se jinak stahují až při otevření detailu, což v lese bez
/// signálu nepomůže. Tohle je „připravit se doma na Wi-Fi“.
class _PhotoPrefetchTile extends ConsumerWidget {
  const _PhotoPrefetchTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(photoCountProvider);
    final progress = ref.watch(photoPrefetchProvider);
    final prefetcher = ref.read(photoPrefetchProvider.notifier);
    final running = progress != null && !progress.finished;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Připravit fotky offline'),
          subtitle: Text(
            running
                ? 'Stahuji ${progress.done} z ${progress.total}…'
                : progress?.finished == true
                    ? 'Hotovo${progress!.failed > 0 ? ", ${progress.failed} se nepodařilo" : ""}'
                    : '$total fotek, zhruba 10 MB',
          ),
          trailing: running
              ? TextButton(
                  onPressed: prefetcher.cancel,
                  child: const Text('Zrušit'),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: total == 0 ? null : prefetcher.run,
                ),
        ),
        if (running)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(value: progress.ratio),
          ),
      ],
    );
  }
}

/// Export a import. Jediná cesta, jak se data dostanou mezi telefony —
/// žádný server, žádné účty.
class _BackupTiles extends ConsumerStatefulWidget {
  const _BackupTiles();

  @override
  ConsumerState<_BackupTiles> createState() => _BackupTilesState();
}

class _BackupTilesState extends ConsumerState<_BackupTiles> {
  bool _busy = false;

  /// Sdílení návštěv a úplná záloha jsou tatáž operace s jedním rozdílem —
  /// fotkami. Ty ale dělají rozdíl mezi desítkami kilobajtů a stovkami
  /// megabajtů, takže je to v UI oddělené na dvě různá tlačítka.
  Future<void> _export({required bool includePhotos}) async {
    setState(() => _busy = true);
    try {
      final db = ref.read(databaseProvider);
      final storage = await ref.read(photoStorageProvider.future);
      final payload = BackupPayload(
        towers: await db.exportableTowers(),
        visits: await db.allVisitsForExport(),
        photos: await db.allPhotosForExport(),
      );
      final bytes = await buildBackupArchive(
        payload: payload,
        storage: storage,
        includePhotos: includePhotos,
      );
      final file =
          await writeBackupToFile(bytes, await getTemporaryDirectory());

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        text: includePhotos
            ? 'Úplná záloha rozhleden'
            : 'Rozhledny: ${payload.visits.length} návštěv',
      ));
    } catch (e) {
      _tell('Nepovedlo se to: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    // FileType.any schválně: záloha může dorazit mailem i messengerem
    // a ty ZIPu občas přiřadí vlastní MIME typ, na který by filtr nesedl.
    final file = await FilePicker.pickFile(
      dialogTitle: 'Vyberte zálohu rozhleden',
      type: FileType.any,
    );
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final report = await restoreBackupArchive(
        zipBytes: bytes,
        db: ref.read(databaseProvider),
        storage: await ref.read(photoStorageProvider.future),
      );
      if (mounted) await _showReport(report);
    } catch (e) {
      _tell('Import se nepovedl: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showReport(MergeReport report) {
    final dupes = report.suspectedDuplicates;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import hotov'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.summary),
            if (dupes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Pozor: ${dupes.length}× je stejná rozhledna zapsaná dvakrát '
                've stejný den. Nejspíš jste ten výlet zapsali oba — projděte '
                'si je v detailu rozhledny a přebytečnou návštěvu smažte '
                'přejetím doleva.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ],
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

  void _tell(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: const Text('Sdílet návštěvy'),
          subtitle: const Text('Malý soubor bez fotek — pošlete ho po výletu. '
              'Druhý telefon na něj jen klepne.'),
          isThreeLine: true,
          enabled: !_busy,
          onTap: () => _export(includePhotos: false),
        ),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Úplná záloha'),
          subtitle: const Text('Včetně fotek. Na přechod na nový telefon.'),
          enabled: !_busy,
          onTap: () => _export(includePhotos: true),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Načíst ze souboru'),
          subtitle: const Text('Data se sloučí, nic se nepřepíše'),
          enabled: !_busy,
          onTap: _import,
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

/// Verze a číslo buildu.
///
/// Čte se z instalovaného balíčku, ne z konstanty v kódu — jinak by se dřív
/// nebo později rozešly a hlášení „mám verzi X“ by přestalo být k užitku.
class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListTile(
          leading: const Icon(Icons.tag),
          title: const Text('Verze'),
          subtitle: Text(info == null
              ? '…'
              : '${info.version} (build ${info.buildNumber})'),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({required this.value, required this.onSave});

  final String? value;
  final Future<void> Function(String?) onSave;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');
  bool _visible = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        // Klíč je sice jen na dlaždice, ale je vázaný na účet — nemá důvod
        // svítit na displeji, když se člověk dívá do nastavení ve vlaku.
        obscureText: !_visible,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: 'Klíč',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _visible = !_visible),
              ),
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: () async {
                  await widget.onSave(_controller.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Klíč uložen')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
