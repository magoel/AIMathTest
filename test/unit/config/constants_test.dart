import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/config/constants.dart';

void main() {
  group('AppConstants.scoreMessage', () {
    test('returns "Perfect Score!" for 100%', () {
      expect(AppConstants.scoreMessage(100), 'Perfect Score!');
    });

    test('returns "Great Job!" for 80-99%', () {
      expect(AppConstants.scoreMessage(99), 'Great Job!');
      expect(AppConstants.scoreMessage(80), 'Great Job!');
      expect(AppConstants.scoreMessage(90), 'Great Job!');
    });

    test('returns "Good Effort!" for 60-79%', () {
      expect(AppConstants.scoreMessage(79), 'Good Effort!');
      expect(AppConstants.scoreMessage(60), 'Good Effort!');
      expect(AppConstants.scoreMessage(70), 'Good Effort!');
    });

    test('returns "Keep Practicing!" for below 60%', () {
      expect(AppConstants.scoreMessage(59), 'Keep Practicing!');
      expect(AppConstants.scoreMessage(0), 'Keep Practicing!');
      expect(AppConstants.scoreMessage(30), 'Keep Practicing!');
    });

    test('handles above 100% as Perfect Score', () {
      expect(AppConstants.scoreMessage(105), 'Perfect Score!');
    });
  });

  group('AppConstants.scoreEmoji', () {
    test('returns star emoji for 100%', () {
      expect(AppConstants.scoreEmoji(100), '\u{1F31F}');
    });

    test('returns party emoji for 80-99%', () {
      expect(AppConstants.scoreEmoji(80), '\u{1F389}');
      expect(AppConstants.scoreEmoji(99), '\u{1F389}');
    });

    test('returns thumbs up for 60-79%', () {
      expect(AppConstants.scoreEmoji(60), '\u{1F44D}');
      expect(AppConstants.scoreEmoji(79), '\u{1F44D}');
    });

    test('returns flexed bicep for below 60%', () {
      expect(AppConstants.scoreEmoji(59), '\u{1F4AA}');
      expect(AppConstants.scoreEmoji(0), '\u{1F4AA}');
    });
  });

  group('AppConstants.adminEmails', () {
    test('contains 3 admin emails', () {
      expect(AppConstants.adminEmails.length, 3);
    });

    test('contains known admin emails', () {
      expect(AppConstants.adminEmails, contains('manish.dce@gmail.com'));
      expect(AppConstants.adminEmails, contains('nupzbansal@gmail.com'));
      expect(AppConstants.adminEmails, contains('numerixlabs@gmail.com'));
    });

    test('rejects random emails', () {
      expect(AppConstants.adminEmails.contains('random@example.com'), isFalse);
      expect(AppConstants.adminEmails.contains(''), isFalse);
    });
  });

  group('AppConstants static values', () {
    test('freeTestMonthlyLimit is 10', () {
      expect(AppConstants.freeTestMonthlyLimit, 10);
    });

    test('testExpiryDays is 90', () {
      expect(AppConstants.testExpiryDays, 90);
    });

    test('questionCounts has expected values', () {
      expect(AppConstants.questionCounts, [5, 10, 15, 20]);
    });

    test('topics map has 17 entries', () {
      expect(AppConstants.topics.length, 17);
    });

    test('gradeLabels has 13 entries (K-12)', () {
      expect(AppConstants.gradeLabels.length, 13);
      expect(AppConstants.gradeLabels.first, 'Kindergarten');
      expect(AppConstants.gradeLabels.last, 'Grade 12');
    });
  });
}
