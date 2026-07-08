import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/narration/fake_narrator.dart';
import 'package:ultimate_ai_narrator/narration/narrator.dart';

void main() {
  test('emits preparing → speaking → completed on success', () async {
    final narrator = FakeNarrator(
      prepareDelay: const Duration(milliseconds: 1),
      speakDelay: const Duration(milliseconds: 1),
    );
    addTearDown(narrator.dispose);

    // Deterministic: assert the exact ordered stream, independent of wall clock.
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

  test('emits preparing → error (no speaking) when forced', () async {
    final narrator = FakeNarrator(
      prepareDelay: const Duration(milliseconds: 1),
      forceError: const NarrationError('nope'),
    );
    addTearDown(narrator.dispose);

    final expectation = expectLater(
      narrator.state,
      emitsInOrder(<Object>[
        isA<NarrationPreparing>(),
        predicate<NarrationState>(
          (s) => s is NarrationError && s.message == 'nope',
          'a NarrationError with message "nope"',
        ),
      ]),
    );
    await narrator.speak('hi');
    await expectation;
  });

  test('stop emits idle', () async {
    final narrator = FakeNarrator();
    addTearDown(narrator.dispose);

    final expectation = expectLater(
      narrator.state,
      emits(isA<NarrationIdle>()),
    );
    await narrator.stop();
    await expectation;
  });
}
