import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

enum AdventureRunnerStatus { loading, playing, finished, contentError }

@immutable
class AdventureRunnerState {
  const AdventureRunnerState({
    required this.status,
    this.adventure,
    this.node,
    this.nodeIndex = 0,
    this.completedNodeIds = const <String>{},
    this.justEarnedRewardId,
    this.errorMessage,
    this.activityResume,
    this.didResume = false,
  });

  final AdventureRunnerStatus status;
  final Adventure? adventure;

  /// The node the child is on right now.
  final StoryNode? node;

  final int nodeIndex;
  final Set<String> completedNodeIds;

  /// Set for exactly one state emission, when the page is handed over, so the
  /// screen can celebrate without the celebration replaying on every rebuild.
  final String? justEarnedRewardId;

  final String? errorMessage;

  /// Where the interrupted run of [node]'s activity got to, when there is one.
  ///
  /// Consumed by the screen on the way into the activity and by nothing else.
  /// It is carried on the state rather than fetched at push time so that the
  /// thing the child is about to see is a pure function of the state the runner
  /// emitted, which is what makes "resumed mid-activity" assertable.
  final ActivityCheckpoint? activityResume;

  /// True when this run opened somewhere other than the first node — the child
  /// is continuing rather than starting.
  final bool didResume;

  int get nodeCount => adventure?.nodes.length ?? 0;

  double get progress => nodeCount == 0 ? 0 : (nodeIndex / nodeCount);

  bool get isOnActivity => node?.isActivity ?? false;
}

/// Drives one Adventure from its first beat to its last.
///
/// The shape it enforces is *story problem -> activity -> the result changes
/// the story -> next problem*. It is deliberately not a level runner: there is
/// no pass mark, no retry gate and no branch on performance. Every child who
/// reaches the end of an activity moves on, because a story that stops for a
/// four-year-old who answered wrong is a story they never finish.
class AdventureRunnerCubit extends Cubit<AdventureRunnerState> {
  AdventureRunnerCubit({
    required this.bundle,
    required this.adventureId,
    required this.profileId,
    required this.storyDao,
    this.badgeService,
  }) : super(const AdventureRunnerState(
          status: AdventureRunnerStatus.loading,
        ));

  final AdventureContentBundle bundle;
  final String adventureId;
  final int profileId;
  final StoryDao storyDao;

  /// Checks for newly earned badges after each story write.
  ///
  /// Nullable so the many existing tests that build this cubit keep working
  /// unchanged, and because a missing badge is never worth failing a story
  /// for. Hooked here rather than in `ActivityCubit`: the engine contract
  /// deliberately has no DAO, no profileId and no context, and its result
  /// already flows out through this cubit.
  final BadgeService? badgeService;

  static const StoryResumeResolver _resumeResolver = StoryResumeResolver();

  Adventure? _adventure;
  int _index = 0;

  bool _didResume = false;

  /// Loads the Adventure and resumes where the child left off.
  Future<void> start() async {
    try {
      _adventure = bundle.requireAdventure(adventureId);
    } catch (error) {
      emit(AdventureRunnerState(
        status: AdventureRunnerStatus.contentError,
        errorMessage: '$error',
      ));
      return;
    }

    final Set<String> completed =
        await storyDao.completedNodeIds(profileId, adventureId);
    final StoryResumePoint? resume =
        await storyDao.resumePointFor(profileId, adventureId);

    // Resume exactly where they were, not at the start of the chapter. A
    // force-kill mid-Adventure is the common case at this age, and every rule
    // the resolver applies is a way an Adventure was observed restarting
    // itself. Keeping them in one pure function is what lets each be pinned by
    // a test rather than re-derived from three conditions inside an async
    // method that also does I/O.
    _index = _resumeResolver.resolve(
      adventure: _adventure!,
      resume: resume,
      completedNodeIds: completed,
    );
    _didResume = _index > 0;

    await _enterNode(completed);
  }

  Future<void> _enterNode(Set<String> completed) async {
    if (isClosed) {
      return;
    }
    final Adventure adventure = _adventure!;
    if (_index >= adventure.nodes.length) {
      await _finishAdventure(completed);
      return;
    }

    final StoryNode node = adventure.nodes[_index];

    // Read before writing. A checkpoint belongs to one activity on one node,
    // and the stored point is the only thing that knows which — so it is
    // fetched here on **every** entry rather than carried from `start` in a
    // field. Carrying it meant the checkpoint survived a cold start but not a
    // back-out-and-return: the child abandoned an activity at round four, the
    // runner kept them on the node, and tapping "let's play" started it again
    // from round one even though the cursor was still in the database.
    final StoryResumePoint? stored =
        await storyDao.resumePointFor(profileId, adventureId);
    final ActivityCheckpoint? resume =
        stored?.nodeId == node.nodeId ? stored?.activity : null;

    await storyDao.saveResumePoint(
      profileId: profileId,
      adventureId: adventureId,
      nodeId: node.nodeId,
      // Stored beside the id so a node renamed by a content update puts the
      // child back into the right part of the story instead of its first line.
      beat: node.beat,
    );

    // Granted once, ever. `grantReward` was always idempotent in the table,
    // but the *celebration* keyed off the node rather than off the grant, so a
    // child who closed the app on the resolution beat watched the page fly
    // into the book again on every return.
    String? earnedReward;
    if (node.rewardId != null) {
      final bool isNewlyEarned = await storyDao.grantReward(
        profileId: profileId,
        rewardId: node.rewardId!,
        adventureId: adventureId,
      );
      if (isNewlyEarned) {
        earnedReward = node.rewardId;
      }
    }

    await badgeService?.evaluateForProfile(profileId);

    if (isClosed) {
      return;
    }
    emit(AdventureRunnerState(
      status: AdventureRunnerStatus.playing,
      adventure: adventure,
      node: node,
      nodeIndex: _index,
      completedNodeIds: completed,
      justEarnedRewardId: earnedReward,
      activityResume: node.isActivity ? resume : null,
      didResume: _didResume,
    ));
  }

  /// Re-asserts the current position.
  ///
  /// A **secondary** safety net for lifecycle callbacks, and nothing depends on
  /// it: the resume point is already written on entering every node and the
  /// activity cursor at every step boundary. An app the OS kills never reaches
  /// a lifecycle callback, so anything that relied on one would be relying on
  /// the case that does not happen.
  Future<void> flush() async {
    final StoryNode? node = state.node;
    if (node == null || state.status != AdventureRunnerStatus.playing) {
      return;
    }
    await storyDao.saveResumePoint(
      profileId: profileId,
      adventureId: adventureId,
      nodeId: node.nodeId,
      beat: node.beat,
    );
  }

  /// Advances past a narration beat.
  ///
  /// [fromNodeId] is the node the caller believed it was on. A narration future
  /// that resolves after the story has already moved — a superseded TTS
  /// callback, a failsafe timer firing late, a second tap landing during the
  /// hand-off — carries the *old* node, and is ignored. Without that check a
  /// late callback could advance a beat the child had not seen, which is a
  /// silent skip rather than a visible bug.
  Future<void> continueStory({String? fromNodeId}) async {
    if (isClosed || state.status != AdventureRunnerStatus.playing) {
      return;
    }
    final StoryNode? node = state.node;
    if (node == null) {
      return;
    }
    if (fromNodeId != null && fromNodeId != node.nodeId) {
      return;
    }
    if (!node.isActivity) {
      await storyDao.saveNodeResult(
        profileId: profileId,
        adventureId: adventureId,
        nodeId: node.nodeId,
        completion: 'completed',
      );
    }
    _index++;
    await _enterNode(<String>{...state.completedNodeIds, node.nodeId});
  }

  /// Records an activity's outcome and moves the story on.
  ///
  /// Note what is **not** here: any check on score, stars or mastery. Those are
  /// stored and they feed adaptation and the parent report, but they never
  /// decide whether the narrative continues.
  Future<void> completeActivity(
    ActivityResult result, {
    String? fromNodeId,
  }) async {
    if (isClosed || state.status != AdventureRunnerStatus.playing) {
      return;
    }
    final StoryNode? node = state.node;
    if (node == null) {
      return;
    }
    // A result belonging to an activity the story has already moved past — a
    // second pop delivering a stale result, a route torn down late — must not
    // be written against whatever node happens to be current now.
    if (fromNodeId != null && fromNodeId != node.nodeId) {
      return;
    }

    // Upserted on `(profileId, nodeId)`, so a node re-entered after a resume
    // overwrites its own row rather than adding a second one. That is what
    // keeps a repeated resume from doubling a score or a completion.
    await storyDao.saveNodeResult(
      profileId: profileId,
      adventureId: adventureId,
      nodeId: node.nodeId,
      completion: result.completion.name,
      stepsTotal: result.stepsTotal,
      stepsIndependent: result.stepsIndependent,
      hintsUsed: result.hintsUsed,
      score: result.score,
      durationSeconds: result.durationSeconds,
    );

    if (result.completion == ActivityCompletion.abandoned) {
      // The child backed out. Stay on this node so returning resumes here
      // rather than skipping the beat they never played.
      await _enterNode(state.completedNodeIds);
      return;
    }

    _index++;
    await _enterNode(<String>{...state.completedNodeIds, node.nodeId});
  }

  Future<void> _finishAdventure(Set<String> completed) async {
    await storyDao.markChapterCompleted(
      profileId: profileId,
      adventureId: adventureId,
    );
    await badgeService?.evaluateForProfile(profileId);
    if (isClosed) {
      return;
    }
    emit(AdventureRunnerState(
      status: AdventureRunnerStatus.finished,
      adventure: _adventure,
      nodeIndex: _adventure?.nodes.length ?? 0,
      completedNodeIds: completed,
    ));
  }
}
