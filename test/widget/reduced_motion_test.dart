import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_ai_narrator/ui/widgets/buddy_character.dart';

void main() {
  testWidgets('reduceMotion stops the perpetual buddy animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BuddyCharacter(mood: BuddyMood.talking, reduceMotion: true),
          ),
        ),
      ),
    );
    // With reduce-motion on, the buddy does not animate forever, so the tree
    // reaches a steady state (a perpetual animation would make this time out).
    await tester.pumpAndSettle();
    expect(find.byType(BuddyCharacter), findsOneWidget);
  });

  testWidgets('without reduceMotion the buddy animates continuously',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BuddyCharacter(mood: BuddyMood.talking),
          ),
        ),
      ),
    );
    await tester.pump();
    // A frame later there is still a scheduled frame (ongoing animation).
    expect(tester.binding.hasScheduledFrame, isTrue);
  });
}
