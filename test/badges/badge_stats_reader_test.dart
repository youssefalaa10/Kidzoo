import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/badge_stats_snapshot.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';

/// Turning rows into the numbers the badge rules judge by.
void main() {
  late AppDatabase database;
  late GameScoresDao gameScoresDao;
  late StoryDao storyDao;
  late BadgeStatsReader reader;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    gameScoresDao = GameScoresDao(database);
    storyDao = StoryDao(database);
    reader = BadgeStatsReader(
      gameScoresDao: gameScoresDao,
      storyDao: storyDao,
    );
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  Future<void> addScore({
    required String gameKey,
    required int score,
    int? level,
    int? stars,
    int? maxScore,
    DateTime? playedAt,
  }) {
    return gameScoresDao.insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: gameKey,
      score: score,
      level: Value<int?>(level),
      starsEarned: Value<int?>(stars),
      maxScore: Value<int?>(maxScore),
      playedAt: playedAt == null ? const Value.absent() : Value(playedAt),
    ));
  }

  test('a brand new profile reads as all zeroes', () async {
    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.totalPlays, 0);
    expect(stats.totalScore, 0);
    expect(stats.totalStars, 0);
    expect(stats.currentStreak, 0);
    expect(stats.hasPerfectScore, isFalse);
    expect(stats.storyNodesCompleted, 0);
  });

  test('totals and per-game bests come from the score rows', () async {
    await addScore(gameKey: 'puzzle', score: 40, level: 1, stars: 1);
    await addScore(gameKey: 'puzzle', score: 90, level: 2, stars: 3);
    await addScore(gameKey: 'math_game', score: 80, stars: 2);
    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.totalPlays, 3);
    expect(stats.totalScore, 210);
    expect(stats.bestScore, 90);
    expect(stats.playsAcross(const <String>{'puzzle'}), 2);
    expect(stats.bestScoreFor('puzzle'), 90);
    expect(stats.bestStarsFor('puzzle'), 3);
    expect(stats.bestLevelFor('puzzle'), 2);
    expect(stats.bestLevelFor('math_game'), 0);
  });

  test('stars fall back to the old rule for rows written before they existed',
      () async {
    // Counting a null starsEarned as zero would make an existing child's star
    // total *drop* on upgrade, which is the one thing a rewards screen must
    // never do.
    await addScore(gameKey: 'fruits', score: 95);
    await addScore(gameKey: 'fruits', score: 20);
    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.totalStars, 1);
  });

  test('a real star count wins over the fallback', () async {
    await addScore(gameKey: 'fruits', score: 95, stars: 3);
    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.totalStars, 3);
  });

  test('hasPerfectScore needs the run to hit its own maximum', () async {
    await addScore(gameKey: 'puzzle', score: 99, maxScore: 100);
    expect((await reader.readSnapshot(profileId)).hasPerfectScore, isFalse);
    await addScore(gameKey: 'puzzle', score: 100, maxScore: 100);
    expect((await reader.readSnapshot(profileId)).hasPerfectScore, isTrue);
  });

  test('a high score with no known maximum is not perfect', () async {
    await addScore(gameKey: 'maze_game', score: 100000);
    expect((await reader.readSnapshot(profileId)).hasPerfectScore, isFalse);
  });

  test('the streak counts days, not plays', () async {
    final DateTime today = DateTime.now();
    await addScore(gameKey: 'fruits', score: 10, playedAt: today);
    await addScore(gameKey: 'fruits', score: 10, playedAt: today);
    await addScore(
      gameKey: 'fruits',
      score: 10,
      playedAt: today.subtract(const Duration(days: 1)),
    );
    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.currentStreak, 2);
  });

  test('story progress comes from the story tables', () async {
    await storyDao.saveNodeResult(
      profileId: profileId,
      adventureId: 'jungle',
      nodeId: 'n1',
      completion: 'completed',
      hintsUsed: 0,
    );
    await storyDao.saveNodeResult(
      profileId: profileId,
      adventureId: 'jungle',
      nodeId: 'n2',
      completion: 'completed',
      hintsUsed: 2,
    );
    await storyDao.saveNodeResult(
      profileId: profileId,
      adventureId: 'jungle',
      nodeId: 'n3',
      completion: 'abandoned',
    );
    await storyDao.grantReward(
      profileId: profileId,
      rewardId: 'green_page',
      adventureId: 'jungle',
    );
    await storyDao.saveResumePoint(
      profileId: profileId,
      adventureId: 'jungle',
      nodeId: 'n1',
    );
    await storyDao.markChapterCompleted(
      profileId: profileId,
      adventureId: 'jungle',
    );

    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.storyNodesCompleted, 2);
    expect(stats.storyNodesWithoutHints, 1);
    expect(stats.storyPagesFound, 1);
    expect(stats.adventuresStarted, 1);
    expect(stats.adventuresCompleted, 1);
  });

  test('another profile does not leak in', () async {
    final int sibling = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Sibling'),
        );
    await gameScoresDao.insertScore(GameScoresCompanion.insert(
      profileId: sibling,
      gameKey: 'puzzle',
      score: 900,
    ));
    final BadgeStatsSnapshot stats = await reader.readSnapshot(profileId);
    expect(stats.totalPlays, 0);
    expect(stats.totalScore, 0);
  });
}
