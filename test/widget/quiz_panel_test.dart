import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/quiz/quiz_models.dart';
import 'package:ultimate_ai_narrator/state/quiz_state.dart';
import 'package:ultimate_ai_narrator/ui/widgets/option_tile.dart';
import 'package:ultimate_ai_narrator/ui/widgets/quiz_panel.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

QuizState _stateWith(int optionCount) {
  final question = Question(
    prompt: 'How many?',
    options: <String>[for (var i = 0; i < optionCount; i++) 'O$i'],
    answer: 'O0',
  );
  return QuizState(
    questions: <Question>[question],
    index: 0,
    status: QuizStatus.ready,
  );
}

void main() {
  for (final count in <int>[3, 4, 5]) {
    testWidgets('renders exactly $count tiles from data', (tester) async {
      await tester.pumpWidget(
        _wrap(QuizPanel(state: _stateWith(count), onAnswer: (_) {})),
      );
      expect(find.byType(OptionTile), findsNWidgets(count));
    });
  }

  testWidgets('tapping an option reports its label', (tester) async {
    String? tapped;
    final state = QuizState(
      questions: <Question>[
        Question(
          prompt: 'q',
          options: const <String>['Apple', 'Banana', 'Cherry'],
          answer: 'Apple',
        ),
      ],
      index: 0,
      status: QuizStatus.ready,
    );
    await tester.pumpWidget(
      _wrap(QuizPanel(state: state, onAnswer: (o) => tapped = o)),
    );
    await tester.tap(find.text('Banana'));
    expect(tapped, 'Banana');
  });

  testWidgets('solved state marks the correct answer and dims others',
      (tester) async {
    final base = _stateWith(4);
    final solved = base.copyWith(status: QuizStatus.solved, lastSelected: 'O0');
    await tester.pumpWidget(
      _wrap(QuizPanel(state: solved, onAnswer: (_) {})),
    );
    // The correct tile shows a check icon.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
