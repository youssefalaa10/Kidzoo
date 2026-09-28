import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/scoring/star_rating.dart';
import 'package:kidzo/core/shared/widgets/kid_result_view.dart';

/// The three shapes every game's star rule reduces to.
void main() {
  group('fromScore', () {
    test('rates at the 0.9 and 0.6 boundaries', () {
      expect(StarRating.fromScore(score: 90, maxScore: 100), 3);
      expect(StarRating.fromScore(score: 89, maxScore: 100), 2);
      expect(StarRating.fromScore(score: 60, maxScore: 100), 2);
      expect(StarRating.fromScore(score: 59, maxScore: 100), 1);
    });

    test('never returns zero, even for a score of nothing', () {
      // A child who finished deserves a star. Nought out of three reads as a
      // failure at the exact moment the app should be congratulating them.
      expect(StarRating.fromScore(score: 0, maxScore: 100), 1);
    });

    test('falls back to one star when there is no maximum', () {
      expect(StarRating.fromScore(score: 500, maxScore: 0), 1);
      expect(StarRating.fromScore(score: 500, maxScore: -1), 1);
    });

    test('honours custom thresholds', () {
      expect(
        StarRating.fromScore(
            score: 80, maxScore: 100, threeStarAt: 0.75, twoStarAt: 0.5),
        3,
      );
    });
  });

  group('fromDuration', () {
    test('rates on par, then twice par', () {
      expect(StarRating.fromDuration(seconds: 30, parSeconds: 40), 3);
      expect(StarRating.fromDuration(seconds: 40, parSeconds: 40), 3);
      expect(StarRating.fromDuration(seconds: 41, parSeconds: 40), 2);
      expect(StarRating.fromDuration(seconds: 80, parSeconds: 40), 2);
      expect(StarRating.fromDuration(seconds: 81, parSeconds: 40), 1);
    });

    test('falls back to one star when par is meaningless', () {
      expect(StarRating.fromDuration(seconds: 10, parSeconds: 0), 1);
    });
  });

  group('KidResultView.starsFor still behaves as it always did', () {
    test('agrees with fromScore at every boundary', () {
      // This delegation is the only change made to a shipped celebration, so
      // the old thresholds are asserted directly rather than via the new API.
      expect(KidResultView.starsFor(90, 100), 3);
      expect(KidResultView.starsFor(89, 100), 2);
      expect(KidResultView.starsFor(60, 100), 2);
      expect(KidResultView.starsFor(59, 100), 1);
      expect(KidResultView.starsFor(5, 0), 1);
    });
  });
}
