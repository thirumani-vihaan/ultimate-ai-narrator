import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';

void main() {
  group('Question.fromJson — data-driven (variable option counts)', () {
    for (final count in <int>[3, 4, 5]) {
      test('parses a $count-option question with no code change', () {
        final options = <String>[
          for (var i = 0; i < count; i++) 'Opt${i + 1}',
        ];
        final q = Question.fromJson(<String, dynamic>{
          'question': 'How many?',
          'options': options,
          'answer': 'Opt2',
        });
        expect(q.options, hasLength(count));
        expect(q.options, options);
        expect(q.isCorrect('Opt2'), isTrue);
        expect(q.isCorrect('Opt1'), isFalse);
      });
    }

    test('parses the exact spec payload (4 options, answer Blue)', () {
      final q = Question.fromJson(<String, dynamic>{
        'question': "What colour was Pip the Robot's lost gear?",
        'options': <String>['Red', 'Green', 'Blue', 'Yellow'],
        'answer': 'Blue',
      });
      expect(q.isCorrect('Blue'), isTrue);
      expect(q.options, hasLength(4));
    });
  });

  group('Question.fromJson — validation of malformed payloads', () {
    void expectFormatError(Map<String, dynamic> json) {
      expect(
        () => Question.fromJson(json),
        throwsA(isA<QuizFormatException>()),
      );
    }

    test('missing question', () {
      expectFormatError(<String, dynamic>{
        'options': <String>['a', 'b'],
        'answer': 'a',
      });
    });

    test('blank question', () {
      expectFormatError(<String, dynamic>{
        'question': '   ',
        'options': <String>['a', 'b'],
        'answer': 'a',
      });
    });

    test('options not a list', () {
      expectFormatError(<String, dynamic>{
        'question': 'q',
        'options': 'nope',
        'answer': 'a',
      });
    });

    test('fewer than two options', () {
      expectFormatError(<String, dynamic>{
        'question': 'q',
        'options': <String>['only'],
        'answer': 'only',
      });
    });

    test('duplicate options', () {
      expectFormatError(<String, dynamic>{
        'question': 'q',
        'options': <String>['a', 'a'],
        'answer': 'a',
      });
    });

    test('blank option', () {
      expectFormatError(<String, dynamic>{
        'question': 'q',
        'options': <String>['a', ''],
        'answer': 'a',
      });
    });

    test('answer not a string', () {
      expectFormatError(<String, dynamic>{
        'question': 'q',
        'options': <String>['a', 'b'],
        'answer': 3,
      });
    });

    test('answer not among options', () {
      expectFormatError(<String, dynamic>{
        'question': 'q',
        'options': <String>['a', 'b'],
        'answer': 'c',
      });
    });
  });

  group('Question value semantics', () {
    test('equality is by value', () {
      final a = Question(
        prompt: 'q',
        options: const <String>['a', 'b'],
        answer: 'a',
      );
      final b = Question(
        prompt: 'q',
        options: const <String>['a', 'b'],
        answer: 'a',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('options list is unmodifiable', () {
      final q = sample();
      expect(() => q.options.add('x'), throwsUnsupportedError);
    });
  });
}

Question sample() => Question(
      prompt: 'q',
      options: const <String>['a', 'b'],
      answer: 'a',
    );
