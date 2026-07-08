import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/quiz/asset_quiz_repository.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_repository.dart';

/// An in-memory [AssetBundle] returning a preset string, so the repository's
/// real load path is exercised offline.
class _StringBundle extends CachingAssetBundle {
  _StringBundle(this._data);
  final String? _data;

  @override
  Future<ByteData> load(String key) async {
    if (_data == null) throw FlutterError('asset not found');
    final bytes = utf8.encode(_data);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (_data == null) throw FlutterError('asset not found');
    return _data;
  }
}

void main() {
  group('AssetQuizRepository.parseQuestions — flexible payload shapes', () {
    test('bare JSON array', () {
      final decoded = json.decode('''
        [{"question":"q","options":["a","b"],"answer":"a"}]
      ''');
      final questions = AssetQuizRepository.parseQuestions(decoded);
      expect(questions, hasLength(1));
      expect(questions.first.answer, 'a');
    });

    test('{"questions":[...]} wrapper', () {
      final decoded = json.decode('''
        {"questions":[{"question":"q","options":["a","b","c"],"answer":"c"}]}
      ''');
      final questions = AssetQuizRepository.parseQuestions(decoded);
      expect(questions, hasLength(1));
      expect(questions.first.options, hasLength(3));
    });

    test('single question object', () {
      final decoded = json.decode('''
        {"question":"q","options":["a","b"],"answer":"b"}
      ''');
      final questions = AssetQuizRepository.parseQuestions(decoded);
      expect(questions, hasLength(1));
      expect(questions.first.answer, 'b');
    });

    test('unrecognised top-level shape throws QuizFormatException', () {
      expect(
        () => AssetQuizRepository.parseQuestions(42),
        throwsA(isA<QuizFormatException>()),
      );
    });
  });

  group('AssetQuizRepository.loadQuestions', () {
    test('loads a valid asset', () async {
      final repo = AssetQuizRepository(
        'x',
        bundle: _StringBundle(
          '[{"question":"q","options":["a","b"],"answer":"a"}]',
        ),
      );
      final questions = await repo.loadQuestions();
      expect(questions, hasLength(1));
    });

    test('missing asset → QuizLoadException', () {
      final repo = AssetQuizRepository('x', bundle: _StringBundle(null));
      expect(repo.loadQuestions(), throwsA(isA<QuizLoadException>()));
    });

    test('invalid JSON → QuizLoadException', () {
      final repo = AssetQuizRepository('x', bundle: _StringBundle('not json'));
      expect(repo.loadQuestions(), throwsA(isA<QuizLoadException>()));
    });

    test('empty array → QuizLoadException', () {
      final repo = AssetQuizRepository('x', bundle: _StringBundle('[]'));
      expect(repo.loadQuestions(), throwsA(isA<QuizLoadException>()));
    });
  });
}
