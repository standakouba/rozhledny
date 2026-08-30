import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/map/basemap.dart';

const _keyApiKey = 'mapy_api_key';
const _keyBasemap = 'basemap_id';
const _keyAllowRotation = 'allow_map_rotation';

// API klíč k Mapy.com se do aplikace **nezapéká**, ani ve vývojovém buildu.
//
// Z distribuovaného balíčku by ho šlo vytáhnout a čerpat cizí free tier.
// Mít na to zvláštní cestu jen pro vývoj by znamenalo dvě verze chování,
// z nichž ta riskantní se dřív nebo později dostane do vydání omylem.
//
// Klíč si tedy zadává každý uživatel sám v Nastavení a zůstává jen v jeho
// telefonu. Bez klíče aplikace normálně funguje na podkladu OpenStreetMap.

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
          mapyApiKey: _prefs.getString(_keyApiKey),
          // Výchozí je OpenStreetMap: funguje hned po instalaci a bez klíče.
          // Na turistickou mapu si uživatel přepne, až si klíč pořídí.
          basemapId: _prefs.getString(_keyBasemap) ?? osmStandard.id,
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
