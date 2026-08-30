import 'package:flutter/material.dart';

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

  static const _visited = Color(0xFF2E7D32);
  static const _unvisited = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final color = visitCount > 0 ? _visited : _unvisited;

    if (compact) {
      return Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
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
          child: const Icon(Icons.visibility, size: 15, color: Colors.white),
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
                border: Border.all(color: _visited, width: 1),
              ),
              child: Text(
                '${visitCount}x',
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: _visited,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
