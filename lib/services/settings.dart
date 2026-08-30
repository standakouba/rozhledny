import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/map/basemap.dart';

const _keyApiKey = 'mapy_api_key';
const _keyBasemap = 'basemap_id';
const _keyAllowRotation = 'allow_map_rotation';

/// Klíč zapečený do buildu přes `--dart-define-from-file=dart_defines.json`.
///
/// Slouží jen jako výchozí hodnota, aby vývojový build nemusel klíč pokaždé
/// klikat v Nastavení. Soubor s klíčem je v .gitignore; release build bez něj
/// prostě spadne na OSM, dokud se klíč nezadá ručně.
const _bakedApiKey = String.fromEnvironment('MAPY_API_KEY');

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (ref) => SharedPreferences.getInstance(),
);

/// Nastavení aplikace. Klíč k Mapy.com se drží tady, ne v repozitáři —
/// zadává se v Nastavení a zůstává jen na telefonu.
class Settings {
  const Settings({
    this.mapyApiKey,
    this.basemapId,
    this.allowRotation = false,
  });

  final String? mapyApiKey;
  final String? basemapId;

  /// Otáčení mapy dvěma prsty. Vypnuté, protože se spustí snadno omylem
  /// a pootočená mapa se v terénu čte špatně — sever nahoře je to, co člověk
  /// od papírové mapy čeká.
  final bool allowRotation;

  /// Vybraný podklad, nebo první použitelný. Bez klíče spadne na OSM, aby
  /// mapa fungovala hned po instalaci.
  MapBasemap get basemap {
    final chosen = basemapById(basemapId);
    return chosen.isUsable(mapyApiKey) ? chosen : osmStandard;
  }

  Settings copyWith({
    String? mapyApiKey,
    String? basemapId,
    bool? allowRotation,
  }) =>
      Settings(
        mapyApiKey: mapyApiKey ?? this.mapyApiKey,
        basemapId: basemapId ?? this.basemapId,
        allowRotation: allowRotation ?? this.allowRotation,
      );
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier(this._prefs)
      : super(Settings(
          // Ručně zadaný klíč má přednost před tím z buildu.
          mapyApiKey: _prefs.getString(_keyApiKey) ??
              (_bakedApiKey.isEmpty ? null : _bakedApiKey),
          // Bez uložené volby se začíná turistickou mapou — kvůli ní to celé je.
          basemapId: _prefs.getString(_keyBasemap) ?? mapyOutdoor.id,
          allowRotation: _prefs.getBool(_keyAllowRotation) ?? false,
        ));

  final SharedPreferences _prefs;

  Future<void> setMapyApiKey(String? key) async {
    final trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _prefs.remove(_keyApiKey);
    } else {
      await _prefs.setString(_keyApiKey, trimmed);
    }
    // Skládat nový Settings ručně znamená zapomenout na pole, která zrovna
    // nejsou na očích — zámek otáčení se takhle při uložení klíče ztrácel.
    state = Settings(
      mapyApiKey: trimmed,
      basemapId: state.basemapId,
      allowRotation: state.allowRotation,
    );
  }

  Future<void> setBasemap(String id) async {
    await _prefs.setString(_keyBasemap, id);
    state = state.copyWith(basemapId: id);
  }

  Future<void> setAllowRotation(bool value) async {
    await _prefs.setBool(_keyAllowRotation, value);
    state = state.copyWith(allowRotation: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).value;
  if (prefs == null) {
    throw StateError('settingsProvider se čte dřív, než doběhne '
        'sharedPrefsProvider — obal ho v UI přes AsyncValue.');
  }
  return SettingsNotifier(prefs);
});
