import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging.dart';
import '../haptics/haptics.dart';
import '../quiz/quiz_repository.dart';
import 'quiz_state.dart';

/// Owns quiz answer logic. Pure state + side-effects (haptics) — no widgets — so
/// every rule is unit-testable offline.
class QuizController extends StateNotifier<QuizState> {
  QuizController(this._repo, this._haptics) : super(const QuizState.loading());

  final QuizRepository _repo;
  final Haptics _haptics;

  /// Loads questions from the (injected) repository. On any failure it degrades
  /// to a friendly error state instead of throwing across the boundary.
  Future<void> load() async {
    try {
      final questions = await _repo.loadQuestions();
      state = QuizState(
        questions: questions,
        index: 0,
        status: QuizStatus.ready,
      );
    } catch (e, s) {
      logError('QuizController.load', e, s);
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: 'We could not load the quiz. Please try again.',
      );
    }
  }

  /// Handle a tapped option. Wrong → shake + haptic, stays answerable. Correct →
  /// solved + celebratory haptic. Ignores taps once solved.
  void answer(String option) {
    final question = state.current;
    if (question == null || state.status == QuizStatus.solved) return;

    if (question.isCorrect(option)) {
      _haptics.correct();
      state = state.copyWith(status: QuizStatus.solved, lastSelected: option);
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
  /// (copyWith can't null-out nullable fields).
  void nextQuestion() {
    if (state.index + 1 < state.questions.length) {
      state = QuizState(
        questions: state.questions,
        index: state.index + 1,
        status: QuizStatus.ready,
      );
    }
  }
}
