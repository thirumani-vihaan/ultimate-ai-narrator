import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// Confetti burst for the correct-answer celebration. Particle count is
/// intentionally capped (14) and the whole thing is wrapped in a
/// [RepaintBoundary] to protect the ~60fps budget on mid-range devices. The
/// controller is disposed to avoid leaks.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.active});

  final bool active;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.active) _controller.play();
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 14,
            maxBlastForce: 18,
            minBlastForce: 6,
            gravity: 0.25,
            emissionFrequency: 0.05,
            colors: const <Color>[
              PebloColors.primary,
              PebloColors.accent,
              PebloColors.mint,
              PebloColors.sky,
              PebloColors.coral,
            ],
          ),
        ),
      ),
    );
  }
}
