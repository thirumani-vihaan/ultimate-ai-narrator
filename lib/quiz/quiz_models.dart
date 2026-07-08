import 'package:flutter/foundation.dart';

/// Thrown when a quiz payload is structurally invalid. The [message] is
/// developer-facing; the UI shows a friendly generic message instead.
class QuizFormatException implements Exception {
  const QuizFormatException(this.message);

  final String message;

  @override
  String toString() => 'QuizFormatException: $message';
}

/// An immutable quiz question.
///
/// The number of options is intentionally *not* fixed at 4 — the renderer draws
/// `options.length` tiles, so a backend sending 3, 4 or 5 options works with
/// zero code changes. This is the spec's core "data-driven" requirement encoded
/// directly in the type.
@immutable
class Question {
  const Question._({
    required this.prompt,
    required this.options,
    required this.answer,
  });

  factory Question({
    required String prompt,
    required List<String> options,
    required String answer,
  }) {
    return Question._(
      prompt: prompt,
      options: List<String>.unmodifiable(options),
      answer: answer,
    );
  }

  /// Parses and *validates* a single question object. Throws
  /// [QuizFormatException] with a precise reason on any malformed field, so a
  /// bad backend payload degrades to a friendly error instead of a crash.
  factory Question.fromJson(Map<String, dynamic> json) {
    final dynamic prompt = json['question'];
    if (prompt is! String || prompt.trim().isEmpty) {
      throw const QuizFormatException('"question" must be a non-empty string.');
    }

    final dynamic rawOptions = json['options'];
    if (rawOptions is! List) {
      throw const QuizFormatException('"options" must be a list.');
    }
    final options = <String>[];
    for (final dynamic o in rawOptions) {
      if (o is! String || o.trim().isEmpty) {
        throw const QuizFormatException(
          'every option must be a non-empty string.',
        );
      }
      options.add(o);
    }
    if (options.length < 2) {
      throw const QuizFormatException('a question needs at least 2 options.');
    }
    if (options.toSet().length != options.length) {
      throw const QuizFormatException('options must be unique.');
    }

    final dynamic answer = json['answer'];
    if (answer is! String) {
      throw const QuizFormatException('"answer" must be a string.');
    }
    if (!options.contains(answer)) {
      throw QuizFormatException(
        '"answer" ("$answer") is not one of the options.',
      );
    }

    return Question(prompt: prompt, options: options, answer: answer);
  }

  final String prompt;
  final List<String> options;
  final String answer;

  bool isCorrect(String selected) => selected == answer;

  @override
  bool operator ==(Object other) =>
      other is Question &&
      other.prompt == prompt &&
      listEquals(other.options, options) &&
      other.answer == answer;

  @override
  int get hashCode => Object.hash(prompt, Object.hashAll(options), answer);
}
