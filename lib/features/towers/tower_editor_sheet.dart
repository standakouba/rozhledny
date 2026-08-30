import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/database.dart';
import '../../data/ids.dart';
import '../../data/providers.dart';

/// Formulář vlastní rozhledny — té, kterou jsme našli a v datech není.
///
/// Slouží i k opravě rozhledny z OSM (překlep v názvu, posunutá poloha).
/// V tom případě se nastaví [Towers.userModified], aby pozdější aktualizace
/// dat z OSM úpravu nepřepsala.
class TowerEditorSheet extends ConsumerStatefulWidget {
  const TowerEditorSheet({super.key, this.existing, this.initialPoint});

  final Tower? existing;

  /// Poloha z dlouhého stisku do mapy, nebo aktuální GPS pozice.
  final LatLng? initialPoint;

  static Future<void> show(
    BuildContext context, {
    Tower? existing,
    LatLng? initialPoint,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          TowerEditorSheet(existing: existing, initialPoint: initialPoint),
    );
  }

  @override
  ConsumerState<TowerEditorSheet> createState() => _TowerEditorSheetState();
}

class _TowerEditorSheetState extends ConsumerState<TowerEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _lat;
  late final TextEditingController _lon;
  late final TextEditingController _height;
  late final TextEditingController _note;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _lat = TextEditingController(
        text: (e?.lat ?? widget.initialPoint?.latitude)?.toStringAsFixed(6) ?? '');
    _lon = TextEditingController(
        text: (e?.lon ?? widget.initialPoint?.longitude)?.toStringAsFixed(6) ?? '');
    _height = TextEditingController(text: e?.height?.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _lat, _lon, _height, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _write();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Bez tohohle se výjimka propadne do neošetřené asynchronní chyby
      // a formulář jen zůstane viset s otáčejícím se kolečkem — uživatel
      // vidí „nic se nestalo“ a netuší proč.
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uložení se nepovedlo: $e')),
      );
    }
  }

  Future<void> _write() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final e = widget.existing;

    await db.upsertTower(TowersCompanion.insert(
      uuid: e?.uuid ?? newUuid(),
      lat: double.parse(_lat.text.replaceAll(',', '.')),
      lon: double.parse(_lon.text.replaceAll(',', '.')),
      source: e?.source ?? TowerSource.user,
      createdAt: e?.createdAt ?? now,
      updatedAt: now,
      osmType: Value(e?.osmType),
      osmId: Value(e?.osmId),
      name: Value(_name.text.trim().isEmpty ? null : _name.text.trim()),
      height: Value(double.tryParse(_height.text.replaceAll(',', '.'))),
      region: Value(e?.region),
      website: Value(e?.website),
      note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
      // Ruční zásah do bodu z OSM se musí označit, jinak by ho aktualizace dat
      // vrátila do původního stavu.
      userModified: Value(e != null && e.source == TowerSource.osm),
    ));
  }

  String? _validateCoordinate(String? v, {required bool isLat}) {
    if (v == null || v.trim().isEmpty) return 'Vyplňte';
    final d = double.tryParse(v.replaceAll(',', '.'));
    if (d == null) return 'Není číslo';
    // Kontrola na rozsah ČR s rezervou — chytí prohozenou šířku a délku,
    // což je při ručním přepisu souřadnic nejčastější chyba.
    final ok = isLat ? (d > 48 && d < 52) : (d > 11 && d < 20);
    return ok ? null : (isLat ? 'Mimo ČR (48–52)' : 'Mimo ČR (11–20)');
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNew ? 'Nová rozhledna' : 'Úprava rozhledny',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Název',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (v) => _validateCoordinate(v, isLat: true),
                      decoration: const InputDecoration(
                        labelText: 'Šířka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lon,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: (v) => _validateCoordinate(v, isLat: false),
                      decoration: const InputDecoration(
                        labelText: 'Délka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _height,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Výška v metrech (nepovinné)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Poznámka (nepovinné)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Zrušit'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(isNew ? 'Přidat' : 'Uložit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
