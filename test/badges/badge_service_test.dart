import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/badge_catalog.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/default_badge_catalog.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';

/// The locked-to-unlocked diff, which is what a pop-up fires on.
///
/// The contract that matters: evaluating twice with the same data must report
/// nothing the second time. Get that wrong and a child is congratulated for
/// "First Win" after every single game they ever play.
void main() {
  late AppDatabase database;
  late GameScoresDao gameScoresDao;
  late BadgeDao badgeDao;
  late BadgeService service;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    gameScoresDao = GameScoresDao(database);
    badgeDao = BadgeDao(database);
    final BadgeCatalog catalog = buildDefaultBadgeCatalog();
    service = BadgeService(
      badgeCatalog: catalog,
      badgeDao: badgeDao,
      badgeStatsReader: BadgeStatsReader(
        gameScoresDao: gameScoresDao,
        storyDao: StoryDao(database),
      ),
      profileDao: ProfileDao(database),
    );
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async {
    await service.dispose();
    await database.close();
  });

  Future<void> addScore({
    String gameKey = 'puzzle',
    int score = 50,
    int? level,
    int? stars,
  }) {
    return gameScoresDao.insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: gameKey,
      score: score,
      level: Value<int?>(level),
      starsEarned: Value<int?>(stars),
    ));
  }

  test('a child who has done nothing earns nothing', () async {
    expect(await service.evaluateForProfile(profileId), isEmpty);
  });

  test('the first finished game earns first_win', () async {
    await addScore();
    final List<BadgeDefinition> earned =
        await service.evaluateForProfile(profileId);
    expect(
      earned.map((BadgeDefinition d) => d.badgeId),
      contains('first_win'),
    );
  });

  test('evaluating again with the same data earns nothing', () async {
    await addScore();
    await service.evaluateForProfile(profileId);
    expect(
      await service.evaluateForProfile(profileId),
      isEmpty,
      reason: 'a badge is worth celebrating exactly once',
    );
  });

  test('the stream emits once, not twice', () async {
    final List<List<BadgeDefinition>> batches = <List<BadgeDefinition>>[];
    final dynamic subscription =
        service.earnedBadgeStream.listen(batches.add);
    await addScore();
    await service.evaluateForProfile(profileId);
    await service.evaluateForProfile(profileId);
    await Future<void>.delayed(Duration.zero);
    expect(batches, hasLength(1));
    await subscription.cancel();
  });

  test('a newly true rule is picked up on the next evaluation', () async {
    await addScore();
    await service.evaluateForProfile(profileId);
    // Clearing a Hard tier is new information.
    await addScore(level: 3, stars: 3);
    final List<BadgeDefinition> earned =
        await service.evaluateForProfile(profileId);
    final Iterable<String> ids =
        earned.map((BadgeDefinition d) => d.badgeId);
    expect(ids, contains('tier_climber'));
    expect(ids, contains('triple_star'));
    expect(ids, isNot(contains('first_win')));
  });

  test('celebrate: false records without emitting', () async {
    final List<List<BadgeDefinition>> batches = <List<BadgeDefinition>>[];
    final dynamic subscription =
        service.earnedBadgeStream.listen(batches.add);
    await addScore();
    final List<BadgeDefinition> earned =
        await service.evaluateForProfile(profileId, celebrate: false);
    await Future<void>.delayed(Duration.zero);
    expect(earned, isNotEmpty);
    expect(batches, isEmpty);
    expect(await badgeDao.earnedBadgeIdsFor(profileId),
        contains('first_win'));
    await subscription.cancel();
  });

  test('backfill populates the wall silently, once', () async {
    final List<List<BadgeDefinition>> batches = <List<BadgeDefinition>>[];
    final dynamic subscription =
        service.earnedBadgeStream.listen(batches.add);
    await addScore();
    await service.backfillSilently(profileId);
    await Future<void>.delayed(Duration.zero);
    expect(await badgeDao.badgeCountFor(profileId), greaterThan(0));
    expect(batches, isEmpty);

    // A second call must do nothing: the wall is no longer empty.
    final int countAfterFirst = await badgeDao.badgeCountFor(profileId);
    await addScore(level: 3, stars: 3);
    await service.backfillSilently(profileId);
    expect(await badgeDao.badgeCountFor(profileId), countAfterFirst);
    await subscription.cancel();
  });

  test('evaluateForCurrentProfile resolves the profile itself', () async {
    await addScore();
    final List<BadgeDefinition> earned =
        await service.evaluateForCurrentProfile();
    expect(
      earned.map((BadgeDefinition d) => d.badgeId),
      contains('first_win'),
    );
  });

  test('a database failure is swallowed, never thrown at the child', () async {
    await addScore();
    await database.close();
    expect(await service.evaluateForProfile(profileId), isEmpty);
    expect(await service.evaluateForCurrentProfile(), isEmpty);
    database = AppDatabase(NativeDatabase.memory());
  });
}
