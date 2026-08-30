import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Poloha je v téhle aplikaci vždy nepovinná.
///
/// Aplikace musí být plně použitelná i bez ní — mapa, seznam i zapisování
/// návštěv fungují stejně. Poloha jen přidává „co mám v okolí“ a vzdálenosti,
/// takže se odmítnuté oprávnění nikde neřeší jako chyba, jen se prostě
/// vzdálenosti nezobrazí.
final currentPositionProvider = StreamProvider<Position?>((ref) async* {
  if (!await Geolocator.isLocationServiceEnabled()) {
    yield null;
    return;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    yield null;
    return;
  }

  // Poslední známá poloha přijde okamžitě, čerstvá až za pár sekund —
  // seznam tak nemusí čekat na fix, aby mohl řadit podle vzdálenosti.
  yield await Geolocator.getLastKnownPosition();
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    ),
  );
});

/// Vzdálenost vzdušnou čarou v metrech.
///
/// Vlastní haversine místo `Geolocator.distanceBetween`, protože se volá
/// pro každou ze 672 rozhleden při každém překreslení seznamu a průchod
/// přes platformní kanál by byl zbytečně drahý.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// „850 m“ / „12,4 km“ / „137 km“ — bez zbytečné přesnosti na dálku.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  if (km < 100) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}
