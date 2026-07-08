import 'dart:async';

import 'package:ultimate_ai_narrator/narration/narrator.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_repository.dart';

/// A [Narrator] whose events are pushed manually, so state-machine transitions
/// can be tested deterministically without any timing.
class ManualNarrator implements Narrator {
  final StreamController<NarrationState> _controller =
      StreamController<NarrationState>.broadcast();
  final List<String> speakCalls = <String>[];
  int stopCalls = 0;
  bool disposed = false;

  void emit(NarrationState state) => _controller.add(state);

  @override
  Stream<NarrationState> get state => _controller.stream;

  @override
  Future<void> speak(String text) async => speakCalls.add(text);

  @override
  Future<void> stop() async => stopCalls++;

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}

/// Returns a fixed list of questions.
class FakeQuizRepository implements QuizRepository {
  FakeQuizRepository(this.questions);

  final List<Question> questions;

  @override
  Future<List<Question>> loadQuestions() async => questions;
}

/// Always fails, to exercise the load-error path.
class FailingQuizRepository implements QuizRepository {
  @override
  Future<List<Question>> loadQuestions() async =>
      throw const QuizLoadException('boom');
}

/// A convenient sample question with a configurable option count.
Question sampleQuestion({int optionCount = 4}) {
  final options = <String>[
    for (var i = 0; i < optionCount; i++) 'Option ${i + 1}',
  ];
  return Question(
    prompt: 'Pick option 2',
    options: options,
    answer: 'Option 2',
  );
}
