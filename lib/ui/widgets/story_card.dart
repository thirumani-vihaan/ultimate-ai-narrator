import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/peblo_theme.dart';
import '../../state/providers.dart';

/// The narrative card. Gently highlights while narrating, and — when the active
/// narrator reports progress — colours the words as they are spoken (with a
/// graceful fallback to plain text when progress isn't available, e.g. on web).
class StoryCard extends ConsumerWidget {
  const StoryCard({super.key, required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  static const TextStyle _base = TextStyle(
    fontSize: 20,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: PebloColors.ink,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var spokenChars = 0;
    if (highlighted) {
      final progress = ref.watch(narrationProgressProvider);
      spokenChars = progress
          .maybeWhen(data: (v) => v, orElse: () => 0)
          .clamp(0, text.length)
          .toInt();
    }

    final Widget body = spokenChars > 0
        ? RichText(
            text: TextSpan(
              style: _base,
              children: <TextSpan>[
                TextSpan(
                  text: text.substring(0, spokenChars),
                  style: const TextStyle(
                    color: PebloColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: text.substring(spokenChars)),
              ],
            ),
          )
        : Text(text, style: _base);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.white, Color(0xFFFFFDF8)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: highlighted
              ? PebloColors.accent
              : PebloColors.primary.withValues(alpha: 0.06),
          width: highlighted ? 2.5 : 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: PebloColors.primary.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: PebloColors.accent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '📖 Storytime',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A6A00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}
