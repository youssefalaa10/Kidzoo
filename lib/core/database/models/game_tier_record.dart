/// What a profile has done at one difficulty tier of one game.
///
/// Built by `GameScoresDao.getTierRecords`, which folds the score rows for a
/// single `gameKey` down to one of these per level.
class GameTierRecord {
  const GameTierRecord({
    required this.level,
    required this.bestStars,
    required this.bestScore,
    required this.plays,
  });

  final int level;
  final int bestStars;
  final int bestScore;

  /// How many winning runs this tier has. The existence of this record at all
  /// is what unlocks the tier above; see `getTierRecords` for why.
  final int plays;
}
