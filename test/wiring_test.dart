import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/haptics/haptics.dart';
import 'package:ultimate_ai_narrator/main.dart';
import 'package:ultimate_ai_narrator/narration/flutter_tts_narrator.dart';
import 'package:ultimate_ai_narrator/quiz/asset_quiz_repository.dart';
import 'package:ultimate_ai_narrator/state/providers.dart';

/// §2.3 WIRING VERIFICATION — proves each injectable interface's REAL
/// implementation is actually reachable from the production entry point
/// (`buildRealOverrides` in main.dart), not merely that the fake pattern works.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildRealOverrides wires the real implementations', () {
    final container = ProviderContainer(overrides: buildRealOverrides());
    addTearDown(container.dispose);

    // Narrator: default (no ELEVENLABS_API_KEY) → the real native TTS narrator.
    expect(container.read(narratorProvider), isA<FlutterTtsNarrator>());

    // Quiz: default (no QUIZ_ENDPOINT) → the real bundled-asset repository,
    // pointed at the shipped quiz asset.
    final repo = container.read(quizRepositoryProvider);
    expect(repo, isA<AssetQuizRepository>());
    expect((repo as AssetQuizRepository).assetPath, kQuizAssetPath);

    // Haptics: the real implementation.
    expect(container.read(hapticsProvider), isA<RealHaptics>());
  });
}
