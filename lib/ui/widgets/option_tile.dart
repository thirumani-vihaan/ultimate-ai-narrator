import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// Visual state of a single answer tile.
enum OptionVisual { normal, wrong, correct, dimmed }

/// One tappable answer. Big, high-contrast, with a playful leading emoji and a
/// large tap target (min 60dp) suited to small fingers.
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

  static const List<String> _emojis = <String>[
    '🍎',
    '🌿',
    '💧',
    '⭐',
    '🌸',
    '🚀',
    '🎈',
    '🐣',
  ];

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg}) colors = switch (visual) {
      OptionVisual.correct => (bg: PebloColors.mint, fg: Colors.white),
      OptionVisual.wrong => (bg: PebloColors.coral, fg: Colors.white),
      OptionVisual.dimmed => (
          bg: PebloColors.cloud,
          fg: PebloColors.ink.withValues(alpha: 0.4),
        ),
      OptionVisual.normal => (bg: PebloColors.cloud, fg: PebloColors.ink),
    };

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
        elevation: visual == OptionVisual.normal ? 3 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: <Widget>[
                Text(
                  _emojis[index % _emojis.length],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.fg,
                    ),
                  ),
                ),
                if (visual == OptionVisual.correct)
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                if (visual == OptionVisual.wrong)
                  const Icon(Icons.close_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
