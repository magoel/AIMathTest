import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/widgets/score_display.dart';

void main() {
  group('ScoreDisplay widget', () {
    testWidgets('displays correct score text (8/10) after animation settles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreDisplay(score: 8, total: 10),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('8/10'), findsOneWidget);
    });

    testWidgets('displays correct percentage (80%) after animation settles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreDisplay(score: 8, total: 10),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('handles zero score (0/5 -> 0%)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreDisplay(score: 0, total: 5),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('handles perfect score (10/10 -> 100%)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreDisplay(score: 10, total: 10),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('handles zero total without crash (0/0)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreDisplay(score: 0, total: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // With total=0, percentage is 0, score displays 0/0
      expect(find.text('0/0'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.byType(ScoreDisplay), findsOneWidget);
    });
  });
}
