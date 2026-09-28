import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';

/// Badge persistence, against real SQLite.
///
/// The contract worth pinning is [BadgeDao.grantBadge]'s return value: it is
/// the only signal that a badge is *newly* earned, and therefore the only
/// thing standing between a child and the same pop-up every time they finish
/// a game.
void main() {
  late AppDatabase database;
  late BadgeDao dao;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = BadgeDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  test('a new profile holds no badges', () async {
    expect(await dao.earnedBadgeIdsFor(profileId), isEmpty);
    expect(await dao.badgeCountFor(profileId), 0);
  });

  test('granting returns true the first time and false after', () async {
    expect(
      await dao.grantBadge(profileId: profileId, badgeId: 'first_win'),
      isTrue,
    );
    expect(
      await dao.grantBadge(profileId: profileId, badgeId: 'first_win'),
      isFalse,
      reason: 'a second grant must not read as newly earned, or the pop-up '
          'fires again every time the child finishes a game',
    );
    expect(await dao.badgeCountFor(profileId), 1);
  });

  test('records when the badge was earned', () async {
    final DateTime before =
        DateTime.now().subtract(const Duration(seconds: 1));
    await dao.grantBadge(profileId: profileId, badgeId: 'first_win');
    final EarnedBadge row = (await dao.badgesFor(profileId)).single;
    expect(row.badgeId, 'first_win');
    expect(row.earnedAt.isAfter(before), isTrue);
  });

  test('badges come back newest first', () async {
    await dao.grantBadge(profileId: profileId, badgeId: 'first_win');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await dao.grantBadge(profileId: profileId, badgeId: 'maze_runner');
    final List<EarnedBadge> rows = await dao.badgesFor(profileId);
    expect(
      rows.map((EarnedBadge r) => r.badgeId).toList(),
      <String>['maze_runner', 'first_win'],
    );
  });

  test('two children earn the same badge independently', () async {
    final int sibling = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Sibling'),
        );
    expect(
      await dao.grantBadge(profileId: profileId, badgeId: 'first_win'),
      isTrue,
    );
    expect(
      await dao.grantBadge(profileId: sibling, badgeId: 'first_win'),
      isTrue,
      reason: 'the unique key is per profile, not global',
    );
    expect(await dao.earnedBadgeIdsFor(profileId), <String>{'first_win'});
    expect(await dao.earnedBadgeIdsFor(sibling), <String>{'first_win'});
  });

  test('watchBadges emits when one is granted', () async {
    final Future<List<EarnedBadge>> first =
        dao.watchBadges(profileId).firstWhere(
              (List<EarnedBadge> rows) => rows.isNotEmpty,
            );
    await dao.grantBadge(profileId: profileId, badgeId: 'page_finder');
    expect((await first).single.badgeId, 'page_finder');
  });
}
