import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';

/// The conversion between the enum and the `int level` every game already
/// takes. Worth pinning because the whole tier feature is that one mapping.
void main() {
  group('level', () {
    test('maps the three tiers onto 1, 2 and 3', () {
      expect(KidDifficulty.easy.level, 1);
      expect(KidDifficulty.medium.level, 2);
      expect(KidDifficulty.hard.level, 3);
    });

    test('round-trips through fromLevel', () {
      for (final KidDifficulty difficulty in KidDifficulty.values) {
        expect(KidDifficulty.fromLevel(difficulty.level), difficulty);
      }
    });
  });

  group('fromLevel clamps rather than throwing', () {
    test('levels at or below 1 are easy', () {
      expect(KidDifficulty.fromLevel(1), KidDifficulty.easy);
      expect(KidDifficulty.fromLevel(0), KidDifficulty.easy);
      expect(KidDifficulty.fromLevel(-7), KidDifficulty.easy);
    });

    test('levels above 3 are hard', () {
      // Puzzle's free-play mode uses level 4, and a score row written by an
      // older build can hold anything at all.
      expect(KidDifficulty.fromLevel(4), KidDifficulty.hard);
      expect(KidDifficulty.fromLevel(99), KidDifficulty.hard);
    });
  });

  group('next and previous', () {
    test('step through the tiers', () {
      expect(KidDifficulty.easy.next, KidDifficulty.medium);
      expect(KidDifficulty.medium.next, KidDifficulty.hard);
      expect(KidDifficulty.hard.previous, KidDifficulty.medium);
      expect(KidDifficulty.medium.previous, KidDifficulty.easy);
    });

    test('stop at the ends', () {
      // hard.next being null is what hides the "Next level" button, and
      // easy.previous being null is why easy needs no unlock check.
      expect(KidDifficulty.hard.next, isNull);
      expect(KidDifficulty.easy.previous, isNull);
    });
  });

  test('nameKey matches the existing localization keys', () {
    expect(KidDifficulty.easy.nameKey, 'easy');
    expect(KidDifficulty.medium.nameKey, 'medium');
    expect(KidDifficulty.hard.nameKey, 'hard');
  });
}
