import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// Pip the Robot's mood, driven by the app phase.
enum BuddyMood { idle, talking, thinking, happy }

/// A lightweight, fully vector (no image assets) buddy with real depth —
/// gradient shell, soft ground shadow, glossy face, catchlit eyes and a glowing
/// antenna. Drawn with a [CustomPainter] so it stays tiny in memory and scales
/// crisply, which matters for the mid-range-device budget. A gentle bob conveys
/// "talking" / "happy".
class BuddyCharacter extends StatefulWidget {
  const BuddyCharacter({
    super.key,
    required this.mood,
    this.size = 172,
    this.reduceMotion = false,
  });

  final BuddyMood mood;
  final double size;
  final bool reduceMotion;

  @override
  State<BuddyCharacter> createState() => _BuddyCharacterState();
}

class _BuddyCharacterState extends State<BuddyCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (!widget.reduceMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(BuddyCharacter oldWidget) {
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Smooth sine bob over the loop.
          final wave = 0.5 - 0.5 * math.cos(_controller.value * 2 * math.pi);
          final talking = widget.mood == BuddyMood.talking;
          final active = !widget.reduceMotion &&
              (talking || widget.mood == BuddyMood.happy);
          final bob = active ? wave * (widget.size * 0.03) : 0.0;
          final mouthOpen = (talking && !widget.reduceMotion)
              ? (0.5 - 0.5 * math.cos(_controller.value * 4 * math.pi))
              : 0.0;
          // Brief blink near the end of each loop.
          final blink = !widget.reduceMotion && _controller.value > 0.93;
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _PipPainter(
              mood: widget.mood,
              mouthOpen: mouthOpen,
              bob: bob,
              blink: blink,
            ),
          );
        },
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({
    required this.mood,
    this.mouthOpen = 0.0,
    this.bob = 0.0,
    this.blink = false,
  });

  final BuddyMood mood;
  final double mouthOpen;
  final double bob;
  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground shadow (stays put while the body bobs).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.95),
        width: w * 0.46,
        height: h * 0.07,
      ),
      Paint()
        ..color = PebloColors.primaryDark.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.save();
    canvas.translate(0, -bob);

    // Antenna + glowing bulb.
    final antenna = Paint()
      ..color = PebloColors.primaryDark
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.18),
      Offset(w * 0.5, h * 0.05),
      antenna,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.05),
      w * 0.09,
      Paint()..color = PebloColors.accent.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.05),
      w * 0.048,
      Paint()..color = PebloColors.accent,
    );
    canvas.drawCircle(
      Offset(w * 0.485, h * 0.035),
      w * 0.016,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Side "ear" bolts.
    final bolt = Paint()..color = PebloColors.primaryDark;
    for (final dx in <double>[0.10, 0.90]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * dx, h * 0.46),
            width: w * 0.09,
            height: h * 0.14,
          ),
          Radius.circular(w * 0.03),
        ),
        bolt,
      );
    }

    // Head shell with vertical gradient + soft drop shadow.
    final headRect = Rect.fromLTWH(w * 0.14, h * 0.17, w * 0.72, h * 0.60);
    final headRRect =
        RRect.fromRectAndRadius(headRect, Radius.circular(w * 0.20));
    canvas.drawRRect(
      headRRect.shift(Offset(0, h * 0.02)),
      Paint()
        ..color = PebloColors.primaryDark.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      headRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF8B6DFF), PebloColors.primaryDark],
        ).createShader(headRect),
    );

    // Glossy face screen.
    final faceRect = Rect.fromLTWH(w * 0.22, h * 0.27, w * 0.56, h * 0.40);
    final faceRRect =
        RRect.fromRectAndRadius(faceRect, Radius.circular(w * 0.12));
    canvas.drawRRect(faceRRect, Paint()..color = const Color(0xFF17123A));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        faceRect.deflate(w * 0.015),
        Radius.circular(w * 0.10),
      ),
      Paint()..color = PebloColors.cream,
    );
    // Top shine on the face.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.29, w * 0.52, h * 0.10),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    _drawFace(canvas, w, h);

    canvas.restore();
  }

  void _drawFace(Canvas canvas, double w, double h) {
    final eyeY = h * 0.44;
    final eyeR = w * 0.058;
    final fill = Paint()..style = PaintingStyle.fill;

    if (mood == BuddyMood.happy) {
      final eye = Paint()
        ..color = PebloColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawArc(
          Rect.fromCircle(center: Offset(w * 0.38, eyeY), radius: eyeR * 1.4),
          3.6,
          2.2,
          false,
          eye,
        )
        ..drawArc(
          Rect.fromCircle(center: Offset(w * 0.62, eyeY), radius: eyeR * 1.4),
          3.6,
          2.2,
          false,
          eye,
        );
    } else if (blink) {
      // Closed eyes — two short horizontal lines.
      final lid = Paint()
        ..color = PebloColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(
          Offset(w * 0.33, eyeY),
          Offset(w * 0.43, eyeY),
          lid,
        )
        ..drawLine(
          Offset(w * 0.57, eyeY),
          Offset(w * 0.67, eyeY),
          lid,
        );
    } else {
      fill.color = PebloColors.ink;
      canvas
        ..drawCircle(Offset(w * 0.38, eyeY), eyeR, fill)
        ..drawCircle(Offset(w * 0.62, eyeY), eyeR, fill);
      // Catchlights bring the eyes to life.
      final light = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas
        ..drawCircle(Offset(w * 0.365, eyeY - eyeR * 0.35), eyeR * 0.32, light)
        ..drawCircle(Offset(w * 0.605, eyeY - eyeR * 0.35), eyeR * 0.32, light);
    }

    final cx = w * 0.5;
    final my = h * 0.57;
    switch (mood) {
      case BuddyMood.talking:
        fill.color = PebloColors.coral;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, my),
              width: w * 0.16,
              height: h * (0.03 + 0.07 * mouthOpen),
            ),
            Radius.circular(w * 0.03),
          ),
          fill,
        );
      case BuddyMood.happy:
        fill.color = PebloColors.coral;
        final smile = Path()
          ..moveTo(w * 0.37, my - h * 0.01)
          ..quadraticBezierTo(cx, my + h * 0.11, w * 0.63, my - h * 0.01)
          ..quadraticBezierTo(cx, my + h * 0.05, w * 0.37, my - h * 0.01)
          ..close();
        canvas.drawPath(smile, fill);
      case BuddyMood.thinking:
        final line = Paint()
          ..color = PebloColors.ink
          ..strokeWidth = w * 0.028
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.44, my), Offset(w * 0.56, my), line);
      case BuddyMood.idle:
        final line = Paint()
          ..color = PebloColors.coral
          ..strokeWidth = w * 0.032
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final smile = Path()
          ..moveTo(w * 0.42, my)
          ..quadraticBezierTo(cx, my + h * 0.055, w * 0.58, my);
        canvas.drawPath(smile, line);
    }

    if (mood == BuddyMood.happy) {
      final cheek = Paint()..color = PebloColors.coral.withValues(alpha: 0.35);
      canvas
        ..drawCircle(Offset(w * 0.31, h * 0.52), w * 0.042, cheek)
        ..drawCircle(Offset(w * 0.69, h * 0.52), w * 0.042, cheek);
    }
  }

  @override
  bool shouldRepaint(_PipPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.mouthOpen != mouthOpen ||
      oldDelegate.bob != bob ||
      oldDelegate.blink != blink;
}
