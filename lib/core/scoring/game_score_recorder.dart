import 'package:drift/drift.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';

/// The one place a finished game becomes a row.
///
/// Before this existed, five games each repeated the same fifteen lines —
/// resolve the profile, build a companion, insert, swallow the error — and
/// twenty others recorded nothing at all, which is why three of the Profile's
/// badges could never unlock. Games now call one method.
///
/// Every failure is swallowed. A child has just finished something and is
/// looking at their stars; a database problem is not their problem, and an
/// exception thrown here would tear down the celebration.
class GameScoreRecorder {
  const GameScoreRecorder({
    required this.gameScoresDao,
    required this.profileDao,
    this.badgeService,
  });

  final GameScoresDao gameScoresDao;
  final ProfileDao profileDao;

  /// Evaluated right after a row lands, so the twelve activities that report
  /// through here get badge checking for free. Nullable so a test can build a
  /// recorder without one.
  final BadgeService? badgeService;

  /// Records a won run at a difficulty tier.
  ///
  /// Only call this on a win: the presence of a row with this level is what
  /// unlocks the next tier. See `GameScoresDao.getTierRecords`.
  Future<void> recordWin({
    required String gameKey,
    required KidDifficulty difficulty,
    required int score,
    required int stars,
    int? maxScore,
    int? durationSeconds,
  }) {
    return recordPlay(
      gameKey: gameKey,
      score: score,
      level: difficulty.level,
      stars: stars,
      maxScore: maxScore,
      durationSeconds: durationSeconds,
    );
  }

  /// Records a finished run for a game that has no difficulty tiers.
  ///
  /// [level] stays null for these, which is what keeps them out of the tier
  /// query without needing a second table or a flag column.
  Future<void> recordPlay({
    required String gameKey,
    required int score,
    int? level,
    int? stars,
    int? maxScore,
    int? durationSeconds,
  }) async {
    try {
      final List<Profile> profiles = await profileDao.getAllProfiles();
      if (profiles.isEmpty) {
        return;
      }
      await gameScoresDao.insertScore(GameScoresCompanion.insert(
        profileId: profiles.first.id,
        gameKey: gameKey,
        score: score,
        level: Value<int?>(level),
        starsEarned: Value<int?>(stars),
        maxScore: Value<int?>(maxScore),
        durationSeconds: Value<int?>(durationSeconds),
      ));
      await badgeService?.evaluateForProfile(profiles.first.id);
    } catch (_) {
      // Deliberately silent: see the class doc.
    }
  }
}
