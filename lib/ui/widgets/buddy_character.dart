import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';

/// Pip the Robot's mood, driven by the app phase.
enum BuddyMood { idle, talking, thinking, happy }

/// A lightweight, fully vector (no image assets) buddy character. Drawn with a
/// [CustomPainter] so it scales crisply and stays tiny in memory — important for
/// the mid-range-device budget. A gentle bounce conveys "talking" / "happy".
class BuddyCharacter extends StatefulWidget {
  const BuddyCharacter({super.key, required this.mood, this.size = 150});

  final BuddyMood mood;
  final double size;

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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
          final active =
              widget.mood == BuddyMood.talking || widget.mood == BuddyMood.happy;
          final bounce = active ? _controller.value * 6 : 0.0;
          return Transform.translate(offset: Offset(0, -bounce), child: child);
        },
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _PipPainter(mood: widget.mood),
        ),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  _PipPainter({required this.mood});

  final BuddyMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..style = PaintingStyle.fill;

    // Antenna.
    final antenna = Paint()
      ..color = PebloColors.primaryDark
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.17),
      Offset(w * 0.5, h * 0.04),
      antenna,
    );
    fill.color = PebloColors.accent;
    canvas.drawCircle(Offset(w * 0.5, h * 0.04), w * 0.05, fill);

    // Head.
    fill.color = PebloColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.17, w * 0.76, h * 0.62),
        Radius.circular(w * 0.16),
      ),
      fill,
    );

    // Face screen.
    fill.color = PebloColors.cream;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.27, w * 0.6, h * 0.42),
        Radius.circular(w * 0.1),
      ),
      fill,
    );

    // Eyes.
    final eyeY = h * 0.43;
    final eyeR = w * 0.055;
    if (mood == BuddyMood.happy) {
      final eye = Paint()
        ..color = PebloColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.38, eyeY), radius: eyeR * 1.4),
        3.6,
        2.2,
        false,
        eye,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.62, eyeY), radius: eyeR * 1.4),
        3.6,
        2.2,
        false,
        eye,
      );
    } else {
      fill.color = PebloColors.ink;
      canvas.drawCircle(Offset(w * 0.38, eyeY), eyeR, fill);
      canvas.drawCircle(Offset(w * 0.62, eyeY), eyeR, fill);
    }

    // Mouth.
    final cx = w * 0.5;
    final my = h * 0.57;
    switch (mood) {
      case BuddyMood.talking:
        fill.color = PebloColors.coral;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, my),
            width: w * 0.18,
            height: h * 0.1,
          ),
          fill,
        );
      case BuddyMood.happy:
        fill.color = PebloColors.coral;
        final smile = Path()
          ..moveTo(w * 0.36, my)
          ..quadraticBezierTo(cx, my + h * 0.12, w * 0.64, my)
          ..close();
        canvas.drawPath(smile, fill);
      case BuddyMood.thinking:
        final line = Paint()
          ..color = PebloColors.ink
          ..strokeWidth = w * 0.025
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.43, my), Offset(w * 0.57, my), line);
      case BuddyMood.idle:
        final line = Paint()
          ..color = PebloColors.coral
          ..strokeWidth = w * 0.03
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final smile = Path()
          ..moveTo(w * 0.42, my)
          ..quadraticBezierTo(cx, my + h * 0.05, w * 0.58, my);
        canvas.drawPath(smile, line);
    }

    // Happy cheeks.
    if (mood == BuddyMood.happy) {
      fill.color = PebloColors.coral.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(w * 0.3, h * 0.51), w * 0.04, fill);
      canvas.drawCircle(Offset(w * 0.7, h * 0.51), w * 0.04, fill);
    }
  }

  @override
  bool shouldRepaint(_PipPainter oldDelegate) => oldDelegate.mood != mood;
}
