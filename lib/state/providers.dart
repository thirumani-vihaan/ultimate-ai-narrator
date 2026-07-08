import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_effects.dart';
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

/// Whether UI sound effects are muted. Defaults to on (not muted).
final StateProvider<bool> muteProvider = StateProvider<bool>((ref) => false);

/// Character-progress of the current narration (for word highlighting). Emits
/// nothing if the active narrator doesn't report progress (e.g. remote audio).
final StreamProvider<int> narrationProgressProvider = StreamProvider<int>((ref) {
  final narrator = ref.watch(narratorProvider);
  if (narrator is ProgressiveNarrator) {
    return (narrator as ProgressiveNarrator).spokenChars;
  }
  return const Stream<int>.empty();
});

/// UI sound effects. Defaults to silent so tests need no override; `main.dart`
/// overrides it with the real just_audio implementation.
final Provider<SoundEffects> soundEffectsProvider =
    Provider<SoundEffects>((ref) => const NoopSoundEffects());

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
