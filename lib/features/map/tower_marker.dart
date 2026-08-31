import 'package:flutter/material.dart';

import '../towers/tower_colors.dart';

/// Značka rozhledny na mapě.
///
/// Vědomě lehký widget bez Material vrstev — na mapě jich je naráz i několik
/// stovek a každá dekorace navíc se projeví na plynulosti posunu.
class TowerMarker extends StatelessWidget {
  const TowerMarker({
    super.key,
    required this.visitCount,
    required this.compact,
    this.selected = false,
  });

  /// Kolikrát je rozhledna navštívená. 0 = ještě nepokořená.
  final int visitCount;

  /// Při odzoomované mapě se kreslí jen tečka — jmenovka ani odznak by se
  /// stejně nedaly přečíst.
  final bool compact;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final visited = visitCount > 0;
    final color = visited ? visitedColor : unvisitedColor;

    if (compact) {
      // Na odzoomované mapě se ikona nevykreslí čitelně, takže navštívené
      // odlišuje velikost. Barva sama by na zeleném podkladu nestačila.
      final size = visited ? 13.0 : 9.0;
      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: visited ? 2.5 : 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 2),
            ],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.amber : Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          // Fajfka u navštívených, oko u zbytku. Rozdíl je tak v **tvaru**,
          // ne jen v barvě — čitelné i na slunci a pro toho, kdo zelenou
          // od šedé rozliší hůř.
          child: Icon(
            visited ? Icons.check : Icons.visibility,
            size: visited ? 18 : 15,
            color: Colors.white,
            weight: visited ? 900 : null,
          ),
        ),
        // Opakované návštěvy jsou na mapě vidět rovnou — Kleť se sedmi
        // návštěvami se nemá schovávat za stejný puntík jako jednorázovka.
        if (visitCount > 1)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: visitedColor, width: 1),
              ),
              child: Text(
                '${visitCount}x',
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: visitedColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
