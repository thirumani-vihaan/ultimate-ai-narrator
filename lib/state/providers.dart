import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/sound_effects.dart';
import '../haptics/haptics.dart';
import '../narration/narrator.dart';
import '../settings/settings_store.dart';
import '../story/story_generator.dart';
import '../story/story_models.dart';
import 'app_phase.dart';
import 'mute_notifier.dart';
import 'quiz_controller.dart';
import 'quiz_state.dart';
import 'story_controller.dart';

/// Injectable seams. All MUST be overridden — in `main.dart`
/// (`buildRealOverrides`) for production, or in tests with fakes. They throw by
/// default so a missing wire fails loudly instead of silently doing nothing.
final Provider<Narrator> narratorProvider = Provider<Narrator>((ref) {
  throw UnimplementedError(
    'narratorProvider must be overridden (see main.dart / tests).',
  );
});

final Provider<Haptics> hapticsProvider = Provider<Haptics>((ref) {
  throw UnimplementedError(
    'hapticsProvider must be overridden (see main.dart / tests).',
  );
});

/// Turns a child's choices into a personalised story + quiz. Defaults to the
/// on-device engine (no key); `main.dart` upgrades it to the real LLM when a key
/// is present (with the on-device engine as fallback).
final Provider<StoryGenerator> storyGeneratorProvider =
    Provider<StoryGenerator>((ref) => const TemplateStoryGenerator());

/// The currently active generated story (null → show the "create story" flow).
final StateProvider<StoryPackage?> activeStoryProvider =
    StateProvider<StoryPackage?>((ref) => null);

/// True while a story is being generated (drives the "conjuring" loading state).
final StateProvider<bool> generatingProvider = StateProvider<bool>((ref) => false);

/// Persistent settings store. Defaults to in-memory (tests); `main.dart`
/// overrides it with the shared_preferences-backed implementation.
final Provider<SettingsStore> settingsStoreProvider =
    Provider<SettingsStore>((ref) => InMemorySettingsStore());

/// Whether UI sound effects are muted (persisted across launches).
final StateNotifierProvider<MuteNotifier, bool> muteProvider =
    StateNotifierProvider<MuteNotifier, bool>(
  (ref) => MuteNotifier(ref.watch(settingsStoreProvider)),
);

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

/// Owns quiz state; sourced from the active generated story's questions.
final StateNotifierProvider<QuizController, QuizState> quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  final haptics = ref.watch(hapticsProvider);
  final package = ref.watch(activeStoryProvider);
  final controller = QuizController(haptics);
  if (package != null) controller.setQuestions(package.quiz);
  return controller;
});
