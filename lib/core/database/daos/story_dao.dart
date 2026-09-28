import 'package:drift/drift.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/tables/story_tables.dart';

part 'story_dao.g.dart';

/// Reads and writes story progress.
///
/// Everything is scoped by `profileId`: two children on one tablet keep
/// separate stories, separate pages and separate resume points.
@DriftAccessor(tables: <Type>[
  StoryNodeProgress,
  StoryChapterProgress,
  StoryRewards,
  ActivityAttemptLogs,
])
class StoryDao extends DatabaseAccessor<AppDatabase> with _$StoryDaoMixin {
  StoryDao(super.db);

  // ------------------------------------------------------------------- resume

  /// Where to pick the story back up, or null if this Adventure is untouched.
  Future<StoryChapterProgressData?> chapterFor(
    int profileId,
    String adventureId,
  ) {
    return (select(storyChapterProgress)
          ..where((StoryChapterProgress t) =>
              t.profileId.equals(profileId) &
              t.adventureId.equals(adventureId)))
        .getSingleOrNull();
  }

  Future<List<StoryChapterProgressData>> chaptersFor(int profileId) {
    return (select(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.profileId.equals(profileId)))
        .get();
  }

  Stream<List<StoryChapterProgressData>> watchChapters(int profileId) {
    return (select(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.profileId.equals(profileId)))
        .watch();
  }

  /// Records where the child currently is.
  ///
  /// Written on *entering* each node rather than only on finishing one, because
  /// a force-kill mid-Adventure is the common case at this age, not the edge
  /// case. Costs one small write per beat and makes resume exact.
  Future<void> saveResumePoint({
    required int profileId,
    required String adventureId,
    required String nodeId,
  }) async {
    final StoryChapterProgressData? existing =
        await chapterFor(profileId, adventureId);
    final DateTime now = DateTime.now();

    if (existing == null) {
      await into(storyChapterProgress).insert(
        StoryChapterProgressCompanion.insert(
          profileId: profileId,
          adventureId: adventureId,
          currentNodeId: Value<String?>(nodeId),
          startedAt: Value<DateTime>(now),
          lastPlayedAt: Value<DateTime>(now),
        ),
      );
      return;
    }

    await (update(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.id.equals(existing.id)))
        .write(StoryChapterProgressCompanion(
      currentNodeId: Value<String?>(nodeId),
      lastPlayedAt: Value<DateTime>(now),
    ));
  }

  Future<void> markChapterCompleted({
    required int profileId,
    required String adventureId,
  }) async {
    final StoryChapterProgressData? existing =
        await chapterFor(profileId, adventureId);
    final DateTime now = DateTime.now();

    if (existing == null) {
      await into(storyChapterProgress).insert(
        StoryChapterProgressCompanion.insert(
          profileId: profileId,
          adventureId: adventureId,
          currentNodeId: const Value<String?>(null),
          isCompleted: const Value<bool>(true),
          startedAt: Value<DateTime>(now),
          completedAt: Value<DateTime?>(now),
          lastPlayedAt: Value<DateTime>(now),
        ),
      );
      return;
    }

    await (update(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.id.equals(existing.id)))
        .write(StoryChapterProgressCompanion(
      currentNodeId: const Value<String?>(null),
      isCompleted: const Value<bool>(true),
      completedAt: Value<DateTime?>(now),
      lastPlayedAt: Value<DateTime>(now),
    ));
  }

  /// Clears an Adventure so it can be replayed from the beginning.
  ///
  /// Replay keeps the recovered page: pages are not scarce, and taking one back
  /// because a child wanted to hear the story again would be a strange lesson.
  Future<void> resetAdventure({
    required int profileId,
    required String adventureId,
  }) async {
    await (delete(storyNodeProgress)
          ..where((StoryNodeProgress t) =>
              t.profileId.equals(profileId) &
              t.adventureId.equals(adventureId)))
        .go();
    await (delete(storyChapterProgress)
          ..where((StoryChapterProgress t) =>
              t.profileId.equals(profileId) &
              t.adventureId.equals(adventureId)))
        .go();
  }

  // -------------------------------------------------------------------- nodes

  Future<void> saveNodeResult({
    required int profileId,
    required String adventureId,
    required String nodeId,
    required String completion,
    int stepsTotal = 0,
    int stepsIndependent = 0,
    int hintsUsed = 0,
    int score = 0,
    int durationSeconds = 0,
  }) async {
    final StoryNodeProgressData? existing = await (select(storyNodeProgress)
          ..where((StoryNodeProgress t) =>
              t.profileId.equals(profileId) & t.nodeId.equals(nodeId)))
        .getSingleOrNull();

    final StoryNodeProgressCompanion values = StoryNodeProgressCompanion(
      completion: Value<String>(completion),
      stepsTotal: Value<int>(stepsTotal),
      stepsIndependent: Value<int>(stepsIndependent),
      hintsUsed: Value<int>(hintsUsed),
      score: Value<int>(score),
      durationSeconds: Value<int>(durationSeconds),
      updatedAt: Value<DateTime>(DateTime.now()),
    );

    if (existing == null) {
      await into(storyNodeProgress).insert(
        StoryNodeProgressCompanion.insert(
          profileId: profileId,
          adventureId: adventureId,
          nodeId: nodeId,
          completion: values.completion,
          stepsTotal: values.stepsTotal,
          stepsIndependent: values.stepsIndependent,
          hintsUsed: values.hintsUsed,
          score: values.score,
          durationSeconds: values.durationSeconds,
          updatedAt: values.updatedAt,
        ),
      );
      return;
    }

    await (update(storyNodeProgress)
          ..where((StoryNodeProgress t) => t.id.equals(existing.id)))
        .write(values);
  }

  Future<List<StoryNodeProgressData>> nodesFor(
    int profileId,
    String adventureId,
  ) {
    return (select(storyNodeProgress)
          ..where((StoryNodeProgress t) =>
              t.profileId.equals(profileId) &
              t.adventureId.equals(adventureId)))
        .get();
  }

  Future<Set<String>> completedNodeIds(
      int profileId, String adventureId) async {
    final List<StoryNodeProgressData> rows =
        await nodesFor(profileId, adventureId);
    return rows
        .where((StoryNodeProgressData row) => row.completion == 'completed')
        .map((StoryNodeProgressData row) => row.nodeId)
        .toSet();
  }

  // ------------------------------------------------------------------ rewards

  /// Grants a page. Idempotent: replaying an Adventure must not duplicate it.
  Future<void> grantReward({
    required int profileId,
    required String rewardId,
    required String adventureId,
  }) async {
    final StoryReward? existing = await (select(storyRewards)
          ..where((StoryRewards t) =>
              t.profileId.equals(profileId) & t.rewardId.equals(rewardId)))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }
    await into(storyRewards).insert(
      StoryRewardsCompanion.insert(
        profileId: profileId,
        rewardId: rewardId,
        adventureId: adventureId,
      ),
    );
  }

  Future<List<StoryReward>> rewardsFor(int profileId) {
    return (select(storyRewards)
          ..where((StoryRewards t) => t.profileId.equals(profileId)))
        .get();
  }

  Stream<List<StoryReward>> watchRewards(int profileId) {
    return (select(storyRewards)
          ..where((StoryRewards t) => t.profileId.equals(profileId)))
        .watch();
  }

  // ---------------------------------------------------------------- telemetry

  Future<void> recordAttempt({
    required int profileId,
    required String activityId,
    required int stepIndex,
    required int attemptIndex,
    required String outcome,
    required String scaffoldLevel,
    required int elapsedMilliseconds,
    String? storyNodeId,
  }) {
    return into(activityAttemptLogs).insert(
      ActivityAttemptLogsCompanion.insert(
        profileId: profileId,
        activityId: activityId,
        storyNodeId: Value<String?>(storyNodeId),
        stepIndex: stepIndex,
        attemptIndex: attemptIndex,
        outcome: outcome,
        scaffoldLevel: scaffoldLevel,
        elapsedMilliseconds: elapsedMilliseconds,
      ),
    );
  }

  Future<List<ActivityAttemptLog>> attemptsFor(
    int profileId, {
    String? activityId,
  }) {
    return (select(activityAttemptLogs)
          ..where((ActivityAttemptLogs t) => activityId == null
              ? t.profileId.equals(profileId)
              : t.profileId.equals(profileId) &
                  t.activityId.equals(activityId)))
        .get();
  }
}
