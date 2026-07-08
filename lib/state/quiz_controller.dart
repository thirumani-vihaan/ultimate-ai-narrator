import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../haptics/haptics.dart';
import '../quiz/quiz_models.dart';
import 'quiz_state.dart';

/// Owns quiz answer logic. Pure state + side-effects (haptics) — no widgets — so
/// every rule is unit-testable offline. Questions are supplied by whatever
/// produced them (a generated story package, an asset, a backend).
class QuizController extends StateNotifier<QuizState> {
  QuizController(this._haptics) : super(const QuizState.loading());

  final Haptics _haptics;

  @visibleForTesting
  QuizState get currentState => state;

  /// Load a set of questions (e.g. from the generated story). An empty list
  /// keeps the loading state.
  void setQuestions(List<Question> questions) {
    state = QuizState(
      questions: questions,
      index: 0,
      status: questions.isEmpty ? QuizStatus.loading : QuizStatus.ready,
    );
  }

  /// Handle a tapped option. Wrong → shake + haptic, stays answerable. Correct →
  /// solved + celebratory haptic. Ignores taps once solved.
  void answer(String option) {
    final question = state.current;
    if (question == null || state.status == QuizStatus.solved) return;

    if (question.isCorrect(option)) {
      _haptics.correct();
      final stars = state.attempts == 0 ? 3 : (state.attempts == 1 ? 2 : 1);
      state = state.copyWith(
        status: QuizStatus.solved,
        lastSelected: option,
        totalStars: state.totalStars + stars,
      );
    } else {
      _haptics.wrong();
      state = state.copyWith(
        status: QuizStatus.wrong,
        lastSelected: option,
        attempts: state.attempts + 1,
        shakeToken: state.shakeToken + 1,
      );
    }
  }

  /// Advance to the next question in the sequence, if any. Builds a fresh state
  /// so per-question fields (lastSelected, attempts, shakeToken) reset cleanly
  /// (copyWith can't null-out nullable fields), preserving the running stars.
  void nextQuestion() {
    if (state.index + 1 < state.questions.length) {
      state = QuizState(
        questions: state.questions,
        index: state.index + 1,
        status: QuizStatus.ready,
        totalStars: state.totalStars,
      );
    }
  }

  /// Restart the whole quiz from the first question.
  void reset() {
    if (state.questions.isEmpty) return;
    state = QuizState(
      questions: state.questions,
      index: 0,
      status: QuizStatus.ready,
    );
  }
}
