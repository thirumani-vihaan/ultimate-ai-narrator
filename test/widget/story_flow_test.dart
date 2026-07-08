import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/app.dart';
import 'package:ultimate_ai_narrator/haptics/haptics.dart';
import 'package:ultimate_ai_narrator/narration/fake_narrator.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/state/providers.dart';
import 'package:ultimate_ai_narrator/story/story_models.dart';
import 'package:ultimate_ai_narrator/ui/widgets/option_tile.dart';

import '../support/fakes.dart';

/// End-to-end smoke test of the full flow, driven entirely by fakes (no device,
/// no credentials): a generated story is active → read → narrate → quiz reveal →
/// wrong feedback → success. Uses fixed `pump(Duration)` steps because the buddy
/// animation repeats forever (so `pumpAndSettle` would never return).
void main() {
  testWidgets('read → narrate → quiz → wrong → correct → success',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final package = StoryPackage(
      title: 'Test Tale',
      story: 'A short and merry little story.',
      quiz: <Question>[
        Question(
          prompt: 'What colour?',
          options: const <String>['Red', 'Green', 'Blue', 'Yellow'],
          answer: 'Blue',
        ),
      ],
    );

    final sfx = FakeSoundEffects();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          narratorProvider.overrideWith(
            (ref) => FakeNarrator(
              prepareDelay: const Duration(milliseconds: 1),
              speakDelay: const Duration(milliseconds: 1),
            ),
          ),
          activeStoryProvider.overrideWith((ref) => package),
          hapticsProvider.overrideWith((ref) => FakeHaptics()),
          soundEffectsProvider.overrideWith((ref) => sfx),
        ],
        child: const UltimateAiNarratorApp(),
      ),
    );
    await tester.pump();

    // A story is active, so the read call-to-action is visible.
    expect(find.text('Read Me a Story'), findsOneWidget);

    await tester.tap(find.text('Read Me a Story'));
    await tester.pump(); // → preparing
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Quiz is revealed, rendered from data (4 options).
    expect(find.byType(OptionTile), findsNWidgets(4));

    // Wrong answer → gentle "try again" feedback.
    await tester.ensureVisible(find.text('Red'));
    await tester.pump();
    await tester.tap(find.text('Red'));
    await tester.pump();
    expect(find.textContaining('Not quite'), findsOneWidget);
    expect(sfx.calls, contains('wrong'));

    // Correct answer → success celebration.
    await tester.ensureVisible(find.text('Blue'));
    await tester.pump();
    await tester.tap(find.text('Blue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('You did it'), findsOneWidget);
    expect(sfx.calls, contains('correct'));
  });
}
