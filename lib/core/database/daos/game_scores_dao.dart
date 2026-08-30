import 'package:drift/drift.dart';
import '../config.dart';
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
}
