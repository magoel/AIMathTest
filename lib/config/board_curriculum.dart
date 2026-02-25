enum Board {
  cbse,
  ib,
  cambridge;

  String get label {
    switch (this) {
      case Board.cbse:
        return 'CBSE';
      case Board.ib:
        return 'IB';
      case Board.cambridge:
        return 'Cambridge';
    }
  }

  String get description {
    switch (this) {
      case Board.cbse:
        return 'Central Board of Secondary Education';
      case Board.ib:
        return 'International Baccalaureate';
      case Board.cambridge:
        return 'Cambridge International';
    }
  }
}

/// Returns topics introduced in the window [grade-2 .. grade+1].
/// Guarantees at least 4 topics by expanding the window downward
/// into earlier grades if needed.
/// Grade: 0 = Kindergarten, 1-12 = Grade 1-12.
Set<String> getAvailableTopics(Board board, int grade) {
  final maxGrade = (grade + 1).clamp(0, 12);
  final topSet = _curriculumMap[board]![maxGrade]!;

  // For K-2 students, show the full cumulative set
  if (grade <= 2) return topSet;

  // Start with the default window: exclude topics from (grade-3) and below
  var belowWindow = (grade - 3).clamp(0, 12);
  var excludeSet = _curriculumMap[board]![belowWindow]!;
  var windowed = topSet.difference(excludeSet);

  // Expand window downward until we have at least 4 topics
  while (windowed.length < 4 && belowWindow > 0) {
    belowWindow--;
    excludeSet = _curriculumMap[board]![belowWindow]!;
    windowed = topSet.difference(excludeSet);
  }

  // If still under 4, return the full cumulative set
  return windowed.length >= 4 ? windowed : topSet;
}

// Base topics available from kindergarten for most boards
const _kBasics = {'addition', 'subtraction', 'word_problems', 'geometry'};

const Map<Board, Map<int, Set<String>>> _curriculumMap = {
  // ── CBSE ──────────────────────────────────────────────────────────────
  Board.cbse: {
    0: {..._kBasics, 'measurement'},
    1: {..._kBasics, 'measurement'},
    2: {..._kBasics, 'measurement'},
    3: {..._kBasics, 'measurement', 'multiplication', 'division'},
    4: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling'},
    5: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling'},
    6: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion'},
    7: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    8: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    9: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry'},
    10: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry'},
    11: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry', 'calculus'},
    12: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry', 'calculus'},
  },

  // ── IB ────────────────────────────────────────────────────────────────
  Board.ib: {
    0: {..._kBasics, 'measurement'},
    1: {..._kBasics, 'measurement'},
    2: {..._kBasics, 'measurement'},
    3: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'data_handling'},
    4: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling'},
    5: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    6: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    7: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    8: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'trigonometry'},
    9: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'trigonometry'},
    10: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'trigonometry'},
    11: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'trigonometry', 'calculus'},
    12: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'trigonometry', 'calculus'},
  },

  // ── Cambridge ─────────────────────────────────────────────────────────
  Board.cambridge: {
    0: {..._kBasics},
    1: {..._kBasics},
    2: {..._kBasics, 'measurement', 'multiplication', 'division'},
    3: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'data_handling'},
    4: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'percentages', 'data_handling'},
    5: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'ratio_proportion', 'probability'},
    6: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    7: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    8: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability'},
    9: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'trigonometry'},
    10: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry'},
    11: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry'},
    12: {..._kBasics, 'measurement', 'multiplication', 'division', 'fractions', 'decimals', 'percentages', 'data_handling', 'algebra', 'ratio_proportion', 'probability', 'number_systems', 'trigonometry', 'calculus'},
  },
};
