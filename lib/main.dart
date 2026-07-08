import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'audio/sound_effects.dart';
import 'haptics/haptics.dart';
import 'narration/elevenlabs_narrator.dart';
import 'narration/fallback_narrator.dart';
import 'narration/flutter_tts_narrator.dart';
import 'narration/just_audio_sink.dart';
import 'narration/narrator.dart';
import 'settings/settings_store.dart';
import 'state/providers.dart';
import 'story/llm_story_generator.dart';
import 'story/story_generator.dart';

/// Optional configuration supplied at build time via `--dart-define` (works on
/// every platform including web). Empty by default → the credential-free,
/// on-device paths are used.
const String _elevenLabsKey = String.fromEnvironment('ELEVENLABS_API_KEY');
const String _elevenLabsModel =
    String.fromEnvironment('ELEVENLABS_MODEL', defaultValue: 'eleven_flash_v2_5');
const String _openAiKey = String.fromEnvironment('OPENAI_API_KEY');

/// THE single place real implementations are constructed and injected. Every
/// injectable interface is wired here — and only here in production code — so
/// the wiring verification has one concrete target.
List<Override> buildRealOverrides() {
  return <Override>[
    narratorProvider.overrideWith((ref) {
      // Remote ElevenLabs (when a key is set) with automatic fallback to the
      // credential-free native engine if it errors; otherwise native only.
      final Narrator narrator = _elevenLabsKey.isNotEmpty
          ? FallbackNarrator(
              ElevenLabsNarrator(
                apiKey: _elevenLabsKey,
                // Value varies with --dart-define=ELEVENLABS_MODEL.
                // ignore: avoid_redundant_argument_values
                model: _elevenLabsModel,
                sink: JustAudioSink(),
              ),
              FlutterTtsNarrator(),
            )
          : FlutterTtsNarrator();
      ref.onDispose(narrator.dispose);
      return narrator;
    }),
    storyGeneratorProvider.overrideWith((ref) {
      // Real LLM (when a key is set) with the on-device engine as fallback;
      // otherwise the on-device engine alone. Either way, no key is required.
      if (_openAiKey.isNotEmpty) {
        return LlmStoryGenerator(
          apiKey: _openAiKey,
          fallback: const TemplateStoryGenerator(),
        );
      }
      return const TemplateStoryGenerator();
    }),
    hapticsProvider.overrideWith((ref) => const RealHaptics()),
    soundEffectsProvider.overrideWith((ref) {
      final sfx = JustAudioSoundEffects();
      ref.onDispose(sfx.dispose);
      return sfx;
    }),
    settingsStoreProvider.overrideWith((ref) => SharedPrefsSettingsStore()),
  ];
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: buildRealOverrides(),
      child: const UltimateAiNarratorApp(),
    ),
  );
}
