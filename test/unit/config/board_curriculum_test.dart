import 'package:flutter_test/flutter_test.dart';
import 'package:aimathtest/config/board_curriculum.dart';

void main() {
  group('Board enum', () {
    test('has label getter', () {
      expect(Board.cbse.label, 'CBSE');
      expect(Board.ib.label, 'IB');
      expect(Board.cambridge.label, 'Cambridge');
    });

    test('has description getter', () {
      expect(Board.cbse.description, 'Central Board of Secondary Education');
      expect(Board.ib.description, 'International Baccalaureate');
      expect(Board.cambridge.description, 'Cambridge International');
    });

    test('has exactly 3 values', () {
      expect(Board.values.length, 3);
    });
  });

  group('getAvailableTopics - K-2 cumulative', () {
    test('Kindergarten gets full cumulative set for CBSE', () {
      final topics = getAvailableTopics(Board.cbse, 0);
      // Grade 0 CBSE has basics + measurement
      expect(topics, containsAll(['addition', 'subtraction', 'word_problems', 'geometry', 'measurement']));
    });

    test('Grade 1 gets full cumulative set for IB', () {
      final topics = getAvailableTopics(Board.ib, 1);
      expect(topics, containsAll(['addition', 'subtraction', 'word_problems', 'geometry', 'measurement']));
    });

    test('Grade 2 gets full cumulative set for Cambridge', () {
      final topics = getAvailableTopics(Board.cambridge, 2);
      // Cambridge grade 2 cumulative includes multiplication, division
      expect(topics, containsAll(['addition', 'subtraction', 'multiplication', 'division']));
    });
  });

  group('getAvailableTopics - windowed (grades 3-12)', () {
    test('Grade 6 CBSE gets windowed topics (at least 4)', () {
      final topics = getAvailableTopics(Board.cbse, 6);
      expect(topics.length, greaterThanOrEqualTo(4));
    });

    test('Grade 10 IB gets windowed topics (at least 4)', () {
      final topics = getAvailableTopics(Board.ib, 10);
      expect(topics.length, greaterThanOrEqualTo(4));
    });

    test('Grade 12 Cambridge gets windowed topics (at least 4)', () {
      final topics = getAvailableTopics(Board.cambridge, 12);
      expect(topics.length, greaterThanOrEqualTo(4));
    });
  });

  group('getAvailableTopics - minimum 4 topics guarantee', () {
    for (final board in Board.values) {
      for (int grade = 0; grade <= 12; grade++) {
        test('${board.label} grade $grade has at least 4 topics', () {
          final topics = getAvailableTopics(board, grade);
          expect(
            topics.length,
            greaterThanOrEqualTo(4),
            reason: '${board.label} grade $grade returned only ${topics.length} topics: $topics',
          );
        });
      }
    }
  });

  group('getAvailableTopics - all boards return topics', () {
    test('CBSE returns non-empty topics for every grade', () {
      for (int grade = 0; grade <= 12; grade++) {
        final topics = getAvailableTopics(Board.cbse, grade);
        expect(topics, isNotEmpty, reason: 'CBSE grade $grade returned empty');
      }
    });

    test('IB returns non-empty topics for every grade', () {
      for (int grade = 0; grade <= 12; grade++) {
        final topics = getAvailableTopics(Board.ib, grade);
        expect(topics, isNotEmpty, reason: 'IB grade $grade returned empty');
      }
    });

    test('Cambridge returns non-empty topics for every grade', () {
      for (int grade = 0; grade <= 12; grade++) {
        final topics = getAvailableTopics(Board.cambridge, grade);
        expect(topics, isNotEmpty, reason: 'Cambridge grade $grade returned empty');
      }
    });
  });

  group('getAvailableTopics - higher grades differ from lower grades', () {
    test('CBSE grade 12 has topics not in grade 1', () {
      final low = getAvailableTopics(Board.cbse, 1);
      final high = getAvailableTopics(Board.cbse, 12);
      // High grades should have advanced topics
      expect(high.difference(low), isNotEmpty,
          reason: 'Grade 12 should have topics not available in grade 1');
    });

    test('IB grade 11 has topics not in grade 2', () {
      final low = getAvailableTopics(Board.ib, 2);
      final high = getAvailableTopics(Board.ib, 11);
      expect(high.difference(low), isNotEmpty,
          reason: 'Grade 11 should have topics not available in grade 2');
    });

    test('Cambridge grade 10 has topics not in grade 0', () {
      final low = getAvailableTopics(Board.cambridge, 0);
      final high = getAvailableTopics(Board.cambridge, 10);
      expect(high.difference(low), isNotEmpty,
          reason: 'Grade 10 should have topics not available in kindergarten');
    });

    test('advanced topics like calculus only appear in high grades', () {
      // Calculus should not be in grade 5 for any board
      for (final board in Board.values) {
        final grade5Topics = getAvailableTopics(board, 5);
        expect(grade5Topics.contains('calculus'), isFalse,
            reason: '${board.label} grade 5 should not have calculus');
      }
    });
  });
}
