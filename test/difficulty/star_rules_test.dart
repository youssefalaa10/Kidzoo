import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/AnimalQuiz/data/animal_quiz_star_rule.dart';
import 'package:kidzo/features/ColorMemoryGame/data/color_memory_star_rule.dart';
import 'package:kidzo/features/MathGame/Data/math_star_rule.dart';
import 'package:kidzo/features/MazeGame/data/maze_star_rule.dart';
import 'package:kidzo/features/MemoryGame/data/memory_star_rule.dart';
import 'package:kidzo/features/Puzzle/data/puzzle_star_rule.dart';

/// Each game's star rule, at its boundaries.
///
/// These are the numbers a child actually sees on the picker, and three of the
/// six games can only be rated on time or on turns because finishing them is
/// unconditional. Pinning the thresholds here keeps that reasoning visible.
void main() {
  group('Memory: turns, not score', () {
    test('perfect recall is three stars', () {
      // moves == totalPairs is a flawless run: every pair found first try.
      expect(MemoryStarRule.rate(totalPairs: 8, moves: 8), 3);
    });

    test('the three-star boundary sits at 0.75', () {
      expect(MemoryStarRule.rate(totalPairs: 8, moves: 10), 3);
      expect(MemoryStarRule.rate(totalPairs: 8, moves: 11), 2);
    });

    test('the two-star boundary sits at 0.5', () {
      expect(MemoryStarRule.rate(totalPairs: 8, moves: 16), 2);
      expect(MemoryStarRule.rate(totalPairs: 8, moves: 17), 1);
    });

    test('a very long game still earns a star', () {
      expect(MemoryStarRule.rate(totalPairs: 8, moves: 200), 1);
    });

    test('degenerate input does not divide by zero', () {
      expect(MemoryStarRule.rate(totalPairs: 0, moves: 0), 1);
      expect(MemoryStarRule.scoreFor(totalPairs: 0, moves: 0), 0);
    });

    test('score is a 0-100 figure', () {
      expect(MemoryStarRule.scoreFor(totalPairs: 8, moves: 8), 100);
      expect(MemoryStarRule.scoreFor(totalPairs: 8, moves: 16), 50);
    });
  });

  group('Math: wrong taps', () {
    test('a clean round is three stars', () {
      expect(MathStarRule.rate(wrongAttempts: 0), 3);
    });

    test('rates down as wrong taps accumulate', () {
      expect(MathStarRule.rate(wrongAttempts: 1), 2);
      expect(MathStarRule.rate(wrongAttempts: 2), 2);
      expect(MathStarRule.rate(wrongAttempts: 3), 1);
    });

    test('score floors at zero rather than going negative', () {
      expect(MathStarRule.scoreFor(wrongAttempts: 99), 0);
      expect(MathStarRule.rate(wrongAttempts: 99), 1);
    });
  });

  group('Maze: one star for finishing, two to earn', () {
    test('covers all four combinations', () {
      expect(
        MazeStarRule.rate(collectedAllStars: true, touchedWall: false),
        3,
      );
      expect(
        MazeStarRule.rate(collectedAllStars: true, touchedWall: true),
        2,
      );
      expect(
        MazeStarRule.rate(collectedAllStars: false, touchedWall: false),
        2,
      );
      expect(
        MazeStarRule.rate(collectedAllStars: false, touchedWall: true),
        1,
      );
    });

    test('a slow escape never scores below zero', () {
      expect(
        MazeStarRule.scoreFor(timeElapsedSeconds: 9999, starsCollected: 0),
        0,
      );
    });

    test('collected stars add to the score', () {
      expect(
        MazeStarRule.scoreFor(timeElapsedSeconds: 100, starsCollected: 3),
        800,
      );
    });
  });

  group('Puzzle: time against a per-piece budget', () {
    test('at or under par is three stars', () {
      // 4 pieces, 6 seconds each.
      expect(PuzzleStarRule.rate(pieceCount: 4, elapsedSeconds: 24), 3);
      expect(PuzzleStarRule.rate(pieceCount: 4, elapsedSeconds: 25), 2);
    });

    test('twice par is still two stars', () {
      expect(PuzzleStarRule.rate(pieceCount: 4, elapsedSeconds: 48), 2);
      expect(PuzzleStarRule.rate(pieceCount: 4, elapsedSeconds: 49), 1);
    });

    test('the nine-piece puzzle gets a proportionally longer budget', () {
      expect(PuzzleStarRule.parSecondsFor(9), 54);
      expect(PuzzleStarRule.maxScoreFor(9), 225);
    });
  });

  group('Colour memory: time against a per-step budget', () {
    test('the step count grows with the sequence each round', () {
      // Level 1: 2 rounds starting at length 3 -> 3 + 4 = 7 taps.
      expect(ColorMemoryStarRule.parSecondsFor(1), 21);
      // Level 2: 3 rounds from 4 -> 4 + 5 + 6 = 15 taps.
      expect(ColorMemoryStarRule.parSecondsFor(2), 45);
      // Level 3: 4 rounds from 5 -> 5 + 6 + 7 + 8 = 26 taps.
      expect(ColorMemoryStarRule.parSecondsFor(3), 78);
    });

    test('rates on par and twice par', () {
      expect(ColorMemoryStarRule.rate(level: 1, elapsedSeconds: 21), 3);
      expect(ColorMemoryStarRule.rate(level: 1, elapsedSeconds: 22), 2);
      expect(ColorMemoryStarRule.rate(level: 1, elapsedSeconds: 42), 2);
      expect(ColorMemoryStarRule.rate(level: 1, elapsedSeconds: 43), 1);
    });
  });

  group('Animal quiz: the score that survived the penalties', () {
    test('the maximum is every animal matched cleanly', () {
      // The three tiers award 10, 15 and 20 a match over 5, 8 and 12 animals.
      expect(
        AnimalQuizStarRule.maxScoreFor(
            pointsPerCorrectMatch: 10, animalCount: 5),
        50,
      );
      expect(
        AnimalQuizStarRule.maxScoreFor(
            pointsPerCorrectMatch: 15, animalCount: 8),
        120,
      );
      expect(
        AnimalQuizStarRule.maxScoreFor(
            pointsPerCorrectMatch: 20, animalCount: 12),
        240,
      );
    });

    test('a flawless run is three stars', () {
      expect(AnimalQuizStarRule.rate(score: 50, maxScore: 50), 3);
    });

    test('rates down as penalties bite', () {
      expect(AnimalQuizStarRule.rate(score: 44, maxScore: 50), 2);
      expect(AnimalQuizStarRule.rate(score: 29, maxScore: 50), 1);
    });
  });
}
