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
      QuizController(haptics)..setQuestions(questions);

  test('setQuestions populates and becomes ready', () {
    final controller = controllerWith(<Question>[sampleQuestion()]);
    expect(controller.currentState.status, QuizStatus.ready);
    expect(controller.currentState.questions, hasLength(1));
    controller.dispose();
  });

  test('empty question list stays in loading', () {
    final controller = controllerWith(const <Question>[]);
    expect(controller.currentState.status, QuizStatus.loading);
    controller.dispose();
  });

  test('wrong answer → shake token + attempt + haptic, stays answerable', () {
    final controller = controllerWith(<Question>[sampleQuestion()]);

    controller.answer('Option 1');
    final s = controller.currentState;
    expect(s.status, QuizStatus.wrong);
    expect(s.attempts, 1);
    expect(s.shakeToken, 1);
    expect(s.lastSelected, 'Option 1');
    expect(haptics.calls, contains('wrong'));
    controller.dispose();
  });

  test('correct answer → solved + celebratory haptic', () {
    final controller = controllerWith(<Question>[sampleQuestion()]);

    controller.answer('Option 2');
    expect(controller.currentState.status, QuizStatus.solved);
    expect(haptics.calls, contains('correct'));
    controller.dispose();
  });

  test('taps after solved are ignored', () {
    final controller = controllerWith(<Question>[sampleQuestion()]);

    controller.answer('Option 2'); // solve
    controller.answer('Option 1'); // ignored
    expect(controller.currentState.status, QuizStatus.solved);
    controller.dispose();
  });

  test('nextQuestion advances and resets per-question fields', () {
    final controller = controllerWith(<Question>[
      sampleQuestion(optionCount: 3),
      sampleQuestion(optionCount: 5),
    ]);

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

  test('reset returns to the first question', () {
    final controller = controllerWith(<Question>[
      sampleQuestion(optionCount: 3),
      sampleQuestion(optionCount: 5),
    ]);
    controller.nextQuestion();
    expect(controller.currentState.index, 1);

    controller.reset();
    expect(controller.currentState.index, 0);
    expect(controller.currentState.status, QuizStatus.ready);
    controller.dispose();
  });

  test('stars: 3 for a first-try correct, 2 after one wrong, accumulating', () {
    final controller = controllerWith(<Question>[
      sampleQuestion(optionCount: 3),
      sampleQuestion(optionCount: 5),
    ]);

    controller.answer('Option 2'); // correct first try → 3 stars
    expect(controller.currentState.currentQuestionStars, 3);
    expect(controller.currentState.totalStars, 3);

    controller.nextQuestion();
    controller.answer('Option 1'); // wrong
    controller.answer('Option 2'); // correct after 1 wrong → 2 stars
    expect(controller.currentState.currentQuestionStars, 2);
    expect(controller.currentState.totalStars, 5);
    expect(controller.currentState.maxStars, 6);
    controller.dispose();
  });
}
