/// Stars for a finished maze: one for getting out, one for every extra.
///
/// Reaching the exit is the game, so it earns the first star outright. The
/// other two come from the two things a child can do beyond merely finishing:
/// pick up every star on the way, and get through without scraping a wall.
///
/// On Easy `requiredStars` is zero, so `hasCollectedAllStars` is trivially
/// true and a clean run scores three. That gradient is deliberate: the easiest
/// maze should be the one where three stars feels achievable.
class MazeStarRule {
  const MazeStarRule._();

  static int rate({
    required bool collectedAllStars,
    required bool touchedWall,
  }) {
    return 1 + (collectedAllStars ? 1 : 0) + (touchedWall ? 0 : 1);
  }

  /// A points figure for the score row: faster is worth more, and each star
  /// picked up is worth a flat bonus.
  static int scoreFor({
    required int timeElapsedSeconds,
    required int starsCollected,
  }) {
    final int speed = 600 - timeElapsedSeconds;
    return (speed < 0 ? 0 : speed) + 100 * starsCollected;
  }
}
