import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/models/game_tier_record.dart';

/// `getTierRecords` against real SQLite.
///
/// This query is the entire unlock mechanism: the picker reads it to decide
/// which tiers are open. The cases that matter are the ones about rows it must
/// *not* count, because each of those would either lock a tier a child has
/// already cleared or open one they have not.
void main() {
  late AppDatabase database;
  late GameScoresDao dao;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = GameScoresDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  Future<void> insertRun({
    required int level,
    int score = 100,
    int? stars,
    String gameKey = 'memory_game',
    int? forProfile,
  }) {
    return dao.insertScore(GameScoresCompanion.insert(
      profileId: forProfile ?? profileId,
      gameKey: gameKey,
      score: score,
      level: Value<int?>(level),
      starsEarned: Value<int?>(stars),
    ));
  }

  test('a game never played has no records', () async {
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records, isEmpty);
  });

  test('one win produces one record for that tier', () async {
    await insertRun(level: 2, score: 140, stars: 2);
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records, hasLength(1));
    expect(records.single.level, 2);
    expect(records.single.plays, 1);
    expect(records.single.bestScore, 140);
    expect(records.single.bestStars, 2);
  });

  test('repeat plays of a tier keep the best, not the last', () async {
    await insertRun(level: 2, score: 140, stars: 3);
    await insertRun(level: 2, score: 60, stars: 1);
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records.single.plays, 2);
    expect(records.single.bestScore, 140);
    expect(records.single.bestStars, 3);
  });

  test('a row with no stars still counts as a play', () async {
    // The unlock invariant. Rows written before starsEarned existed leave it
    // null; gating on stars instead of plays would re-lock a tier the child
    // had already finished.
    await insertRun(level: 1, score: 30);
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records.single.plays, 1);
    expect(records.single.bestStars, 0);
  });

  test('rows with no level are excluded', () async {
    // Adventure and the non-tiered games write these. They are not evidence
    // that any tier was cleared.
    await dao.insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: 'memory_game',
      score: 500,
    ));
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records, isEmpty);
  });

  test('another game does not unlock this one', () async {
    await insertRun(level: 3, gameKey: 'puzzle');
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records, isEmpty);
  });

  test('another profile does not unlock this one', () async {
    final int sibling = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Sibling'),
        );
    await insertRun(level: 3, forProfile: sibling);
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records, isEmpty);
  });

  test('separate tiers produce separate records', () async {
    await insertRun(level: 1, score: 50, stars: 3);
    await insertRun(level: 2, score: 90, stars: 1);
    final List<GameTierRecord> records =
        await dao.getTierRecords(profileId: profileId, gameKey: 'memory_game');
    expect(records.map((GameTierRecord r) => r.level).toSet(), <int>{1, 2});
  });
}
