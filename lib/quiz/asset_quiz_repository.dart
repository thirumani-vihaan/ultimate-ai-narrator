import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../core/logging.dart';
import 'quiz_models.dart';
import 'quiz_repository.dart';

/// Loads quiz questions from a bundled JSON asset (the default, backend-free
/// path). Accepts three payload shapes so it tolerates whatever a real backend
/// might send without any code change:
///   * a bare JSON array of question objects,
///   * `{ "questions": [ ... ] }`,
///   * a single question object `{ "question": ..., "options": ..., "answer": ... }`.
class AssetQuizRepository implements QuizRepository {
  AssetQuizRepository(this.assetPath, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  @override
  Future<List<Question>> loadQuestions() async {
    final String raw;
    try {
      raw = await _bundle.loadString(assetPath);
    } catch (e, s) {
      logError('AssetQuizRepository.loadString', e, s);
      throw QuizLoadException(
        'Could not read quiz asset "$assetPath".',
        cause: e,
      );
    }

    final dynamic decoded;
    try {
      decoded = json.decode(raw);
    } catch (e, s) {
      logError('AssetQuizRepository.decode', e, s);
      throw QuizLoadException('Quiz asset is not valid JSON.', cause: e);
    }

    final questions = parseQuestions(decoded);
    if (questions.isEmpty) {
      throw const QuizLoadException('Quiz payload contained no questions.');
    }
    return questions;
  }

  /// Shared, source-agnostic parsing used by asset + HTTP repositories.
  /// Throws [QuizFormatException] if the top-level shape is unrecognised.
  static List<Question> parseQuestions(dynamic decoded) {
    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['questions'] is List) {
      list = decoded['questions'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic> &&
        decoded.containsKey('question')) {
      list = <dynamic>[decoded];
    } else {
      throw const QuizFormatException(
        'Expected a list of questions, a {"questions":[...]} object, '
        'or a single question object.',
      );
    }
    return list
        .map(
          (dynamic e) => Question.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(growable: false);
  }
}
