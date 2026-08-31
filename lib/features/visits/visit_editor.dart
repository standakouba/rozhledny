import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../data/ids.dart';
import '../../data/providers.dart';

final dateFormat = DateFormat('d. M. y', 'cs');

/// Formulář jedné návštěvy. Používá se pro přidání i pro úpravu — u opakovaně
/// navštívené rozhledny je otevřený několikrát nad různými záznamy.
class VisitEditorSheet extends ConsumerStatefulWidget {
  const VisitEditorSheet({
    super.key,
    required this.towerUuid,
    required this.towerName,
    this.existing,
  });

  final String towerUuid;
  final String towerName;

  /// `null` = nová návštěva.
  final Visit? existing;

  @override
  ConsumerState<VisitEditorSheet> createState() => _VisitEditorSheetState();
}

class _VisitEditorSheetState extends ConsumerState<VisitEditorSheet> {
  /// `null` = nevím kdy. U rozhleden zapisovaných zpětně je to běžný případ.
  late DateTime? _date;
  late int? _rating;
  late TextEditingController _note;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // U nové návštěvy se předvyplní dnešek — to je běžný případ. U úpravy se
    // bere, co je uložené, včetně prázdna: „nevím kdy“ se nesmí při otevření
    // formuláře tiše přepsat na dnešek.
    _date = widget.existing == null ? DateTime.now() : widget.existing!.visitedOn;
    _rating = widget.existing?.rating;
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Kdy jste tam byli?',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _write();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Neošetřená chyba by se projevila jen zaseknutým tlačítkem.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Návštěvu se nepodařilo uložit: $e')),
      );
    }
  }

  Future<void> _write() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final uuid = widget.existing?.uuid ?? newUuid();

    await db.upsertVisit(VisitsCompanion.insert(
      uuid: uuid,
      towerUuid: widget.towerUuid,
      // Čas se zahazuje — návštěva je záležitost dne, ne minuty, a jednotný
      // tvar usnadní hledání duplicit při importu z druhého telefonu.
      visitedOn: Value(
        _date == null ? null : DateTime(_date!.year, _date!.month, _date!.day),
      ),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      rating: Value(_rating),
      note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        // Klávesnice (viewInsets) i systémová lišta (padding). `paddingOf`
        // klesne na nulu, když je klávesnice venku, takže se nesčítají.
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'Byl jsem tu' : 'Úprava návštěvy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(widget.towerName,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_date == null ? Icons.event_busy : Icons.event),
              title: Text(
                _date == null ? 'Datum neznámé' : dateFormat.format(_date!),
                style: _date == null
                    ? TextStyle(color: Theme.of(context).colorScheme.outline)
                    : null,
              ),
              subtitle: _date == null
                  ? const Text('Návštěva se počítá, jen nepůjde do přehledu '
                      'po letech')
                  : null,
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDate,
            ),
            // Zpětně zadávané rozhledny jsou hlavní důvod, proč tohle
            // tlačítko existuje — po letech si datum nikdo nevybaví.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _date = _date == null
                    ? DateTime.now()
                    : null),
                icon: Icon(
                    _date == null ? Icons.event_available : Icons.event_busy,
                    size: 18),
                label: Text(_date == null
                    ? 'Přece jen datum zadám'
                    : 'Nevzpomenu si na datum'),
              ),
            ),
            const SizedBox(height: 8),
            _RatingPicker(
              rating: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Poznámka',
                hintText: 'S kým, jaký byl výhled, bylo otevřeno…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Zrušit'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: Text(isNew ? 'Zapsat návštěvu' : 'Uložit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.rating, required this.onChanged});

  final int? rating;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            // Klepnutí na už vybranou hvězdu hodnocení zruší — jinak by nešlo
            // vrátit se k „nehodnoceno“.
            onPressed: () => onChanged(rating == i ? null : i),
            icon: Icon(
              (rating ?? 0) >= i ? Icons.star : Icons.star_border,
              color: Colors.amber.shade700,
            ),
          ),
        const SizedBox(width: 8),
        Text(rating == null ? 'nehodnoceno' : '$rating/5',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

