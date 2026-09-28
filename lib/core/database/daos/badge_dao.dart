import 'package:drift/drift.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/tables/badge_tables.dart';

part 'badge_dao.g.dart';

@DriftAccessor(tables: <Type>[EarnedBadges])
class BadgeDao extends DatabaseAccessor<AppDatabase> with _$BadgeDaoMixin {
  BadgeDao(super.db);

  /// Just the ids, for the evaluator's "have they already got this" check.
  Future<Set<String>> earnedBadgeIdsFor(int profileId) async {
    final List<EarnedBadge> rows = await (select(earnedBadges)
          ..where(($EarnedBadgesTable t) => t.profileId.equals(profileId)))
        .get();
    return rows.map((EarnedBadge row) => row.badgeId).toSet();
  }

  /// Newest first, which is the order the Profile's activity feed wants.
  Future<List<EarnedBadge>> badgesFor(int profileId) {
    final SimpleSelectStatement<$EarnedBadgesTable, EarnedBadge> query =
        select(earnedBadges)
          ..where(($EarnedBadgesTable t) => t.profileId.equals(profileId))
          ..orderBy(<OrderClauseGenerator<$EarnedBadgesTable>>[
            ($EarnedBadgesTable t) => OrderingTerm.desc(t.earnedAt),
          ]);
    return query.get();
  }

  Stream<List<EarnedBadge>> watchBadges(int profileId) {
    final SimpleSelectStatement<$EarnedBadgesTable, EarnedBadge> query =
        select(earnedBadges)
          ..where(($EarnedBadgesTable t) => t.profileId.equals(profileId))
          ..orderBy(<OrderClauseGenerator<$EarnedBadgesTable>>[
            ($EarnedBadgesTable t) => OrderingTerm.desc(t.earnedAt),
          ]);
    return query.watch();
  }

  Future<int> badgeCountFor(int profileId) async =>
      (await earnedBadgeIdsFor(profileId)).length;

  /// Awards [badgeId], returning true **only if it was not already held**.
  ///
  /// That boolean is the entire locked-to-unlocked diff. Everything upstream —
  /// which badges to celebrate, what to put in the pop-up queue — is derived
  /// from it, so no separate bookkeeping of "seen" badges is needed and two
  /// evaluations racing each other (a game finishing while the Profile screen
  /// loads) cannot produce two celebrations of the same badge.
  ///
  /// Modelled on `StoryDao.grantReward`, which is select-then-insert for the
  /// same reason: the unique key makes a double insert an error rather than a
  /// duplicate, and this turns that into an ordinary answer.
  Future<bool> grantBadge({
    required int profileId,
    required String badgeId,
  }) async {
    final EarnedBadge? existing = await (select(earnedBadges)
          ..where(($EarnedBadgesTable t) =>
              t.profileId.equals(profileId) & t.badgeId.equals(badgeId)))
        .getSingleOrNull();
    if (existing != null) {
      return false;
    }
    await into(earnedBadges).insert(EarnedBadgesCompanion.insert(
      profileId: profileId,
      badgeId: badgeId,
    ));
    return true;
  }
}
