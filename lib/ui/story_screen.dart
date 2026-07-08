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
                        Center(child: BuddyCharacter(mood: mood)),
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
            child: CelebrationOverlay(active: phase is PhaseSuccess),
          ),
        ],
      ),
    );
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
          Text(
            'Shhh… Pip is reading!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: PebloColors.primaryDark,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (phase is PhaseSuccess) const _SuccessBanner(),
        QuizPanel(state: quiz, onAnswer: quizController.answer),
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
          Text(
            'Here comes a question!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: PebloColors.primaryDark,
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
          Text(
            'You did it! Great job!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
          Text('🎉', style: TextStyle(fontSize: 26)),
        ],
      ),
    );
  }
}
