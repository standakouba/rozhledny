import 'package:uuid/uuid.dart';

/// Vlastní namespace pro UUID v5. Nesmí se nikdy změnit — jinak by se rozhledny
/// naseedované starší verzí aplikace přestaly párovat s těmi z novější a import
/// z druhého telefonu by je zdvojil.
const _osmNamespace = 'b2f6b1c4-3a4e-4f9f-9a1d-8c5e0a7d2f13';

/// Deterministické UUID rozhledny z OSM.
///
/// Stejná rozhledna musí mít stejné UUID na všech telefonech, aby slučování
/// při importu spárovalo návštěvy se správným bodem.
String osmTowerUuid(String osmType, int osmId) =>
    const Uuid().v5(_osmNamespace, '$osmType/$osmId');

/// Náhodné UUID pro vlastní rozhledny, návštěvy a fotky.
String newUuid() => const Uuid().v4();
