import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/narration/fake_narrator.dart';
import 'package:ultimate_ai_narrator/narration/fallback_narrator.dart';
import 'package:ultimate_ai_narrator/narration/narrator.dart';

void main() {
  const fast = Duration(milliseconds: 1);

  test('primary success passes through (fallback untouched)', () async {
    final narrator = FallbackNarrator(
      FakeNarrator(prepareDelay: fast, speakDelay: fast),
      FakeNarrator(prepareDelay: fast, speakDelay: fast),
    );
    addTearDown(narrator.dispose);

    final expectation = expectLater(
      narrator.state,
      emitsInOrder(<Matcher>[
        isA<NarrationPreparing>(),
        isA<NarrationSpeaking>(),
        isA<NarrationCompleted>(),
      ]),
    );
    await narrator.speak('hi');
    await expectation;
  });

  test('primary error transparently falls back and completes', () async {
    final narrator = FallbackNarrator(
      FakeNarrator(prepareDelay: fast, forceError: const NarrationError('down')),
      FakeNarrator(prepareDelay: fast, speakDelay: fast),
    );
    addTearDown(narrator.dispose);

    // Primary always errors, so reaching Completed proves the fallback ran.
    final expectation = expectLater(
      narrator.state,
      emitsThrough(isA<NarrationCompleted>()),
    );
    await narrator.speak('hi');
    await expectation;
  });

  test('if both fail, an error is surfaced', () async {
    final narrator = FallbackNarrator(
      FakeNarrator(prepareDelay: fast, forceError: const NarrationError('a')),
      FakeNarrator(prepareDelay: fast, forceError: const NarrationError('b')),
    );
    addTearDown(narrator.dispose);

    final expectation = expectLater(
      narrator.state,
      emitsThrough(isA<NarrationError>()),
    );
    await narrator.speak('hi');
    await expectation;
  });
}
