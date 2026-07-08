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

    final events = <NarrationState>[];
    narrator.state.listen(events.add);

    await narrator.speak('hi');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(events.map((e) => e.runtimeType), <Type>[
      NarrationPreparing,
      NarrationSpeaking,
      NarrationCompleted,
    ]);
  });

  test('emits preparing → error when forced', () async {
    final narrator = FakeNarrator(
      prepareDelay: const Duration(milliseconds: 1),
      forceError: const NarrationError('nope'),
    );
    addTearDown(narrator.dispose);

    final events = <NarrationState>[];
    narrator.state.listen(events.add);

    await narrator.speak('hi');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(events.first, isA<NarrationPreparing>());
    expect(events.last, isA<NarrationError>());
    expect((events.last as NarrationError).message, 'nope');
    expect(events.any((e) => e is NarrationSpeaking), isFalse);
  });

  test('stop emits idle', () async {
    final narrator = FakeNarrator();
    addTearDown(narrator.dispose);
    final events = <NarrationState>[];
    narrator.state.listen(events.add);

    await narrator.stop();
    await Future<void>.delayed(Duration.zero);

    expect(events.single, isA<NarrationIdle>());
  });
}
