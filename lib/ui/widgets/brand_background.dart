import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// The app's signature **story-agnostic** backdrop: a soft gradient with a warm
/// focal glow behind the hero and a scattering of gentle sparkles + a couple of
/// very faint drifting blobs. Intentionally restrained so it reads as "designed"
/// rather than busy — and never tied to a particular story.
///
/// [palette] is a parameter so a story *could* theme the scenery from its own
/// data; it defaults to the Peblo brand colours. Cheap by design and fully
/// static under reduced-motion.
class BrandBackground extends StatefulWidget {
  const BrandBackground({
    super.key,
    required this.reduceMotion,
    this.palette = _brand,
  });

  final bool reduceMotion;
  final List<Color> palette;

  static const List<Color> _brand = <Color>[
    PebloColors.primary,
    PebloColors.sky,
    PebloColors.mint,
  ];

  @override
  State<BrandBackground> createState() => _BrandBackgroundState();
}

class _BrandBackgroundState extends State<BrandBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    if (!widget.reduceMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(BrandBackground oldWidget) {
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
            colors: <Color>[Color(0xFFF1ECFF), Color(0xFFFFF7EC)],
            stops: <double>[0.0, 0.7],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _BackdropPainter(
              t: _controller.value,
              palette: widget.palette,
              reduceMotion: widget.reduceMotion,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.t,
    required this.palette,
    required this.reduceMotion,
  });

  final double t;
  final List<Color> palette;
  final bool reduceMotion;

  // Faint drifting blobs: baseX, baseY, radius(frac w), drift, phase, colorIdx.
  static const List<List<double>> _blobs = <List<double>>[
    <double>[0.16, 0.32, 0.34, 0.03, 0.0, 0],
    <double>[0.86, 0.54, 0.30, 0.03, 0.5, 1],
    <double>[0.60, 0.86, 0.32, 0.025, 0.8, 2],
  ];

  static const List<List<double>> _sparkles = <List<double>>[
    <double>[0.14, 0.16, 0.0],
    <double>[0.30, 0.40, 0.5],
    <double>[0.72, 0.22, 0.2],
    <double>[0.86, 0.44, 0.8],
    <double>[0.22, 0.62, 0.35],
    <double>[0.52, 0.72, 0.65],
    <double>[0.80, 0.66, 0.15],
    <double>[0.40, 0.24, 0.9],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // A couple of very faint drifting blobs for gentle depth (behind glow).
    for (final b in _blobs) {
      final phase = b[4];
      final dx = reduceMotion ? 0.0 : b[3] * math.cos((t + phase) * 2 * math.pi);
      final dy = reduceMotion
          ? 0.0
          : b[3] * 0.7 * math.sin((t * 1.2 + phase) * 2 * math.pi);
      final color = palette[b[5].toInt() % palette.length];
      canvas.drawCircle(
        Offset(w * (b[0] + dx), h * (b[1] + dy)),
        w * b[2],
        Paint()..color = color.withValues(alpha: 0.06),
      );
    }

    // Warm focal glow behind the hero (upper-centre).
    final glowRect =
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.24), radius: w * 0.75);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            PebloColors.accent.withValues(alpha: 0.22),
            PebloColors.accent.withValues(alpha: 0.0),
          ],
        ).createShader(glowRect),
    );

    // Sparkles.
    for (final s in _sparkles) {
      final phase = s[2];
      final tw = reduceMotion
          ? 0.5
          : 0.3 + 0.7 * (0.5 + 0.5 * math.sin((t * 2 + phase) * 2 * math.pi));
      canvas
        ..drawCircle(
          Offset(w * s[0], h * s[1]),
          w * 0.010,
          Paint()..color = PebloColors.accent.withValues(alpha: 0.18 * tw),
        )
        ..drawCircle(
          Offset(w * s[0], h * s[1]),
          w * 0.004,
          Paint()..color = PebloColors.accent.withValues(alpha: tw),
        );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.reduceMotion != reduceMotion;
}
