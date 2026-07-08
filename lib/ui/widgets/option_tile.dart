import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';
import 'pressable.dart';

/// Visual state of a single answer tile.
enum OptionVisual { normal, wrong, correct, dimmed }

/// One tappable answer — a soft, elevated card with a colourful lettered badge
/// (A, B, C…), a press-squish, and clear correct/wrong states. The lettered
/// badge is content-agnostic (works for any story) and reads as "designed"
/// rather than a bare list item.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.index,
    required this.label,
    required this.visual,
    required this.onTap,
  });

  final int index;
  final String label;
  final OptionVisual visual;
  final VoidCallback? onTap;

  static const List<Color> _badgeColors = <Color>[
    PebloColors.primary,
    PebloColors.sky,
    PebloColors.mint,
    PebloColors.coral,
    PebloColors.accent,
    PebloColors.bubble,
  ];

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + (index % 26));
    final badgeColor = _badgeColors[index % _badgeColors.length];

    final bool solid = visual == OptionVisual.correct || visual == OptionVisual.wrong;
    final Color surface = switch (visual) {
      OptionVisual.correct => PebloColors.mint,
      OptionVisual.wrong => PebloColors.coral,
      OptionVisual.dimmed => PebloColors.cloud,
      OptionVisual.normal => PebloColors.cloud,
    };
    final Color textColor = switch (visual) {
      OptionVisual.correct || OptionVisual.wrong => Colors.white,
      OptionVisual.dimmed => PebloColors.ink.withValues(alpha: 0.35),
      OptionVisual.normal => PebloColors.ink,
    };

    return Pressable(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            gradient: solid
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white,
                      Color(0xFFF6F2FF),
                    ],
                  ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (solid ? surface : PebloColors.primary)
                    .withValues(alpha: visual == OptionVisual.dimmed ? 0.06 : 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _Badge(
                letter: letter,
                color: visual == OptionVisual.dimmed
                    ? PebloColors.ink.withValues(alpha: 0.18)
                    : (solid ? Colors.white : badgeColor),
                textColor: solid ? surface : Colors.white,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (visual == OptionVisual.correct)
                const Icon(Icons.check_circle_rounded, color: Colors.white)
              else if (visual == OptionVisual.wrong)
                const Icon(Icons.cancel_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.letter,
    required this.color,
    required this.textColor,
  });

  final String letter;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
