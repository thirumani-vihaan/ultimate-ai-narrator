import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// The narrative card. Gently highlights while the story is being narrated.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PebloColors.cloud,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? PebloColors.accent : Colors.transparent,
          width: 3,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: PebloColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('📖', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: PebloColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
