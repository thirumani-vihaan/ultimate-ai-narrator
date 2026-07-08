import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/peblo_theme.dart';
import '../../quiz/quiz_models.dart';
import '../../state/quiz_state.dart';
import 'option_tile.dart';

/// Renders the quiz **entirely from data**. It draws `question.options.length`
/// tiles, so a backend payload with 3, 4 or 5 options works with no code change.
/// A wrong answer shakes the tapped tile; the shake is triggered by a change in
/// [QuizState.shakeToken] (state → animation, never an imperative call).
class QuizPanel extends StatefulWidget {
  const QuizPanel({super.key, required this.state, required this.onAnswer});

  final QuizState state;
  final ValueChanged<String> onAnswer;

  @override
  State<QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<QuizPanel>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void didUpdateWidget(QuizPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.shakeToken != oldWidget.state.shakeToken) {
      _shake.forward(from: 0);
    }
    // Re-run the entrance stagger when the question changes.
    if (widget.state.index != oldWidget.state.index) {
      _entry.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _entry.dispose();
    super.dispose();
  }

  double _shakeOffset() {
    final t = _shake.value;
    if (t == 0) return 0;
    // Damped oscillation — settles smoothly instead of stopping abruptly.
    return (1 - t) * 18 * math.sin(t * math.pi * 5);
  }

  OptionVisual _visualFor(String option, Question question) {
    final s = widget.state;
    if (s.status == QuizStatus.solved) {
      return option == question.answer
          ? OptionVisual.correct
          : OptionVisual.dimmed;
    }
    if (s.status == QuizStatus.wrong && s.lastSelected == option) {
      return OptionVisual.wrong;
    }
    return OptionVisual.normal;
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.state.current;
    if (question == null) return const SizedBox.shrink();
    final solved = widget.state.status == QuizStatus.solved;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          question.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: PebloColors.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        // Data-driven: exactly one tile per option, whatever the count.
        ...List<Widget>.generate(question.options.length, (i) {
          final option = question.options[i];
          final tile = OptionTile(
            index: i,
            label: option,
            visual: _visualFor(option, question),
            onTap: solved ? null : () => widget.onAnswer(option),
          );
          final isShaking = widget.state.status == QuizStatus.wrong &&
              widget.state.lastSelected == option;

          Widget child = tile;
          if (isShaking) {
            child = AnimatedBuilder(
              animation: _shake,
              builder: (context, inner) => Transform.translate(
                offset: Offset(_shakeOffset(), 0),
                child: inner,
              ),
              child: child,
            );
          }
          // Staggered fade + slide-up entrance.
          child = AnimatedBuilder(
            animation: _entry,
            builder: (context, inner) {
              final start = (i * 0.12).clamp(0.0, 0.6);
              final t = Interval(start, 1.0, curve: Curves.easeOut)
                  .transform(_entry.value);
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 14),
                  child: inner,
                ),
              );
            },
            child: child,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          );
        }),
        if (widget.state.status == QuizStatus.wrong)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Not quite — give it another try! 💪',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: PebloColors.coral,
              ),
            ),
          ),
      ],
    );
  }
}
