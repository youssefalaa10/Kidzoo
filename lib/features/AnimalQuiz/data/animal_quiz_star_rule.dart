import 'package:kidzo/core/scoring/star_rating.dart';

/// Stars for a finished animal quiz, rated on the score that survived.
///
/// Every wrong tap costs points, so a child who names every animal first time
/// finishes on the full total and anything less is already reflected in the
/// score. That makes a plain ratio the honest measure here.
class AnimalQuizStarRule {
  const AnimalQuizStarRule._();

  /// The best score obtainable at this tier: every animal matched with no
  /// penalties. 50, 120 and 240 for the three tiers.
  static int maxScoreFor({
    required int pointsPerCorrectMatch,
    required int animalCount,
  }) =>
      pointsPerCorrectMatch * animalCount;

  static int rate({required int score, required int maxScore}) =>
      StarRating.fromScore(score: score, maxScore: maxScore);
}
