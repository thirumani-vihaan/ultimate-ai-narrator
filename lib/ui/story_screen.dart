import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/peblo_theme.dart';
import '../state/app_phase.dart';
import '../state/providers.dart';
import '../state/quiz_state.dart';
import '../state/story_controller.dart';
import 'widgets/buddy_character.dart';
import 'widgets/celebration_overlay.dart';
import 'widgets/error_retry.dart';
import 'widgets/quiz_panel.dart';
import 'widgets/read_button.dart';
import 'widgets/story_card.dart';

/// The single screen: buddy + story + a bottom area that swaps between the read
/// button, loading, error/retry, and the quiz — all driven by [StoryPhase].
class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(storyControllerProvider);
    final story = ref.read(storyControllerProvider.notifier);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Bridge: when the quiz becomes solved, tell the story controller to
    // enter its celebratory Success phase (single, testable coupling point).
    ref.listen<QuizState>(quizControllerProvider, (previous, next) {
      if (next.isSolved && (previous == null || !previous.isSolved)) {
        story.markSolved();
      }
    });

    final mood = switch (phase) {
      PhaseNarrating() => BuddyMood.talking,
      PhasePreparing() || PhaseRevealing() || PhaseQuiz() => BuddyMood.thinking,
      PhaseSuccess() => BuddyMood.happy,
      PhaseIdle() || PhaseError() => BuddyMood.idle,
    };

    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _Header(),
                        const SizedBox(height: 4),
                        Center(
                          child: ExcludeSemantics(
                            child: BuddyCharacter(
                              mood: mood,
                              reduceMotion: reduceMotion,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        StoryCard(
                          text: StoryController.storyText,
                          highlighted: phase is PhaseNarrating,
                        ),
                        const SizedBox(height: 20),
                        _BottomArea(phase: phase),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: CelebrationOverlay(
              active: phase is PhaseSuccess && !reduceMotion,
            ),
          ),
          // Screen-reader live announcements (its own widget so it doesn't
          // rebuild the whole screen on quiz changes).
          const _LiveAnnouncer(),
        ],
      ),
    );
  }
}

/// Announces the current phase to assistive technologies via a live region.
class _LiveAnnouncer extends ConsumerWidget {
  const _LiveAnnouncer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(storyControllerProvider);
    final quiz = ref.watch(quizControllerProvider);
    return Semantics(
      container: true,
      liveRegion: true,
      label: _announcementFor(phase, quiz),
      child: const SizedBox.shrink(),
    );
  }

  static String _announcementFor(StoryPhase phase, QuizState quiz) {
    return switch (phase) {
      PhaseIdle() => 'Ready. Tap Read Me a Story to begin.',
      PhasePreparing() => 'Getting the story ready.',
      PhaseNarrating() => 'The story is playing.',
      PhaseRevealing() => 'Here comes a question.',
      PhaseQuiz() => 'Question ${quiz.index + 1} of ${quiz.total}.',
      PhaseSuccess() => 'Correct! Well done.',
      PhaseError(:final String message) => message,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Story Buddy',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: PebloColors.primary,
          ),
        ),
        Text(
          "Tap the button and I'll read you a story! 🎧",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: PebloColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Swaps the bottom content based on the current phase.
class _BottomArea extends ConsumerWidget {
  const _BottomArea({required this.phase});

  final StoryPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.read(storyControllerProvider.notifier);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: switch (phase) {
        PhaseIdle() => ReadButton(
            key: const ValueKey<String>('read'),
            busy: false,
            onPressed: story.readStory,
          ),
        PhasePreparing() => const ReadButton(
            key: ValueKey<String>('preparing'),
            busy: true,
            onPressed: null,
          ),
        PhaseNarrating() => const _ListeningHint(key: ValueKey<String>('hint')),
        PhaseError(:final message) => ErrorRetry(
            key: const ValueKey<String>('error'),
            message: message,
            onRetry: story.retry,
          ),
        PhaseRevealing() ||
        PhaseQuiz() ||
        PhaseSuccess() =>
          _QuizArea(key: const ValueKey<String>('quiz'), phase: phase),
      },
    );
  }
}

class _ListeningHint extends StatelessWidget {
  const _ListeningHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: PebloColors.sky.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('🔊', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Shhh… Pip is reading!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: PebloColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the quiz (or a brief reveal placeholder / load error).
class _QuizArea extends ConsumerWidget {
  const _QuizArea({super.key, required this.phase});

  final StoryPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);
    final story = ref.read(storyControllerProvider.notifier);
    final revealing = phase is PhaseRevealing;

    if (quiz.status == QuizStatus.error) {
      return ErrorRetry(
        message: quiz.errorMessage ?? 'We could not load the quiz.',
        onRetry: quizController.load,
      );
    }

    if (revealing || quiz.status == QuizStatus.loading) {
      return const _RevealPlaceholder();
    }

    final solved = phase is PhaseSuccess;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (solved) const _SuccessBanner(),
        if (solved) ...<Widget>[
          const SizedBox(height: 4),
          _StarRow(count: quiz.currentQuestionStars, max: 3, size: 30),
          const SizedBox(height: 10),
        ],
        if (quiz.total > 1) ...<Widget>[
          _QuizProgress(index: quiz.index, total: quiz.total),
          const SizedBox(height: 10),
        ],
        QuizPanel(state: quiz, onAnswer: quizController.answer),
        if (solved) ...<Widget>[
          const SizedBox(height: 16),
          if (quiz.isLastQuestion)
            _RestartButton(
              earned: quiz.totalStars,
              max: quiz.maxStars,
              onRestart: () {
                quizController.reset();
                story.readStory();
              },
            )
          else
            _NextButton(
              onNext: () {
                quizController.nextQuestion();
                story.goToQuiz();
              },
            ),
        ],
      ],
    );
  }
}

class _RevealPlaceholder extends StatelessWidget {
  const _RevealPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: PebloColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('✨', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Here comes a question!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PebloColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: PebloColors.mint,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: PebloColors.mint.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('🎉', style: TextStyle(fontSize: 26)),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'You did it! Great job!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 10),
          Text('🎉', style: TextStyle(fontSize: 26)),
        ],
      ),
    );
  }
}

/// Row of dots showing progress through the question sequence.
class _QuizProgress extends StatelessWidget {
  const _QuizProgress({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'Question ${index + 1} of $total',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: PebloColors.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == index ? 26 : 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i < index
                      ? PebloColors.mint
                      : (i == index
                          ? PebloColors.primary
                          : PebloColors.primary.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: PebloColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Next question'),
      ),
    );
  }
}

class _RestartButton extends StatelessWidget {
  const _RestartButton({
    required this.onRestart,
    required this.earned,
    required this.max,
  });

  final VoidCallback onRestart;
  final int earned;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          '🌟 You finished all the questions! 🌟',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: PebloColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You earned $earned of $max stars',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: PebloColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        _StarRow(count: earned, max: max, size: 26),
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onRestart,
            style: ElevatedButton.styleFrom(
              backgroundColor: PebloColors.accent,
              foregroundColor: PebloColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Read it again'),
          ),
        ),
      ],
    );
  }
}

/// A row of gold/empty stars, animating each filled star in with a small pop.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.count, required this.max, this.size = 28});

  final int count;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < max; i++)
          TweenAnimationBuilder<double>(
            key: ValueKey<String>('star-$i-${i < count}'),
            tween: Tween<double>(begin: i < count ? 0.0 : 1.0, end: 1.0),
            duration: Duration(milliseconds: 250 + i * 120),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: i < count ? t : 1.0, child: child),
            child: Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < count ? PebloColors.accent : PebloColors.ink.withValues(
                    alpha: 0.25,
                  ),
            ),
          ),
      ],
    );
  }
}
