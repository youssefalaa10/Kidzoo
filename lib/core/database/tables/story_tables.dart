import 'package:drift/drift.dart';
import 'package:kidzo/core/database/tables/profile_table.dart';

/// One node a child has reached or finished.
///
/// Keyed by `(profileId, nodeId)` so resume is a lookup rather than a scan, and
/// so two children on one device keep separate stories.
class StoryNodeProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get adventureId => text()();
  TextColumn get nodeId => text()();

  /// `inProgress`, `completed` or `abandoned`.
  ///
  /// There is deliberately no `failed`. Every child who reaches the last step
  /// of an activity completes it, so the story can never stall on performance.
  TextColumn get completion => text().withDefault(const Constant('completed'))();

  /// Mastery signals. They feed the parent report and the adaptive nudge, and
  /// they **never** branch the narrative.
  IntColumn get stepsTotal => integer().withDefault(const Constant(0))();
  IntColumn get stepsIndependent => integer().withDefault(const Constant(0))();
  IntColumn get hintsUsed => integer().withDefault(const Constant(0))();
  IntColumn get score => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{profileId, nodeId},
      ];
}

/// Where a child is in each Adventure.
class StoryChapterProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get adventureId => text()();

  /// The node to resume at. Null once the Adventure is finished.
  TextColumn get currentNodeId => text().nullable()();

  /// Carries a future entitlement check. Nothing reads it as a paywall today;
  /// Adventure boundaries are natural gates by construction, so the hook costs
  /// nothing now and would be expensive to add later.
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(true))();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Drives the "let's continue the story" reminder: a notification is only
  /// worth sending to a child who actually has a story in progress.
  DateTimeColumn get lastPlayedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{profileId, adventureId},
      ];
}

/// The pages recovered into the book.
///
/// Free and non-scarce by design: no rarity, no randomness, nothing paywalled.
/// The book is a progress meter a pre-reader can read spatially, not a
/// collection to chase.
class StoryRewards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get rewardId => text()();
  TextColumn get adventureId => text()();
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{profileId, rewardId},
      ];
}

/// Per-step telemetry.
///
/// Separate from `GameScores`, which holds one row per play and therefore
/// cannot carry the distinction this table exists for: `wrongSlotButRightItem`
/// (reached for the right answer and missed) versus `wrongItem` (chose wrong).
/// One means the targets are too small, the other means more teaching is
/// needed, and collapsing them into "wrong" destroys the only signal that tells
/// you which.
/// Named `...Logs` rather than `ActivityAttempts` on purpose: Drift derives a
/// data class by singularising the table name, and `ActivityAttempt` is already
/// the engine's sealed attempt type. Two different meanings under one name in
/// the same import graph is a bug waiting to be written.
class ActivityAttemptLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get activityId => text()();
  TextColumn get storyNodeId => text().nullable()();
  IntColumn get stepIndex => integer()();
  IntColumn get attemptIndex => integer()();
  TextColumn get outcome => text()();
  TextColumn get scaffoldLevel => text()();
  IntColumn get elapsedMilliseconds => integer()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
}
