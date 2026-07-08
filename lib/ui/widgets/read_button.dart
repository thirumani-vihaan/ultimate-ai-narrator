import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// The big, friendly "Read Me a Story" call to action. Shows a spinner + a
/// reassuring label while audio is being prepared.
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
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: PebloColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PebloColors.primary.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          elevation: 6,
        ),
        icon: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.volume_up_rounded, size: 28),
        label: Text(busy ? 'Warming up my voice…' : label),
      ),
    );
  }
}
