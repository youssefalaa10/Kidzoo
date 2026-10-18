import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/default_badge_catalog.dart';
import 'package:kidzo/core/catalog/default_game_catalog.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/features/Profile/models/badge_view.dart';
import 'package:kidzo/features/Profile/models/recent_activity_entry.dart';
import 'package:kidzo/features/Profile/models/recent_activity_kind.dart';
import 'package:kidzo/features/Profile/profile_analytics_cubit.dart';
import 'package:kidzo/features/Profile/profile_analytics_state.dart';

/// What the Profile shows. There was no test for any of this before.
void main() {
  late AppDatabase database;
  late GameScoresDao gameScoresDao;
  late StoryDao storyDao;
  late BadgeDao badgeDao;
  late ProfileAnalyticsCubit cubit;
  late AppLocalizations l10n;
  late int profileId;

  setUpAll(() {
    // Built from disk rather than rootBundle: asset loading over the platform
    // channel stops resolving after the first test in a file.
    final Map<String, dynamic> decoded =
        json.decode(File('assets/lang/en.json').readAsStringSync())
            as Map<String, dynamic>;
    l10n = AppLocalizations(
      const Locale('en'),
      decoded.map((String key, dynamic value) =>
          MapEntry<String, String>(key, value.toString())),
    );
  });

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    gameScoresDao = GameScoresDao(database);
    storyDao = StoryDao(database);
    badgeDao = BadgeDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
    cubit = ProfileAnalyticsCubit(
      gameScoresDao: gameScoresDao,
      storyDao: storyDao,
      badgeDao: badgeDao,
      badgeCatalog: buildDefaultBadgeCatalog(),
      badgeStatsReader: BadgeStatsReader(
        gameScoresDao: gameScoresDao,
        storyDao: storyDao,
      ),
      gameCatalog: buildDefaultGameCatalog(),
      badgeService: BadgeService(
        badgeCatalog: buildDefaultBadgeCatalog(),
        badgeDao: badgeDao,
        badgeStatsReader: BadgeStatsReader(
          gameScoresDao: gameScoresDao,
          storyDao: storyDao,
        ),
        profileDao: ProfileDao(database),
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  Future<void> addScore({
    String gameKey = 'puzzle',
    int score = 50,
    int? level,
    int? stars,
    DateTime? playedAt,
  }) {
    return gameScoresDao.insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: gameKey,
      score: score,
      level: Value<int?>(level),
      starsEarned: Value<int?>(stars),
      playedAt: playedAt == null ? const Value.absent() : Value(playedAt),
    ));
  }

  Future<ProfileAnalyticsLoaded> loadState() async {
    await cubit.load(profileId, l10n);
    expect(cubit.state, isA<ProfileAnalyticsLoaded>());
    return cubit.state as ProfileAnalyticsLoaded;
  }

  test('a brand new profile loads with everything at zero', () async {
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.totalScore, 0);
    expect(state.gamesPlayed, 0);
    expect(state.stars, 0);
    expect(state.recentActivity, isEmpty);
    expect(state.storyNodesCompleted, 0);
  });

  test('the badge wall lists the whole catalog, all locked at first',
      () async {
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.badges, hasLength(21));
    expect(state.badgesEarned, 0);
    expect(
      state.badges.every((BadgeView badge) => !badge.isEarned),
      isTrue,
    );
  });

  test('badge titles are resolved, not left as keys', () async {
    final ProfileAnalyticsLoaded state = await loadState();
    final BadgeView firstWin = state.badges
        .firstWhere((BadgeView badge) => badge.badgeId == 'first_win');
    expect(firstWin.title, 'First Win');
    expect(firstWin.description, isNotEmpty);
  });

  test('playing earns a badge and stamps it with a date', () async {
    await addScore();
    final ProfileAnalyticsLoaded state = await loadState();
    final BadgeView firstWin = state.badges
        .firstWhere((BadgeView badge) => badge.badgeId == 'first_win');
    expect(firstWin.isEarned, isTrue);
    expect(firstWin.earnedAt, isNotNull);
    expect(state.badgesEarned, greaterThan(0));
  });

  test('headline numbers come from the score rows', () async {
    await addScore(score: 40, stars: 1);
    await addScore(score: 120, stars: 3);
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.totalScore, 160);
    expect(state.gamesPlayed, 2);
    expect(state.bestScore, 120);
    expect(state.stars, 4);
  });

  test('the star count is real stars, not a score threshold', () async {
    // The old screen counted rows scoring 80+, which disagreed with the
    // starsEarned the games now write.
    await addScore(score: 200, stars: 1);
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.stars, 1);
  });

  test('the activity feed names the game, newest first', () async {
    final DateTime now = DateTime.now();
    await addScore(
      gameKey: 'puzzle',
      score: 10,
      playedAt: now.subtract(const Duration(hours: 2)),
    );
    await addScore(gameKey: 'memory_game', score: 20, playedAt: now);
    final ProfileAnalyticsLoaded state = await loadState();
    final List<RecentActivityEntry> games = state.recentActivity
        .where((RecentActivityEntry e) => e.kind == RecentActivityKind.game)
        .toList();
    expect(games.first.title, 'Memory Game');
    expect(games[1].title, 'Puzzle');
  });

  test('earned badges appear in the activity feed too', () async {
    await addScore();
    final ProfileAnalyticsLoaded state = await loadState();
    expect(
      state.recentActivity
          .any((RecentActivityEntry e) => e.kind == RecentActivityKind.badge),
      isTrue,
    );
  });

  test('story progress reaches the Profile', () async {
    // None of this was visible here before: Adventure writes to its own
    // tables and nothing on this screen read them.
    await storyDao.saveNodeResult(
      profileId: profileId,
      adventureId: 'jungle',
      nodeId: 'n1',
      completion: 'completed',
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
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.storyNodesCompleted, 1);
    expect(state.storyPagesFound, 1);
    expect(state.adventuresCompleted, 1);
    expect(state.adventuresStarted, 1);
    expect(
      state.recentActivity.any(
          (RecentActivityEntry e) => e.kind == RecentActivityKind.storyNode),
      isTrue,
    );
  });

  test('the feed is capped so it stays scannable', () async {
    for (int index = 0; index < 20; index++) {
      await addScore(score: index);
    }
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.recentActivity.length, lessThanOrEqualTo(8));
  });

  test('the five category cards are always present', () async {
    final ProfileAnalyticsLoaded state = await loadState();
    expect(state.categories, hasLength(5));
  });

  test('a failure surfaces as an error state, not a crash', () async {
    await database.close();
    await cubit.load(profileId, l10n);
    expect(cubit.state, isA<ProfileAnalyticsError>());
    database = AppDatabase(NativeDatabase.memory());
  });
}
