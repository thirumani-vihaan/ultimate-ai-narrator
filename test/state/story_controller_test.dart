import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/narration/narrator.dart';
import 'package:ultimate_ai_narrator/state/app_phase.dart';
import 'package:ultimate_ai_narrator/state/story_controller.dart';

import '../support/fakes.dart';

const String kStory = 'Once upon a test tale, a merry little test.';

Future<void> tick([int ms = 2]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late ManualNarrator narrator;
  late StoryController controller;

  setUp(() {
    narrator = ManualNarrator();
    controller = StoryController(
      narrator,
      revealDelay: const Duration(milliseconds: 5),
    );
  });

  tearDown(() {
    controller.dispose();
    narrator.dispose();
  });

  test('starts idle', () {
    expect(controller.currentPhase, isA<PhaseIdle>());
  });

  test('readStory → preparing and calls speak with the story text', () {
    controller.readStory(kStory);
    expect(controller.currentPhase, isA<PhasePreparing>());
    expect(narrator.speakCalls, <String>[kStory]);
  });

  test('happy path: preparing → narrating → revealing → quiz', () async {
    controller.readStory(kStory);

    narrator.emit(const NarrationSpeaking());
    await tick();
    expect(controller.currentPhase, isA<PhaseNarrating>());

    narrator.emit(const NarrationCompleted());
    await tick();
    expect(controller.currentPhase, isA<PhaseRevealing>());

    await tick(15); // let the reveal timer fire
    expect(controller.currentPhase, isA<PhaseQuiz>());
  });

  test('duplicate/late completion does not double-advance past quiz', () async {
    controller.readStory(kStory);
    narrator.emit(const NarrationSpeaking());
    await tick();
    narrator.emit(const NarrationCompleted());
    await tick(15);
    expect(controller.currentPhase, isA<PhaseQuiz>());

    // A second, late completion event must be ignored.
    narrator.emit(const NarrationCompleted());
    await tick();
    expect(controller.currentPhase, isA<PhaseQuiz>());
  });

  test('error while preparing → PhaseError, then retry re-speaks', () async {
    controller.readStory(kStory);
    narrator.emit(const NarrationError('no sound'));
    await tick();
    expect(controller.currentPhase, isA<PhaseError>());
    expect((controller.currentPhase as PhaseError).message, 'no sound');

    controller.retry();
    expect(controller.currentPhase, isA<PhasePreparing>());
    expect(narrator.speakCalls, hasLength(2));
  });

  test('markSolved only transitions from quiz', () async {
    // Not in quiz yet → no-op.
    controller.markSolved();
    expect(controller.currentPhase, isA<PhaseIdle>());

    controller.readStory(kStory);
    narrator.emit(const NarrationSpeaking());
    await tick();
    narrator.emit(const NarrationCompleted());
    await tick(15);
    expect(controller.currentPhase, isA<PhaseQuiz>());

    controller.markSolved();
    expect(controller.currentPhase, isA<PhaseSuccess>());
  });

  test('stopReading from narrating returns to idle and stops the narrator',
      () async {
    controller.readStory(kStory);
    narrator.emit(const NarrationSpeaking());
    await tick();
    expect(controller.currentPhase, isA<PhaseNarrating>());

    controller.stopReading();
    expect(controller.currentPhase, isA<PhaseIdle>());
    expect(narrator.stopCalls, 1);
  });

  test('watchdog reveals the quiz even if completion never fires', () async {
    // A dedicated controller with a tiny watchdog window.
    final n = ManualNarrator();
    final c = StoryController(
      n,
      revealDelay: const Duration(milliseconds: 5),
      watchdogOverride: const Duration(milliseconds: 10),
    );
    addTearDown(() {
      c.dispose();
      n.dispose();
    });

    c.readStory(kStory);
    n.emit(const NarrationSpeaking());
    await tick();
    expect(c.currentPhase, isA<PhaseNarrating>());

    // No completion event is ever emitted; the watchdog must reveal the quiz.
    await tick(30);
    expect(c.currentPhase, isA<PhaseQuiz>());
  });
}
