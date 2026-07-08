import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/audio/sound_effects.dart';
import 'package:ultimate_ai_narrator/haptics/haptics.dart';
import 'package:ultimate_ai_narrator/main.dart';
import 'package:ultimate_ai_narrator/narration/flutter_tts_narrator.dart';
import 'package:ultimate_ai_narrator/settings/settings_store.dart';
import 'package:ultimate_ai_narrator/state/providers.dart';
import 'package:ultimate_ai_narrator/story/story_generator.dart';

/// WIRING VERIFICATION — proves each injectable interface's REAL implementation
/// is actually reachable from the production entry point (`buildRealOverrides`
/// in main.dart), not merely that the fake pattern works.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildRealOverrides wires the real implementations', () {
    final container = ProviderContainer(overrides: buildRealOverrides());
    addTearDown(container.dispose);

    // Narrator: default (no ELEVENLABS_API_KEY) → the real native TTS narrator.
    expect(container.read(narratorProvider), isA<FlutterTtsNarrator>());

    // Story generator: default (no OPENAI_API_KEY) → the on-device engine.
    expect(
      container.read(storyGeneratorProvider),
      isA<TemplateStoryGenerator>(),
    );

    // Haptics, sound effects, settings: the real implementations.
    expect(container.read(hapticsProvider), isA<RealHaptics>());
    expect(container.read(soundEffectsProvider), isA<JustAudioSoundEffects>());
    expect(
      container.read(settingsStoreProvider),
      isA<SharedPrefsSettingsStore>(),
    );
  });
}
