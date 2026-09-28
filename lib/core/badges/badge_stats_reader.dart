import 'package:kidzo/core/badges/badge_stats_snapshot.dart';
import 'package:kidzo/core/badges/play_streak_calculator.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';

/// Builds a [BadgeStatsSnapshot] from what is actually in the database.
///
/// Four reads folded in Dart rather than SQL aggregates, matching how the rest
/// of this codebase queries: the row counts here are in the hundreds, and
/// keeping the arithmetic in Dart is what lets every badge rule be tested
/// without a database at all.
class BadgeStatsReader {
  const BadgeStatsReader({
    required this.gameScoresDao,
    required this.storyDao,
    this.streakCalculator = const PlayStreakCalculator(),
  });

  final GameScoresDao gameScoresDao;
  final StoryDao storyDao;
  final PlayStreakCalculator streakCalculator;

  /// Score at or above which a pre-v3 row counts as one star.
  ///
  /// Rows written before `starsEarned` existed leave it null. Treating those
  /// as zero stars would make an existing child's star count *drop* the moment
  /// they upgrade, which is the one thing a rewards screen must never do. This
  /// is the threshold the Profile has always used for its star tally, kept so
  /// the number does not move.
  static const int legacyStarScore = 80;

  Future<BadgeStatsSnapshot> readSnapshot(int profileId) async {
    final List<GameScore> scores =
        await gameScoresDao.getScoresForProfile(profileId);
    final List<StoryNodeProgressData> nodes =
        await storyDao.allNodesFor(profileId);
    final List<StoryReward> rewards = await storyDao.rewardsFor(profileId);
    final List<StoryChapterProgressData> chapters =
        await storyDao.chaptersFor(profileId);

    final Map<String, int> plays = <String, int>{};
    final Map<String, int> bestScores = <String, int>{};
    final Map<String, int> bestStars = <String, int>{};
    final Map<String, int> bestLevels = <String, int>{};
    int totalScore = 0;
    int totalStars = 0;
    int bestScore = 0;
    bool hasPerfectScore = false;

    for (final GameScore row in scores) {
      totalScore += row.score;
      if (row.score > bestScore) {
        bestScore = row.score;
      }
      totalStars += row.starsEarned ??
          (row.score >= legacyStarScore ? 1 : 0);
      final int? maxScore = row.maxScore;
      if (maxScore != null && maxScore > 0 && row.score >= maxScore) {
        hasPerfectScore = true;
      }
      plays[row.gameKey] = (plays[row.gameKey] ?? 0) + 1;
      if (row.score > (bestScores[row.gameKey] ?? 0)) {
        bestScores[row.gameKey] = row.score;
      }
      final int stars = row.starsEarned ?? 0;
      if (stars > (bestStars[row.gameKey] ?? 0)) {
        bestStars[row.gameKey] = stars;
      }
      final int? level = row.level;
      if (level != null && level > (bestLevels[row.gameKey] ?? 0)) {
        bestLevels[row.gameKey] = level;
      }
    }

    return BadgeStatsSnapshot(
      totalScore: totalScore,
      totalPlays: scores.length,
      bestScore: bestScore,
      totalStars: totalStars,
      currentStreak: streakCalculator.countConsecutiveDays(
        scores.map((GameScore row) => row.playedAt).toList(growable: false),
      ),
      playsByGameKey: plays,
      bestScoreByGameKey: bestScores,
      bestStarsByGameKey: bestStars,
      bestLevelByGameKey: bestLevels,
      hasPerfectScore: hasPerfectScore,
      storyNodesCompleted: nodes
          .where((StoryNodeProgressData n) => n.completion == 'completed')
          .length,
      storyNodesWithoutHints: nodes
          .where((StoryNodeProgressData n) =>
              n.completion == 'completed' && n.hintsUsed == 0)
          .length,
      storyPagesFound: rewards.length,
      adventuresStarted: chapters.length,
      adventuresCompleted: chapters
          .where((StoryChapterProgressData c) => c.isCompleted)
          .length,
    );
  }
}
