import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/haptics/haptics.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/state/quiz_controller.dart';
import 'package:ultimate_ai_narrator/state/quiz_state.dart';

import '../support/fakes.dart';

void main() {
  late FakeHaptics haptics;

  setUp(() => haptics = FakeHaptics());

  QuizController controllerWith(List<Question> questions) =>
      QuizController(FakeQuizRepository(questions), haptics);

  test('load populates questions and becomes ready', () async {
    final controller = controllerWith(<Question>[sampleQuestion()]);
    await controller.load();
    expect(controller.currentState.status, QuizStatus.ready);
    expect(controller.currentState.questions, hasLength(1));
    controller.dispose();
  });

  test('load failure degrades to a friendly error state', () async {
    final controller = QuizController(FailingQuizRepository(), haptics);
    await controller.load();
    expect(controller.currentState.status, QuizStatus.error);
    expect(controller.currentState.errorMessage, isNotNull);
    controller.dispose();
  });

  test('wrong answer → shake token + attempt + haptic, stays answerable',
      () async {
    final controller = controllerWith(<Question>[sampleQuestion()]);
    await controller.load();

    controller.answer('Option 1');
    final s = controller.currentState;
    expect(s.status, QuizStatus.wrong);
    expect(s.attempts, 1);
    expect(s.shakeToken, 1);
    expect(s.lastSelected, 'Option 1');
    expect(haptics.calls, contains('wrong'));
    controller.dispose();
  });

  test('correct answer → solved + celebratory haptic', () async {
    final controller = controllerWith(<Question>[sampleQuestion()]);
    await controller.load();

    controller.answer('Option 2');
    expect(controller.currentState.status, QuizStatus.solved);
    expect(haptics.calls, contains('correct'));
    controller.dispose();
  });

  test('taps after solved are ignored', () async {
    final controller = controllerWith(<Question>[sampleQuestion()]);
    await controller.load();

    controller.answer('Option 2'); // solve
    controller.answer('Option 1'); // ignored
    expect(controller.currentState.status, QuizStatus.solved);
    controller.dispose();
  });

  test('nextQuestion advances and resets per-question fields', () async {
    final controller = controllerWith(<Question>[
      sampleQuestion(optionCount: 3),
      sampleQuestion(optionCount: 5),
    ]);
    await controller.load();

    controller.answer('Option 1'); // wrong → bump attempts/shake
    controller.nextQuestion();
    final s = controller.currentState;
    expect(s.index, 1);
    expect(s.status, QuizStatus.ready);
    expect(s.attempts, 0);
    expect(s.lastSelected, isNull);
    expect(s.current!.options, hasLength(5));
    controller.dispose();
  });

  test('reset returns to the first question', () async {
    final controller = controllerWith(<Question>[
      sampleQuestion(optionCount: 3),
      sampleQuestion(optionCount: 5),
    ]);
    await controller.load();
    controller.nextQuestion();
    expect(controller.currentState.index, 1);
    expect(controller.currentState.isLastQuestion, isTrue);

    controller.reset();
    expect(controller.currentState.index, 0);
    expect(controller.currentState.status, QuizStatus.ready);
    expect(controller.currentState.total, 2);
    expect(controller.currentState.isLastQuestion, isFalse);
    controller.dispose();
  });
}
