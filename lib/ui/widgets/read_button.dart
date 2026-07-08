import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';
import 'pressable.dart';

/// The big, friendly primary call to action — a glossy gradient pill with a
/// press-squish. Shows a spinner + reassuring label while audio is preparing.
class ReadButton extends StatelessWidget {
  const ReadButton({
    super.key,
    required this.busy,
    required this.onPressed,
    this.label = 'Read Me a Story',
  });

  final bool busy;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy ? null : onPressed,
      child: Container(
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF8B6DFF), PebloColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(34),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: PebloColors.primary.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.auto_stories_rounded, size: 26, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                busy ? 'Getting ready…' : label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
