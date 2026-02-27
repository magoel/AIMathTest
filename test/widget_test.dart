import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/models/question_model.dart';
import 'package:aimathtest/config/constants.dart';

void main() {
  test('App smoke test - core models and constants load', () {
    final q = QuestionModel(
      id: 'smoke',
      question: 'Is this working?',
      correctAnswer: 'yes',
      topic: 'addition',
    );
    expect(q.id, 'smoke');
    expect(AppConstants.appName, 'AIMathTest');
    expect(AppConstants.freeTestMonthlyLimit, 10);
  });
}
