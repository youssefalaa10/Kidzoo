import 'package:drift/drift.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/tables/story_tables.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

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

  /// The whole resume cursor for one Adventure, or null if it is untouched.
  Future<StoryResumePoint?> resumePointFor(
    int profileId,
    String adventureId,
  ) async {
    final StoryChapterProgressData? row =
        await chapterFor(profileId, adventureId);
    if (row == null) {
      return null;
    }
    return StoryResumePoint(
      profileId: profileId,
      adventureId: adventureId,
      nodeId: row.currentNodeId,
      beat: _beatNamed(row.currentBeat),
      activity: ActivityCheckpoint.decode(row.activityCheckpoint),
      isChapterCompleted: row.isCompleted,
      updatedAt: row.lastPlayedAt,
    );
  }

  /// A stored beat name, or null when it is absent or no longer a beat.
  ///
  /// Non-throwing on purpose. A beat removed from the enum between releases
  /// must degrade to "no hint about where they were", never to a crash on the
  /// way into a story.
  static StoryBeat? _beatNamed(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final StoryBeat beat in StoryBeat.values) {
      if (beat.name == raw) {
        return beat;
      }
    }
    return null;
  }

  /// Records where the child currently is.
  ///
  /// Written on *entering* each node rather than only on finishing one, because
  /// a force-kill mid-Adventure is the common case at this age, not the edge
  /// case. Costs one small write per beat and makes resume exact.
  ///
  /// Moving to a **different** node drops any activity checkpoint, because a
  /// checkpoint belongs to the activity that wrote it. Re-entering the *same*
  /// node keeps it — which is exactly the resume path, where the runner has
  /// already read the checkpoint and is about to hand it to the engine.
  Future<void> saveResumePoint({
    required int profileId,
    required String adventureId,
    required String nodeId,
    StoryBeat? beat,
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
          currentBeat: Value<String?>(beat?.name),
          startedAt: Value<DateTime>(now),
          lastPlayedAt: Value<DateTime>(now),
        ),
      );
      return;
    }

    final bool isSameNode = existing.currentNodeId == nodeId;
    await (update(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.id.equals(existing.id)))
        .write(StoryChapterProgressCompanion(
      currentNodeId: Value<String?>(nodeId),
      currentBeat: Value<String?>(beat?.name),
      lastPlayedAt: Value<DateTime>(now),
      activityCheckpoint: isSameNode
          ? const Value<String?>.absent()
          : const Value<String?>(null),
    ));
  }

  /// Stores where the child is **inside** the activity they are playing.
  ///
  /// Called at every step boundary, not on the way out. That is the whole
  /// point: an exit callback does not run when the OS kills the app, and on a
  /// tablet handed back to a parent mid-round that is most of how a session
  /// ends. One small write per step buys exactness for the case that actually
  /// happens.
  Future<void> saveActivityCheckpoint({
    required int profileId,
    required String adventureId,
    required ActivityCheckpoint checkpoint,
  }) async {
    final StoryChapterProgressData? existing =
        await chapterFor(profileId, adventureId);
    if (existing == null) {
      return;
    }
    await (update(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.id.equals(existing.id)))
        .write(StoryChapterProgressCompanion(
      activityCheckpoint: Value<String?>(checkpoint.encode()),
      lastPlayedAt: Value<DateTime>(DateTime.now()),
    ));
  }

  /// Forgets the in-flight activity, leaving the story position alone.
  ///
  /// Called when an activity finishes, so a later replay of the same node
  /// starts it over rather than resuming a run the child already completed.
  Future<void> clearActivityCheckpoint({
    required int profileId,
    required String adventureId,
  }) async {
    final StoryChapterProgressData? existing =
        await chapterFor(profileId, adventureId);
    if (existing == null || existing.activityCheckpoint == null) {
      return;
    }
    await (update(storyChapterProgress)
          ..where((StoryChapterProgress t) => t.id.equals(existing.id)))
        .write(const StoryChapterProgressCompanion(
      activityCheckpoint: Value<String?>(null),
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
          currentBeat: const Value<String?>(null),
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
      // Cleared together, and that pairing is load-bearing: a null node on a
      // completed chapter is what distinguishes "finished" from "finished once
      // and playing it again right now". Collapsing those two was how a replay
      // threw away every beat the child had just played.
      currentNodeId: const Value<String?>(null),
      currentBeat: const Value<String?>(null),
      activityCheckpoint: const Value<String?>(null),
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
  ///
  /// Returns whether this call is what earned it. The table was always
  /// idempotent; the *celebration* was not, so a child who closed the app on
  /// the resolution beat watched the page fly into the book again every time
  /// they came back. Telling the caller which of the two happened is what lets
  /// the story celebrate exactly once.
  Future<bool> grantReward({
    required int profileId,
    required String rewardId,
    required String adventureId,
  }) async {
    final StoryReward? existing = await (select(storyRewards)
          ..where((StoryRewards t) =>
              t.profileId.equals(profileId) & t.rewardId.equals(rewardId)))
        .getSingleOrNull();
    if (existing != null) {
      return false;
    }
    await into(storyRewards).insert(
      StoryRewardsCompanion.insert(
        profileId: profileId,
        rewardId: rewardId,
        adventureId: adventureId,
      ),
    );
    return true;
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
