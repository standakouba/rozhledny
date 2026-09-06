import 'package:flutter/material.dart';

/// Kulaté tlačítko ležící na mapě.
///
/// Vzhled je tady na jednom místě schválně: ovládací prvky nad mapou tvoří
/// jeden sloupec a kdyby si každý držel vlastní barvu a velikost, rozešly by
/// se při první úpravě. Světlá ploška místo barevného FABu proto, že mapa má
/// pod tlačítky pokaždé jinou barvu a výrazná plocha z ní dělá guláš.
class MapRoundButton extends StatelessWidget {
  const MapRoundButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.size = 44,
  });

  final String tooltip;

  /// `null` tlačítko zešedne a nereaguje — používá se, dokud nedorazí poloha.
  final VoidCallback? onPressed;

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(
                  color: onPressed == null
                      ? theme.disabledColor
                      : theme.colorScheme.onSurface,
                  size: size * 0.52,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
