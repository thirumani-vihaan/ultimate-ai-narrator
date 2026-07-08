import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/logging.dart';
import '../quiz/quiz_models.dart';
import 'story_generator.dart';
import 'story_models.dart';

/// Real generator backed by an OpenAI-compatible chat-completions API. Returns a
/// personalised story + quiz as strict JSON. Injectable [http.Client] so tests
/// exercise the real request/parse/error paths with a fake transport.
///
/// It is resilient by design: on **any** failure (no network, bad status,
/// malformed JSON) it transparently falls back to the on-device
/// [TemplateStoryGenerator], so a story is always produced.
class LlmStoryGenerator implements StoryGenerator {
  LlmStoryGenerator({
    required this.apiKey,
    Uri? endpoint,
    this.model = 'gpt-4o-mini',
    http.Client? client,
    StoryGenerator? fallback,
  })  : _client = client ?? http.Client(),
        _fallback = fallback ?? const TemplateStoryGenerator(),
        _endpoint =
            endpoint ?? Uri.parse('https://api.openai.com/v1/chat/completions');

  final String apiKey;
  final String model;
  final Uri _endpoint;
  final http.Client _client;
  final StoryGenerator _fallback;

  static const String _system =
      'You are a warm children\'s storyteller for ages 4-8. Given a hero, a '
      'companion and a place, write ONE short, gentle, joyful story (4-6 short '
      'sentences) starring them, then create a quiz derived ONLY from facts in '
      'your story. Respond with STRICT JSON of the shape: '
      '{"title": string, "story": string, "questions": [{"question": string, '
      '"options": [string, ...], "answer": string}]}. Provide 4 questions, each '
      'with 3-5 options, and "answer" MUST be one of that question\'s options. '
      'No text outside the JSON.';

  @override
  Future<StoryPackage> generate(StoryRequest request) async {
    try {
      final res = await _client
          .post(
            _endpoint,
            headers: <String, String>{
              'authorization': 'Bearer $apiKey',
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'model': model,
              'temperature': 0.9,
              'response_format': <String, String>{'type': 'json_object'},
              'messages': <Map<String, String>>[
                <String, String>{'role': 'system', 'content': _system},
                <String, String>{'role': 'user', 'content': _userPrompt(request)},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw StateError('LLM HTTP ${res.statusCode}');
      }
      final envelope = jsonDecode(res.body) as Map<String, dynamic>;
      final content = (envelope['choices'] as List<dynamic>).first
          as Map<String, dynamic>;
      final message = content['message'] as Map<String, dynamic>;
      final raw = message['content'] as String;
      return _parsePackage(jsonDecode(raw));
    } catch (e, s) {
      logError('LlmStoryGenerator.generate (falling back)', e, s);
      return _fallback.generate(request);
    }
  }

  String _userPrompt(StoryRequest r) =>
      'Hero: ${r.heroName}. Companion: ${r.companion}. Place: ${r.place}.';

  StoryPackage _parsePackage(dynamic decoded) {
    final map = Map<String, dynamic>.from(decoded as Map);
    final title = (map['title'] as String?)?.trim();
    final story = (map['story'] as String?)?.trim();
    if (title == null || title.isEmpty || story == null || story.isEmpty) {
      throw const FormatException('LLM story missing title/story.');
    }
    final rawQuestions = map['questions'];
    if (rawQuestions is! List || rawQuestions.length < 3) {
      throw const FormatException('LLM story needs at least 3 questions.');
    }
    final quiz = rawQuestions
        .map(
          (dynamic e) => Question.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(growable: false);
    return StoryPackage(title: title, story: story, quiz: quiz);
  }
}
