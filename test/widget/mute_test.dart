import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/app.dart';
import 'package:ultimate_ai_narrator/haptics/haptics.dart';
import 'package:ultimate_ai_narrator/narration/fake_narrator.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/state/providers.dart';
import 'package:ultimate_ai_narrator/story/story_models.dart';

void main() {
  testWidgets('mute toggle flips the sound icon', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          narratorProvider.overrideWith((ref) => FakeNarrator()),
          activeStoryProvider.overrideWith(
            (ref) => StoryPackage(
              title: 'T',
              story: 'A tale.',
              quiz: <Question>[
                Question(
                  prompt: 'q',
                  options: const <String>['a', 'b'],
                  answer: 'a',
                ),
              ],
            ),
          ),
          hapticsProvider.overrideWith((ref) => FakeHaptics()),
        ],
        child: const UltimateAiNarratorApp(),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.music_note_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.music_off_rounded), findsOneWidget);
  });
}
