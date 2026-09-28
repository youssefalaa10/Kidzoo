import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/badge_catalog.dart';
import 'package:kidzo/core/badges/badge_celebration_cubit.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/badge_stats_snapshot.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';

/// The pop-up queue.
///
/// Several badges can come true on one run — a twenty-fifth game that is also
/// a first three-star and a fifth day in a row — so the queue is what stops
/// three celebrations playing on top of each other.
void main() {
  late AppDatabase database;
  late BadgeService service;
  late BadgeCelebrationCubit cubit;

  BadgeDefinition badge(String id) => BadgeDefinition(
        badgeId: id,
        titleLocalizationKey: '${id}Title',
        descriptionLocalizationKey: '${id}Desc',
        icon: Icons.star_rounded,
        color: KidUi.hint,
        pillar: BadgePillar.games,
        isEarnedBy: (BadgeStatsSnapshot _) => false,
      );

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    service = BadgeService(
      badgeCatalog: BadgeCatalog(<BadgeDefinition>[]),
      badgeDao: BadgeDao(database),
      badgeStatsReader: BadgeStatsReader(
        gameScoresDao: GameScoresDao(database),
        storyDao: StoryDao(database),
      ),
      profileDao: ProfileDao(database),
    );
    cubit = BadgeCelebrationCubit(badgeService: service);
  });

  tearDown(() async {
    await cubit.close();
    await service.dispose();
    await database.close();
  });

  /// The first badge of a quiet queue is held back so the game's own win
  /// celebration lands first.
  Future<void> settleOpeningDelay() =>
      Future<void>.delayed(KidUi.celebrate + const Duration(milliseconds: 50));

  test('starts with nothing to celebrate', () {
    expect(cubit.state.isCelebrating, isFalse);
    expect(cubit.state.current, isNull);
  });

  test('an empty batch changes nothing', () async {
    cubit.enqueueBadges(<BadgeDefinition>[]);
    await settleOpeningDelay();
    expect(cubit.state.isCelebrating, isFalse);
  });

  test('the first badge waits for the game celebration to land', () async {
    cubit.enqueueBadges(<BadgeDefinition>[badge('first_win')]);
    expect(
      cubit.state.isCelebrating,
      isFalse,
      reason: 'a badge that interrupts the win sound reads as an error',
    );
    await settleOpeningDelay();
    expect(cubit.state.current!.badgeId, 'first_win');
  });

  test('shows a queued batch one at a time, in order', () async {
    cubit.enqueueBadges(<BadgeDefinition>[
      badge('first_win'),
      badge('triple_star'),
      badge('tier_climber'),
    ]);
    await settleOpeningDelay();
    expect(cubit.state.pending, hasLength(3));
    expect(cubit.state.current!.badgeId, 'first_win');

    cubit.dismissCurrentBadge();
    expect(cubit.state.current!.badgeId, 'triple_star');

    cubit.dismissCurrentBadge();
    expect(cubit.state.current!.badgeId, 'tier_climber');

    cubit.dismissCurrentBadge();
    expect(cubit.state.isCelebrating, isFalse);
  });

  test('a badge already queued is not queued twice', () async {
    cubit.enqueueBadges(<BadgeDefinition>[badge('first_win')]);
    await settleOpeningDelay();
    cubit.enqueueBadges(<BadgeDefinition>[
      badge('first_win'),
      badge('triple_star'),
    ]);
    expect(
      cubit.state.pending.map((BadgeDefinition b) => b.badgeId).toList(),
      <String>['first_win', 'triple_star'],
    );
  });

  test('a batch arriving mid-celebration joins the queue immediately',
      () async {
    cubit.enqueueBadges(<BadgeDefinition>[badge('first_win')]);
    await settleOpeningDelay();
    cubit.enqueueBadges(<BadgeDefinition>[badge('page_finder')]);
    // No second delay: the scrim is already up, so there is nothing to wait
    // for.
    expect(cubit.state.pending, hasLength(2));
  });

  test('dismissing an empty queue is harmless', () {
    cubit.dismissCurrentBadge();
    expect(cubit.state.isCelebrating, isFalse);
  });

  test('clearQueue cancels a pending opening too', () async {
    cubit.enqueueBadges(<BadgeDefinition>[badge('first_win')]);
    cubit.clearQueue();
    await settleOpeningDelay();
    expect(cubit.state.isCelebrating, isFalse);
  });

  test('a badge earned through the service reaches the queue', () async {
    // The stream is the only thing that should ever drive this queue, so this
    // is the one test that goes the whole way round: score row -> evaluation
    // -> stream -> pending.
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final int profileId = await db.into(db.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
    final BadgeService live = BadgeService(
      badgeCatalog: BadgeCatalog(<BadgeDefinition>[
        BadgeDefinition(
          badgeId: 'always',
          titleLocalizationKey: 'alwaysTitle',
          descriptionLocalizationKey: 'alwaysDesc',
          icon: Icons.star_rounded,
          color: KidUi.hint,
          pillar: BadgePillar.games,
          isEarnedBy: (BadgeStatsSnapshot s) => s.totalPlays >= 1,
        ),
      ]),
      badgeDao: BadgeDao(db),
      badgeStatsReader: BadgeStatsReader(
        gameScoresDao: GameScoresDao(db),
        storyDao: StoryDao(db),
      ),
      profileDao: ProfileDao(db),
    );
    addTearDown(live.dispose);
    final BadgeCelebrationCubit listener =
        BadgeCelebrationCubit(badgeService: live);
    addTearDown(listener.close);

    await GameScoresDao(db).insertScore(GameScoresCompanion.insert(
      profileId: profileId,
      gameKey: 'puzzle',
      score: 10,
    ));
    await live.evaluateForProfile(profileId);
    await settleOpeningDelay();
    expect(listener.state.current!.badgeId, 'always');
  });

  test('closing while a badge is pending does not throw', () async {
    cubit.enqueueBadges(<BadgeDefinition>[badge('first_win')]);
    await cubit.close();
    await settleOpeningDelay();
  });
}
