import 'package:flutter/foundation.dart';

import '../quiz/quiz_models.dart';

enum QuizStatus { loading, ready, wrong, solved, error }

/// Immutable snapshot of the quiz. Equality is by value so Riverpod rebuilds
/// only when something actually changes.
@immutable
class QuizState {
  const QuizState({
    required this.questions,
    required this.index,
    required this.status,
    this.lastSelected,
    this.attempts = 0,
    this.shakeToken = 0,
    this.errorMessage,
  });

  const QuizState.loading()
      : questions = const <Question>[],
        index = 0,
        status = QuizStatus.loading,
        lastSelected = null,
        attempts = 0,
        shakeToken = 0,
        errorMessage = null;

  final List<Question> questions;
  final int index;
  final QuizStatus status;

  /// The most recently selected option (to highlight it).
  final String? lastSelected;

  /// Number of wrong attempts on the current question.
  final int attempts;

  /// Monotonic counter; a change signals the UI to play the shake animation
  /// (decoupling "an event happened" from imperative animation calls).
  final int shakeToken;

  final String? errorMessage;

  Question? get current =>
      questions.isEmpty || index >= questions.length ? null : questions[index];

  bool get isSolved => status == QuizStatus.solved;

  QuizState copyWith({
    List<Question>? questions,
    int? index,
    QuizStatus? status,
    String? lastSelected,
    int? attempts,
    int? shakeToken,
    String? errorMessage,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      index: index ?? this.index,
      status: status ?? this.status,
      lastSelected: lastSelected ?? this.lastSelected,
      attempts: attempts ?? this.attempts,
      shakeToken: shakeToken ?? this.shakeToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QuizState &&
      listEquals(other.questions, questions) &&
      other.index == index &&
      other.status == status &&
      other.lastSelected == lastSelected &&
      other.attempts == attempts &&
      other.shakeToken == shakeToken &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(questions),
        index,
        status,
        lastSelected,
        attempts,
        shakeToken,
        errorMessage,
      );
}
