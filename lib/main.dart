import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'haptics/haptics.dart';
import 'narration/elevenlabs_narrator.dart';
import 'narration/fallback_narrator.dart';
import 'narration/flutter_tts_narrator.dart';
import 'narration/just_audio_sink.dart';
import 'narration/narrator.dart';
import 'quiz/asset_quiz_repository.dart';
import 'quiz/http_quiz_repository.dart';
import 'quiz/quiz_repository.dart';
import 'state/providers.dart';

/// Optional configuration supplied at build time via `--dart-define` (works on
/// every platform including web). Empty by default → the credential-free,
/// device-native paths are used.
const String _elevenLabsKey = String.fromEnvironment('ELEVENLABS_API_KEY');
const String _quizEndpoint = String.fromEnvironment('QUIZ_ENDPOINT');

/// The default quiz asset ("as if served by our backend").
const String kQuizAssetPath = 'assets/quiz/quiz.json';

/// THE single place real implementations are constructed and injected. Every
/// injectable interface from INTERFACES.md is wired here — and only here in
/// production code — so the §2.3 wiring verification has one concrete target.
List<Override> buildRealOverrides() {
  return <Override>[
    narratorProvider.overrideWith((ref) {
      // Remote ElevenLabs (when a key is set) with automatic fallback to the
      // credential-free native engine if it errors; otherwise native only.
      final Narrator narrator = _elevenLabsKey.isNotEmpty
          ? FallbackNarrator(
              ElevenLabsNarrator(
                apiKey: _elevenLabsKey,
                sink: JustAudioSink(),
              ),
              FlutterTtsNarrator(),
            )
          : FlutterTtsNarrator();
      ref.onDispose(narrator.dispose);
      return narrator;
    }),
    quizRepositoryProvider.overrideWith((ref) {
      final QuizRepository repository = _quizEndpoint.isNotEmpty
          ? HttpQuizRepository(Uri.parse(_quizEndpoint))
          : AssetQuizRepository(kQuizAssetPath);
      return repository;
    }),
    hapticsProvider.overrideWith((ref) => const RealHaptics()),
  ];
}

void main() {
  runApp(
    ProviderScope(
      overrides: buildRealOverrides(),
      child: const UltimateAiNarratorApp(),
    ),
  );
}
