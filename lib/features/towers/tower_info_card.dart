import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/database.dart';

/// Fotka a popis rozhledny z Wikipedie a Wikimedia Commons.
///
/// Data jsou zabalená v assetu (generuje `tools/fetch_wiki.dart`), takže text
/// funguje i bez signálu. Fotka se stahuje na vyžádání a zůstává v cache;
/// hromadné přednačtení je v Nastavení.
///
/// Rozhledna bez shody (341 z 672) nezobrazí nic — žádné prázdné místo
/// ani omluvná hláška.
class TowerInfoCard extends StatelessWidget {
  const TowerInfoCard({super.key, required this.tower});

  final Tower tower;

  bool get _hasAnything =>
      tower.photoUrl != null || tower.wikipediaExtract != null;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnything) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tower.photoUrl != null) _Photo(tower: tower),
        if (tower.wikipediaExtract != null) ...[
          const SizedBox(height: 12),
          Text(tower.wikipediaExtract!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          if (tower.wikipediaUrl != null)
            InkWell(
              onTap: () => _open(tower.wikipediaUrl!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Celý článek na Wikipedii',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new,
                        size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 4),
        _Attribution(tower: tower),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.tower});

  final Tower tower;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: GestureDetector(
          onTap: tower.photoPageUrl == null
              ? null
              : () => _open(tower.photoPageUrl!),
          child: CachedNetworkImage(
            imageUrl: tower.photoUrl!,
            fit: BoxFit.cover,
            placeholder: (context, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            // Bez signálu a bez cache se místo fotky ukáže decentní ikona,
            // ne křiklavá chyba — na výletě to není nic, co by se dalo řešit.
            errorWidget: (context, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.image_not_supported_outlined,
                  color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}

/// Atribuce není ozdoba: Commons u těchto snímků hlásí `AttributionRequired`
/// a text z Wikipedie je CC BY-SA. Bez uvedení autora a licence by šlo
/// o porušení licence, takže se vykresluje vždy, když se zobrazuje obsah.
class _Attribution extends StatelessWidget {
  const _Attribution({required this.tower});

  final Tower tower;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.outline, fontSize: 11);
    final linkStyle = style?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    final parts = <Widget>[];

    if (tower.photoUrl != null && tower.photoAuthor != null) {
      parts.add(Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Foto: ${tower.photoAuthor}, ', style: style),
          GestureDetector(
            onTap: tower.photoLicenseUrl == null
                ? null
                : () => _open(tower.photoLicenseUrl!),
            child: Text(tower.photoLicense ?? '', style: linkStyle),
          ),
          Text(' · Wikimedia Commons', style: style),
        ],
      ));
    }

    if (tower.wikipediaExtract != null) {
      parts.add(Text('Text: Wikipedie, CC BY-SA', style: style));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in parts)
          Padding(padding: const EdgeInsets.only(top: 2), child: p),
      ],
    );
  }
}

Future<void> _open(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
