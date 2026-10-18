import 'package:kidzo/core/scoring/star_rating.dart';

/// Stars for a finished memory game, rated on how few turns it took.
///
/// A memory game can only end one way — every pair matched — so a score ratio
/// would hand out three stars every time. Turns are the real measure: perfect
/// play is one turn per pair.
class MemoryStarRule {
  const MemoryStarRule._();

  /// The thresholds are deliberately gentler than the 0.9 / 0.6 default.
  /// Perfect recall from a four-year-old is not the bar; remembering rather
  /// more than half of what they turned over is.
  static int rate({required int totalPairs, required int moves}) {
    if (moves <= 0 || totalPairs <= 0) {
      return 1;
    }
    return StarRating.fromRatio(
      totalPairs / moves,
      threeStarAt: 0.75,
      twoStarAt: 0.5,
    );
  }

  /// A 0-100 figure for the score row, so Memory is comparable with the games
  /// that count points.
  static int scoreFor({required int totalPairs, required int moves}) {
    if (moves <= 0 || totalPairs <= 0) {
      return 0;
    }
    return ((totalPairs / moves) * 100).round().clamp(0, 100);
  }
}
