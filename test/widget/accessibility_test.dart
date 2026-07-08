import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/app.dart';
import 'package:ultimate_ai_narrator/haptics/haptics.dart';
import 'package:ultimate_ai_narrator/narration/fake_narrator.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/state/providers.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('exposes a live-region status announcement for screen readers',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          narratorProvider.overrideWith((ref) => FakeNarrator()),
          quizRepositoryProvider.overrideWith(
            (ref) => FakeQuizRepository(<Question>[
              Question(prompt: 'q', options: const <String>['a', 'b'], answer: 'a'),
            ]),
          ),
          hapticsProvider.overrideWith((ref) => FakeHaptics()),
        ],
        child: const UltimateAiNarratorApp(),
      ),
    );
    await tester.pump();

    // Idle state announces a "Ready…" status.
    expect(find.bySemanticsLabel(RegExp('Ready')), findsOneWidget);
    handle.dispose();
  });
}
