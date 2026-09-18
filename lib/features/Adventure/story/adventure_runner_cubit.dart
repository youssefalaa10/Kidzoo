import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

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
  }) : super(const AdventureRunnerState(
          status: AdventureRunnerStatus.loading,
        ));

  final AdventureContentBundle bundle;
  final String adventureId;
  final int profileId;
  final StoryDao storyDao;

  Adventure? _adventure;
  int _index = 0;

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
    final StoryChapterProgressData? chapter =
        await storyDao.chapterFor(profileId, adventureId);

    // Resume exactly where they were, not at the start of the chapter. A
    // force-kill mid-Adventure is the common case at this age.
    final int resumeIndex = chapter?.currentNodeId == null
        ? 0
        : _adventure!.indexOfNode(chapter!.currentNodeId!);
    _index = resumeIndex < 0 ? 0 : resumeIndex;

    if (chapter?.isCompleted ?? false) {
      // Replaying a finished Adventure starts it over, but the page stays won.
      _index = 0;
    }

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
    await storyDao.saveResumePoint(
      profileId: profileId,
      adventureId: adventureId,
      nodeId: node.nodeId,
    );

    String? earnedReward;
    if (node.rewardId != null) {
      await storyDao.grantReward(
        profileId: profileId,
        rewardId: node.rewardId!,
        adventureId: adventureId,
      );
      earnedReward = node.rewardId;
    }

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
    ));
  }

  /// Advances past a narration beat.
  Future<void> continueStory() async {
    if (isClosed || state.status != AdventureRunnerStatus.playing) {
      return;
    }
    final StoryNode? node = state.node;
    if (node == null) {
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
  Future<void> completeActivity(ActivityResult result) async {
    if (isClosed || state.status != AdventureRunnerStatus.playing) {
      return;
    }
    final StoryNode? node = state.node;
    if (node == null) {
      return;
    }

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
