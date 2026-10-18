/// How a finished run becomes one, two or three stars.
///
/// Every game scores differently — some count points, some count moves, some
/// can only be finished perfectly and so have to be rated on time instead — so
/// the rule lives with the game and this class holds only the three shapes
/// those rules reduce to. Keeping them here is what stops six games inventing
/// six slightly different definitions of "three stars".
///
/// The floor is always one star. A child who finished deserves a star; nought
/// out of three at the end of a game they just completed reads as a failure,
/// which is precisely the message this app avoids everywhere else.
class StarRating {
  const StarRating._();

  /// Points against a known maximum.
  ///
  /// The 0.9 / 0.6 thresholds are the ones `KidResultView.starsFor` has always
  /// used; they are the default so that moving that method onto this class
  /// changed no behaviour.
  static int fromScore({
    required int score,
    required int maxScore,
    double threeStarAt = 0.9,
    double twoStarAt = 0.6,
  }) {
    if (maxScore <= 0) {
      return 1;
    }
    return fromRatio(
      score / maxScore,
      threeStarAt: threeStarAt,
      twoStarAt: twoStarAt,
    );
  }

  /// A ratio where higher is better and 1.0 is a perfect run.
  static int fromRatio(
    double ratio, {
    double threeStarAt = 0.9,
    double twoStarAt = 0.6,
  }) {
    if (ratio >= threeStarAt) {
      return 3;
    }
    if (ratio >= twoStarAt) {
      return 2;
    }
    return 1;
  }

  /// Elapsed time against a par budget, where lower is better.
  ///
  /// For the games that can only be finished by finishing correctly — a puzzle
  /// is complete or it is not — so a points ratio would hand out three stars
  /// every time and mean nothing.
  static int fromDuration({
    required int seconds,
    required int parSeconds,
    double twoStarFactor = 2.0,
  }) {
    if (parSeconds <= 0) {
      return 1;
    }
    if (seconds <= parSeconds) {
      return 3;
    }
    if (seconds <= parSeconds * twoStarFactor) {
      return 2;
    }
    return 1;
  }
}
