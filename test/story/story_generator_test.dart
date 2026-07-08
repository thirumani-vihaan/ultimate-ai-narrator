import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ultimate_ai_narrator/story/llm_story_generator.dart';
import 'package:ultimate_ai_narrator/story/story_generator.dart';
import 'package:ultimate_ai_narrator/story/story_models.dart';

void main() {
  const request = StoryRequest(
    heroName: 'Maya',
    companion: 'a curious fox',
    place: 'the Whispering Woods',
  );

  group('TemplateStoryGenerator', () {
    const gen = TemplateStoryGenerator();

    test("weaves the child's choices into a coherent story", () async {
      final pkg = await gen.generate(request);
      expect(pkg.title, contains('Maya'));
      expect(pkg.story, contains('Maya'));
      expect(pkg.story, contains('a curious fox'));
      expect(pkg.story, contains('the Whispering Woods'));
      expect(pkg.story.length, greaterThan(60));
    });

    test('quiz is derived from the story and always valid', () async {
      final pkg = await gen.generate(request);
      expect(pkg.quiz.length, 4);
      for (final q in pkg.quiz) {
        expect(q.options, contains(q.answer));
        expect(q.options.toSet().length, q.options.length);
        expect(q.options.length, greaterThanOrEqualTo(3));
      }
      final placeQ = pkg.quiz.firstWhere((q) => q.prompt.contains('Where'));
      expect(placeQ.answer, 'the Whispering Woods');
      final counts = pkg.quiz.map((q) => q.options.length).toSet();
      expect(counts.length, greaterThan(1));
    });

    test('is deterministic for the same request', () async {
      final a = await gen.generate(request);
      final b = await gen.generate(request);
      expect(a.story, b.story);
      expect(a.title, b.title);
    });

    test('produces different stories for different requests', () async {
      final a = await gen.generate(request);
      final b = await gen.generate(
        const StoryRequest(
          heroName: 'Arjun',
          companion: 'a sleepy dragon',
          place: 'Outer Space',
        ),
      );
      expect(a.story, isNot(b.story));
    });
  });

  group('LlmStoryGenerator', () {
    test('parses a valid LLM JSON response into a package', () async {
      final content = jsonEncode(<String, dynamic>{
        'title': 'Maya and the Blue Key',
        'story': 'Once upon a time Maya found a key.',
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'question': 'What did Maya find?',
            'options': <String>['Key', 'Boot', 'Hat'],
            'answer': 'Key',
          },
          <String, dynamic>{
            'question': 'Colour?',
            'options': <String>['Blue', 'Red', 'Green'],
            'answer': 'Blue',
          },
          <String, dynamic>{
            'question': 'Who?',
            'options': <String>['Maya', 'Sam'],
            'answer': 'Maya',
          },
        ],
      });
      final envelope = jsonEncode(<String, dynamic>{
        'choices': <Map<String, dynamic>>[
          <String, dynamic>{
            'message': <String, String>{'content': content},
          },
        ],
      });
      final mock = MockClient((http.Request req) async {
        return http.Response(envelope, 200);
      });
      final gen = LlmStoryGenerator(apiKey: 'k', client: mock);

      final pkg = await gen.generate(request);
      expect(pkg.title, 'Maya and the Blue Key');
      expect(pkg.quiz, hasLength(3));
      expect(pkg.quiz.first.answer, 'Key');
    });

    test('falls back to the on-device generator on HTTP error', () async {
      final mock = MockClient((http.Request req) async {
        return http.Response('boom', 500);
      });
      final gen = LlmStoryGenerator(apiKey: 'k', client: mock);

      final pkg = await gen.generate(request);
      expect(pkg.story, contains('Maya'));
      expect(pkg.quiz, isNotEmpty);
    });

    test('falls back when the model returns malformed content', () async {
      final envelope = jsonEncode(<String, dynamic>{
        'choices': <Map<String, dynamic>>[
          <String, dynamic>{
            'message': <String, String>{'content': 'not json at all'},
          },
        ],
      });
      final mock = MockClient((http.Request req) async {
        return http.Response(envelope, 200);
      });
      final gen = LlmStoryGenerator(apiKey: 'k', client: mock);

      final pkg = await gen.generate(request);
      expect(pkg.story, contains('Maya'));
    });
  });
}
