import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/logging.dart';
import 'asset_quiz_repository.dart';
import 'quiz_models.dart';
import 'quiz_repository.dart';

/// Optional real backend. Selected only when a `QUIZ_ENDPOINT` is configured;
/// otherwise the app uses [AssetQuizRepository]. Shares the exact same parsing
/// so the "data-driven" contract is identical across sources.
class HttpQuizRepository implements QuizRepository {
  HttpQuizRepository(this.endpoint, {http.Client? client})
      : _client = client ?? http.Client();

  final Uri endpoint;
  final http.Client _client;

  @override
  Future<List<Question>> loadQuestions() async {
    final http.Response res;
    try {
      res = await _client.get(endpoint).timeout(const Duration(seconds: 10));
    } catch (e, s) {
      logError('HttpQuizRepository.get', e, s);
      throw QuizLoadException('Could not reach the quiz backend.', cause: e);
    }

    if (res.statusCode != 200) {
      throw QuizLoadException('Quiz backend returned HTTP ${res.statusCode}.');
    }

    final dynamic decoded;
    try {
      decoded = json.decode(res.body);
    } catch (e, s) {
      logError('HttpQuizRepository.decode', e, s);
      throw QuizLoadException('Quiz backend sent invalid JSON.', cause: e);
    }

    final questions = AssetQuizRepository.parseQuestions(decoded);
    if (questions.isEmpty) {
      throw const QuizLoadException('Quiz backend sent no questions.');
    }
    return questions;
  }
}
