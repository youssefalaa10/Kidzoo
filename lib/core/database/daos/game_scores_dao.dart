import 'package:drift/drift.dart';
import '../config.dart';
import '../models/game_tier_record.dart';
import '../tables/game_scores_table.dart';

part 'game_scores_dao.g.dart';

@DriftAccessor(tables: [GameScores])
class GameScoresDao extends DatabaseAccessor<AppDatabase>
    with _$GameScoresDaoMixin {
  GameScoresDao(super.db);

  Future<List<GameScore>> getScoresForProfile(int profileId) =>
      (select(gameScores)..where((t) => t.profileId.equals(profileId))).get();

  Future<int> insertScore(GameScoresCompanion score) =>
      into(gameScores).insert(score);

  Future<int> getTotalScoreForProfile(int profileId) async {
    final query = select(gameScores)
      ..where((t) => t.profileId.equals(profileId));
    final scores = await query.get();
    return scores.fold<int>(0, (sum, item) => sum + item.score);
  }

  Stream<List<GameScore>> watchScoresForProfile(int profileId) =>
      (select(gameScores)..where((t) => t.profileId.equals(profileId))).watch();

  Future<List<GameScore>> getRecentScoresForProfile(
    int profileId, {
    int limit = 20,
  }) {
    final query = select(gameScores)
      ..where((t) => t.profileId.equals(profileId))
      ..orderBy(<OrderClauseGenerator<$GameScoresTable>>[
        (t) => OrderingTerm.desc(t.playedAt),
      ])
      ..limit(limit);
    return query.get();
  }

  /// One record per difficulty tier this profile has cleared in [gameKey].
  ///
  /// **The unlock invariant.** For the six tiered games a row with a non-null
  /// `level` is written *only on a win*. So "a record exists for level N" is
  /// exactly "tier N has been completed", and the predicate the picker uses to
  /// unlock the next tier is `plays > 0` — never `bestStars > 0`, because
  /// rows written before stars existed leave `starsEarned` null and would
  /// silently re-lock a tier the child had already finished.
  ///
  /// Rows with a null level are Adventure and legacy results; they are not
  /// tier evidence and are excluded.
  Future<List<GameTierRecord>> getTierRecords({
    required int profileId,
    required String gameKey,
  }) async {
    final GeneratedColumn<int> levelColumn = gameScores.level;
    final Expression<int> bestStars = gameScores.starsEarned.max();
    final Expression<int> bestScore = gameScores.score.max();
    final Expression<int> plays = gameScores.id.count();
    final JoinedSelectStatement<$GameScoresTable, GameScore> query =
        selectOnly(gameScores)
          ..addColumns(<Expression<Object>>[
            levelColumn,
            bestStars,
            bestScore,
            plays,
          ])
          ..where(gameScores.profileId.equals(profileId) &
              gameScores.gameKey.equals(gameKey) &
              gameScores.level.isNotNull())
          ..groupBy(<Expression<Object>>[levelColumn]);
    final List<TypedResult> rows = await query.get();
    return rows
        .map((TypedResult row) => GameTierRecord(
              level: row.read(levelColumn)!,
              bestStars: row.read(bestStars) ?? 0,
              bestScore: row.read(bestScore) ?? 0,
              plays: row.read(plays) ?? 0,
            ))
        .toList(growable: false);
  }
}
