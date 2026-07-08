import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// A soft, cheerful sky behind the content: a vertical gradient plus a few
/// slowly drifting clouds. Kept deliberately cheap (3 cloud blobs, one slow
/// controller, wrapped in a `RepaintBoundary`) to protect the 60 fps budget,
/// and fully static when reduced-motion is requested.
class SkyBackground extends StatefulWidget {
  const SkyBackground({super.key, required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    if (!widget.reduceMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(SkyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFD9F1FF), PebloColors.cream],
            stops: <double>[0.0, 0.55],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _CloudsPainter(t: _controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _CloudsPainter extends CustomPainter {
  _CloudsPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    // Three clouds at different heights/speeds, wrapping around horizontally.
    _cloud(canvas, size, paint, baseY: 0.12, phase: t, scale: 1.0);
    _cloud(canvas, size, paint, baseY: 0.24, phase: (t + 0.5) % 1.0, scale: 0.7);
    _cloud(canvas, size, paint, baseY: 0.06, phase: (t + 0.8) % 1.0, scale: 0.5);
  }

  void _cloud(
    Canvas canvas,
    Size size,
    Paint paint, {
    required double baseY,
    required double phase,
    required double scale,
  }) {
    final w = size.width;
    final h = size.height;
    // Travel from off-left to off-right.
    final x = -0.2 * w + phase * (w * 1.4);
    final y = h * baseY;
    final r = w * 0.06 * scale;
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + r, y + r * 0.2), r * 1.2, paint);
    canvas.drawCircle(Offset(x + r * 2.1, y), r * 0.9, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, r * 2.1, r * 1.2),
        Radius.circular(r),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CloudsPainter oldDelegate) => oldDelegate.t != t;
}
