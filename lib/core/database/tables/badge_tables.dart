import 'package:drift/drift.dart';
import 'package:kidzo/core/database/tables/profile_table.dart';

/// One badge a child has earned, and the moment it happened.
///
/// Modelled on `StoryRewards`, down to the unique key that makes granting
/// idempotent: the same badge can only ever be in here once per profile, so a
/// grant is safe to attempt from anywhere without first checking.
///
/// Append-only. A badge is never taken back, not even when a child replays
/// something or resets an Adventure — the same rule story pages already
/// follow. Un-awarding something a child has already been congratulated for is
/// a strange lesson to teach.
///
/// Note what is *not* here: the badge's name, icon or unlock rule. Those live
/// in the injected `BadgeCatalog`, so wording and artwork can be changed in a
/// release without a migration, and `badgeId` stays the only durable fact.
class EarnedBadges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get badgeId => text()();
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{profileId, badgeId},
      ];
}
