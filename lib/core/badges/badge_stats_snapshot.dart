import 'package:flutter/foundation.dart';

/// Everything the badge rules are allowed to know, at one moment in time.
///
/// Deliberately holds no database types and no `BuildContext`, which is what
/// lets every unlock rule be tested as a pure function with no widget tree and
/// no SQLite. It is also the single definition of the numbers the Profile
/// shows: before this existed, the Profile screen and the badge rules each
/// computed "total score" and "stars" their own way, and disagreed.
@immutable
class BadgeStatsSnapshot {
  const BadgeStatsSnapshot({
    required this.totalScore,
    required this.totalPlays,
    required this.bestScore,
    required this.totalStars,
    required this.currentStreak,
    required this.playsByGameKey,
    required this.bestScoreByGameKey,
    required this.bestStarsByGameKey,
    required this.bestLevelByGameKey,
    required this.hasPerfectScore,
    required this.storyNodesCompleted,
    required this.storyNodesWithoutHints,
    required this.storyPagesFound,
    required this.adventuresStarted,
    required this.adventuresCompleted,
  });

  final int totalScore;

  /// Finished runs, across every activity that records one.
  final int totalPlays;
  final int bestScore;
  final int totalStars;

  /// Consecutive days up to and including today (or yesterday, if today has
  /// not been played yet).
  final int currentStreak;

  final Map<String, int> playsByGameKey;
  final Map<String, int> bestScoreByGameKey;
  final Map<String, int> bestStarsByGameKey;

  /// The highest difficulty tier cleared per game, as an `int level`.
  final Map<String, int> bestLevelByGameKey;

  /// Whether any run ever hit its own maximum score.
  final bool hasPerfectScore;

  final int storyNodesCompleted;

  /// Story beats finished without asking for a hint.
  final int storyNodesWithoutHints;
  final int storyPagesFound;
  final int adventuresStarted;
  final int adventuresCompleted;

  int playsAcross(Iterable<String> gameKeys) => gameKeys.fold<int>(
        0,
        (int sum, String key) => sum + (playsByGameKey[key] ?? 0),
      );

  int bestScoreFor(String gameKey) => bestScoreByGameKey[gameKey] ?? 0;

  int bestStarsFor(String gameKey) => bestStarsByGameKey[gameKey] ?? 0;

  int bestLevelFor(String gameKey) => bestLevelByGameKey[gameKey] ?? 0;

  /// How many of [gameKeys] have been played at least once.
  int distinctPlayedAmong(Iterable<String> gameKeys) => gameKeys
      .where((String key) => (playsByGameKey[key] ?? 0) > 0)
      .length;

  bool get hasClearedAnyHardTier =>
      bestLevelByGameKey.values.any((int level) => level >= 3);

  bool get hasAnyThreeStar =>
      bestStarsByGameKey.values.any((int stars) => stars >= 3);

  /// A child who has done nothing at all. Used as the Profile's loading state
  /// and as the baseline every rule test starts from.
  static const BadgeStatsSnapshot empty = BadgeStatsSnapshot(
    totalScore: 0,
    totalPlays: 0,
    bestScore: 0,
    totalStars: 0,
    currentStreak: 0,
    playsByGameKey: <String, int>{},
    bestScoreByGameKey: <String, int>{},
    bestStarsByGameKey: <String, int>{},
    bestLevelByGameKey: <String, int>{},
    hasPerfectScore: false,
    storyNodesCompleted: 0,
    storyNodesWithoutHints: 0,
    storyPagesFound: 0,
    adventuresStarted: 0,
    adventuresCompleted: 0,
  );
}
