import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/widgets/math_text.dart';

void main() {
  group('MathText widget', () {
    testWidgets('renders plain text (no LaTeX) as regular Text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText('Hello World'),
          ),
        ),
      );

      // Plain text (no $ signs) renders as a regular Text widget
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(MathText), findsOneWidget);
    });

    testWidgets('renders without error when given LaTeX like \$2 + 3\$',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText(r'Solve: $2 + 3$'),
          ),
        ),
      );

      // LaTeX content renders via Text.rich with WidgetSpan, not plain Text.
      // Just verify the MathText widget exists and didn't crash.
      expect(find.byType(MathText), findsOneWidget);
      // No exceptions thrown — the widget tree built successfully.
    });

    testWidgets('handles empty string without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText(''),
          ),
        ),
      );

      // Empty string has no $ signs, so it renders as plain Text
      expect(find.byType(MathText), findsOneWidget);
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('widget type is found in tree', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText('Any content here'),
          ),
        ),
      );

      expect(find.byType(MathText), findsOneWidget);
    });

    testWidgets('handles complex LaTeX without crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathText(r'What is $\frac{1}{2} + \frac{3}{4}$?'),
          ),
        ),
      );

      expect(find.byType(MathText), findsOneWidget);
    });
  });
}
