import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/ids.dart';
import '../../data/providers.dart';
import '../../services/contributions.dart';

/// Nahlášení chyby v základních datech — „tahle rozhledna tu nemá co dělat“.
///
/// Bod z mapy **nemizí**. Jestli má zmizet ze všech telefonů, se nerozhodne
/// v jednom z nich: rozhledna může být zavřená, ne zbouraná, a stát tam dál.
/// Hlášení je zpráva, ne zásah do dat, a čeká, až ho uživatel sám odešle
/// v Nastavení.
///
/// Špatný název ani posunutá poloha sem nepatří — na ty je editor rozhledny,
/// který rovnou nese opravenou hodnotu.
class TowerReportSheet extends ConsumerStatefulWidget {
  const TowerReportSheet({super.key, required this.tower});

  final Tower tower;

  static Future<void> show(BuildContext context, Tower tower) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TowerReportSheet(tower: tower),
    );
  }

  @override
  ConsumerState<TowerReportSheet> createState() => _TowerReportSheetState();
}

class _TowerReportSheetState extends ConsumerState<TowerReportSheet> {
  final _note = TextEditingController();
  TowerReportReason _reason = TowerReportReason.gone;

  /// Hlášení, které u rozhledny už leží. Formulář se jím předvyplní a místo
  /// druhého záznamu ho přepíše — viz unique index v [TowerReports].
  TowerReport? _existing;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final found = await ref
        .read(databaseProvider)
        .reportForTower(widget.tower.uuid);
    if (!mounted) return;
    setState(() {
      _existing = found;
      if (found != null) {
        _reason = found.reason;
        _note.text = found.note ?? '';
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// U „něco jiného“ je popis jediná informace, kterou hlášení nese. Bez něj
  /// by dorazilo prázdné a nedalo by se podle něj rozhodnout vůbec nic.
  bool get _needsNote =>
      _reason == TowerReportReason.other && _note.text.trim().isEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final note = _note.text.trim();
    try {
      await ref.read(databaseProvider).upsertReport(
            TowerReportsCompanion.insert(
              uuid: _existing?.uuid ?? newUuid(),
              towerUuid: widget.tower.uuid,
              reason: _reason,
              note: Value(note.isEmpty ? null : note),
              createdAt: _existing?.createdAt ?? DateTime.now(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nahlášení se nepovedlo uložit: $e')),
      );
    }
  }

  Future<void> _withdraw() async {
    setState(() => _saving = true);
    await ref.read(databaseProvider).deleteReport(widget.tower.uuid);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        // Klávesnice i systémová lišta; nesčítají se, protože se vzájemně
        // vylučují — viz komentář ve visit_editor.dart.
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nahlásit chybu v datech', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Rozhledna vám z mapy nezmizí. Zpráva počká v Nastavení, '
              'odkud ji pošlete autorovi aplikace.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              RadioGroup<TowerReportReason>(
                groupValue: _reason,
                onChanged: (v) {
                  if (_saving || v == null) return;
                  setState(() => _reason = v);
                },
                child: Column(
                  children: [
                    for (final reason in TowerReportReason.values)
                      RadioListTile<TowerReportReason>(
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(_capitalized(reasonLabel(reason))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: _reason == TowerReportReason.other
                      ? 'Co je špatně'
                      : 'Poznámka (nepovinné)',
                  helperText: 'Co jste na místě viděli. Jde to k nám, '
                      'ne do vašich poznámek.',
                  // Nápověda se vejde na dva řádky. S výchozím jedním se na
                  // telefonu uřízne přesně ta půlka věty, kvůli které tam je:
                  // že tenhle text opustí telefon.
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_existing != null)
                    TextButton(
                      onPressed: _saving ? null : _withdraw,
                      child: const Text('Zrušit nahlášení'),
                    )
                  else
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Zrušit'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving || _needsNote ? null : _save,
                    icon: const Icon(Icons.outlined_flag),
                    label: Text(_existing == null ? 'Nahlásit' : 'Uložit'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _capitalized(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
