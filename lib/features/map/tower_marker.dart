import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../towers/tower_colors.dart';
import 'tower_glyph.dart';

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
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
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
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          // Fajfka u navštívených, silueta rozhledny u zbytku. Rozdíl je tak
          // v **tvaru**, ne jen v barvě — čitelné i na slunci a pro toho, kdo
          // zelenou od šedé rozliší hůř.
          child: visited
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.white,
                  weight: 900,
                )
              : const TowerGlyph(size: 14, color: Colors.white),
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

/// Velikost samotné značky bez jmenovky.
const markerSize = 34.0;

/// Rozměry jmenovky v pixelech. Sdílí je rozvržení značky i výběr, které
/// jmenovky se na mapu vejdou — kdyby se rozešly, texty by se buď zbytečně
/// skrývaly, nebo naopak překrývaly.
///
/// Výška počítá se dvěma řádky textu (2 × 13,8 px) a svislým odsazením
/// plošky; zbytek je rezerva, aby se text neuštípl při větším systémovém
/// písmu.
const labelWidth = 135.0;
const labelHeight = 34.0;

/// Značka rozhledny pro mapovou vrstvu, případně i s jmenovkou pod ní.
///
/// Skládá se tady, a ne v mapové obrazovce, kvůli kotvě: bod na mapě musí
/// sedět na středu ikony, a ten přepočet stojí a padá s rozměry značky.
Marker towerMarker({
  required LatLng point,
  required int visitCount,
  required bool compact,
  required bool selected,
  required bool rotate,
  required VoidCallback onTap,
  String? label,
}) {
  final width = label == null ? markerSize : labelWidth;
  final height = label == null ? markerSize : markerSize + labelHeight;

  return Marker(
    point: point,
    width: width,
    height: height,
    // Na souřadnici musí sedět střed ikony, ne střed celé značky — s
    // jmenovkou pod ní by jinak puntík vyskočil kus nad rozhlednu.
    alignment: Marker.computePixelAlignment(
      width: width,
      height: height,
      left: width / 2,
      top: markerSize / 2,
    ),
    rotate: rotate,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: onTap,
            child: TowerMarker(
              visitCount: visitCount,
              compact: compact,
              selected: selected,
            ),
          ),
        ),
        // Jmenovka nesmí brát klepnutí. Značka je 28 px, ale s textem by se
        // citlivá plocha roztáhla na 116 a detail by se otevíral i tam, kam
        // uživatel mířil na mapu pod ní.
        if (label != null)
          IgnorePointer(
            child: SizedBox(
              width: labelWidth,
              height: labelHeight,
              child: TowerLabel(name: label),
            ),
          ),
      ],
    ),
  );
}

/// Jmenovka rozhledny pod značkou.
///
/// Text s bílým obrysem se nad turistickou mapou v terénu nedal přečíst —
/// vrstevnice a lesní plochy pod písmeny je rozbíjely. Krytá ploška je proti
/// mapě mnohem klidnější; hraje si za to o jeden řádek víc.
///
/// Ploška je světlá napevno, i v tmavém motivu: podkladová mapa je světlá
/// vždycky, takže tmavý štítek z motivu aplikace by na ní byl cizí prvek.
class TowerLabel extends StatelessWidget {
  const TowerLabel({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Align(
      // Nahoře, ne na střed: jednořádková jmenovka je nižší než vyhrazené
      // místo a vycentrovaná by se od značky odlepila.
      alignment: Alignment.topCenter,
      // Obal se drží textu, ať krátké jméno nezabírá plnou šířku značky
      // a nezakrývá kus mapy zbytečně.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          // Stav rozhledny nese značka tvarem i barvou, text ne.
          style: const TextStyle(
            fontSize: 12,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
      ),
    );
  }
}

/// Vybere značky, které dostanou jmenovku, aby si texty navzájem nestínily.
///
/// [points] jsou pozice v pixelech aktuálního zoomu. Ze dvojice, která by se
/// překryla, si jméno nechá jen jedna. Rozhoduje pořadí podle `uuid`, ne podle
/// výřezu — jinak by jmenovka přeskakovala mezi sousedy při každém posunu
/// mapy a text by blikal.
Set<String> labelledMarkers(List<({String uuid, Offset pixel})> points) {
  final ordered = [...points]..sort((a, b) => a.uuid.compareTo(b.uuid));
  final kept = <Offset>[];
  final result = <String>{};

  for (final p in ordered) {
    // Vodorovně stačí část šířky: většina jmen je kratší než celé pole,
    // takže plná šířka by schovávala i jmenovky, které se vedle sebe vejdou.
    final clashes = kept.any(
      (o) =>
          (o.dx - p.pixel.dx).abs() < labelWidth * 0.6 &&
          (o.dy - p.pixel.dy).abs() < labelHeight + 8,
    );
    if (clashes) continue;
    kept.add(p.pixel);
    result.add(p.uuid);
  }
  return result;
}
