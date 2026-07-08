import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../haptics/haptics.dart';
import '../narration/narrator.dart';
import '../quiz/quiz_repository.dart';
import 'app_phase.dart';
import 'quiz_controller.dart';
import 'quiz_state.dart';
import 'story_controller.dart';

/// Injectable seams. All three MUST be overridden — in `main.dart`
/// (`buildRealOverrides`) for production, or in tests with fakes. They throw by
/// default so a missing wire fails loudly instead of silently doing nothing.
final Provider<Narrator> narratorProvider = Provider<Narrator>((ref) {
  throw UnimplementedError(
    'narratorProvider must be overridden (see main.dart / tests).',
  );
});

final Provider<QuizRepository> quizRepositoryProvider =
    Provider<QuizRepository>((ref) {
  throw UnimplementedError(
    'quizRepositoryProvider must be overridden (see main.dart / tests).',
  );
});

final Provider<Haptics> hapticsProvider = Provider<Haptics>((ref) {
  throw UnimplementedError(
    'hapticsProvider must be overridden (see main.dart / tests).',
  );
});

/// Orchestrates narration → quiz-reveal phases.
final StateNotifierProvider<StoryController, StoryPhase> storyControllerProvider =
    StateNotifierProvider<StoryController, StoryPhase>((ref) {
  final narrator = ref.watch(narratorProvider);
  return StoryController(narrator);
});

/// Owns quiz state; kicks off loading immediately.
final StateNotifierProvider<QuizController, QuizState> quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  final haptics = ref.watch(hapticsProvider);
  return QuizController(repo, haptics)..load();
});
