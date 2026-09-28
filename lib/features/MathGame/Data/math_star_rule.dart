import 'package:kidzo/core/scoring/star_rating.dart';

/// Stars for a round of five maths questions, rated on wrong taps.
///
/// Every round ends with all five correct — a child cannot move on until they
/// answer correctly — so the only thing that separates a strong round from a
/// lucky one is how many wrong options were tried along the way.
class MathStarRule {
  const MathStarRule._();

  static const int questionsPerRound = 5;

  /// Five clean answers is three stars; roughly half is two; below that, one.
  static int rate({required int wrongAttempts}) => StarRating.fromScore(
        score: scoreFor(wrongAttempts: wrongAttempts),
        maxScore: questionsPerRound,
      );

  static int scoreFor({required int wrongAttempts}) =>
      (questionsPerRound - wrongAttempts).clamp(0, questionsPerRound);
}
