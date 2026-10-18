import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/story/adventure_runner_cubit.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

import 'support/disk_content_source.dart';

/// The story flow itself: beats, activities, resume, rewards.
///
/// Runs against the **real** Adventure 1 content rather than a fixture, so this
/// suite is also a check that the authored story actually plays end to end.
void main() {
  late AppDatabase database;
  late StoryDao dao;
  late AdventureContentBundle bundle;
  late int profileId;

  setUpAll(() async {
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
  });

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = StoryDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  AdventureRunnerCubit makeRunner() => AdventureRunnerCubit(
        bundle: bundle,
        adventureId: 'jungle',
        profileId: profileId,
        storyDao: dao,
      );

  /// Plays the whole Adventure, answering every activity as completed.
  Future<AdventureRunnerCubit> playThrough(
    AdventureRunnerCubit runner, {
    int? stopAfterNodes,
  }) async {
    await runner.start();
    int guard = 0;
    int played = 0;
    while (runner.state.status == AdventureRunnerStatus.playing && guard < 50) {
      guard++;
      if (stopAfterNodes != null && played >= stopAfterNodes) {
        break;
      }
      played++;
      if (runner.state.isOnActivity) {
        await runner.completeActivity(const ActivityResult(
          completion: ActivityCompletion.completed,
          score: 30,
          maxScore: 40,
          stepsTotal: 4,
          stepsIndependent: 3,
          hintsUsed: 1,
          durationSeconds: 40,
        ));
      } else {
        await runner.continueStory();
      }
    }
    return runner;
  }

  group('Playing through', () {
    test('starts on the opening problem', () async {
      final AdventureRunnerCubit runner = makeRunner();
      await runner.start();

      expect(runner.state.status, AdventureRunnerStatus.playing);
      expect(runner.state.node!.beat, StoryBeat.openingProblem);
      expect(runner.state.node!.isActivity, isFalse);
      await runner.close();
    });

    test('reaches the end and marks the chapter complete', () async {
      final AdventureRunnerCubit runner = await playThrough(makeRunner());

      expect(runner.state.status, AdventureRunnerStatus.finished);
      final chapter = await dao.chapterFor(profileId, 'jungle');
      expect(chapter!.isCompleted, isTrue);
      await runner.close();
    });

    test('visits every beat of the required dramatic shape', () async {
      final AdventureRunnerCubit runner = makeRunner();
      final List<StoryBeat> visited = <StoryBeat>[];
      await runner.start();
      int guard = 0;
      while (
          runner.state.status == AdventureRunnerStatus.playing && guard < 50) {
        guard++;
        visited.add(runner.state.node!.beat);
        if (runner.state.isOnActivity) {
          await runner.completeActivity(const ActivityResult(
            completion: ActivityCompletion.completed,
            score: 10,
            maxScore: 10,
            stepsTotal: 1,
            stepsIndependent: 1,
            hintsUsed: 0,
            durationSeconds: 5,
          ));
        } else {
          await runner.continueStory();
        }
      }

      for (final StoryBeat beat in StoryBeat.requiredSequence) {
        expect(visited, contains(beat),
            reason: 'the child never reached the $beat beat');
      }
      await runner.close();
    });

    test('every activity node is actually reachable and resolvable', () async {
      // A node pointing at a missing activity would only show up at runtime,
      // in front of a child, as a dead end.
      final Adventure adventure = bundle.requireAdventure('jungle');
      for (final StoryNode node in adventure.nodes) {
        if (!node.isActivity) {
          continue;
        }
        expect(
            () => bundle.requireActivity(node.activityRef!), returnsNormally);
      }
    });
  });

  group('No-fail: the story never stalls on performance', () {
    test('an activity finished with zero independent steps still advances',
        () async {
      final AdventureRunnerCubit runner = makeRunner();
      await runner.start();
      await runner.continueStory(); // past the opening beat
      expect(runner.state.isOnActivity, isTrue);
      final String activityNodeId = runner.state.node!.nodeId;

      await runner.completeActivity(const ActivityResult(
        completion: ActivityCompletion.completed,
        score: 4,
        maxScore: 40,
        stepsTotal: 4,
        stepsIndependent: 0,
        hintsUsed: 12,
        durationSeconds: 90,
      ));

      expect(runner.state.node!.nodeId, isNot(activityNodeId),
          reason: 'a child who needed help on every step must still move on');
      await runner.close();
    });

    test('mastery signals are stored even though they change nothing',
        () async {
      final AdventureRunnerCubit runner = makeRunner();
      await runner.start();
      await runner.continueStory();
      await runner.completeActivity(const ActivityResult(
        completion: ActivityCompletion.completed,
        score: 4,
        maxScore: 40,
        stepsTotal: 4,
        stepsIndependent: 0,
        hintsUsed: 12,
        durationSeconds: 90,
      ));

      final rows = await dao.nodesFor(profileId, 'jungle');
      final row = rows.firstWhere((r) => r.hintsUsed == 12);
      expect(row.stepsIndependent, 0);
      expect(row.completion, 'completed');
      await runner.close();
    });
  });

  group('Resume', () {
    test('a fresh runner picks up at the node it left off on', () async {
      final AdventureRunnerCubit first = makeRunner();
      await playThrough(first, stopAfterNodes: 3);
      final String? left = first.state.node?.nodeId;
      await first.close();

      final AdventureRunnerCubit second = makeRunner();
      await second.start();

      expect(second.state.node!.nodeId, left,
          reason: 'a force-kill mid-Adventure is the common case, not an edge '
              'case, so resume has to be exact');
      await second.close();
    });

    test('backing out of an activity stays on that node', () async {
      final AdventureRunnerCubit runner = makeRunner();
      await runner.start();
      await runner.continueStory();
      final String activityNode = runner.state.node!.nodeId;

      await runner.completeActivity(const ActivityResult(
        completion: ActivityCompletion.abandoned,
        score: 0,
        maxScore: 40,
        stepsTotal: 4,
        stepsIndependent: 0,
        hintsUsed: 0,
        durationSeconds: 5,
      ));

      expect(runner.state.node!.nodeId, activityNode,
          reason: 'skipping the beat they never played would silently drop it');
      await runner.close();
    });

    test('replaying a finished adventure starts over', () async {
      await playThrough(makeRunner()).then((r) => r.close());

      final AdventureRunnerCubit again = makeRunner();
      await again.start();
      expect(again.state.node!.beat, StoryBeat.openingProblem);
      await again.close();
    });
  });

  group('Rewards', () {
    test('the page is granted when the resolution beat is reached', () async {
      final AdventureRunnerCubit runner = await playThrough(makeRunner());
      final rewards = await dao.rewardsFor(profileId);
      expect(rewards.map((r) => r.rewardId), contains('green_page'));
      await runner.close();
    });

    test('the page is not granted early', () async {
      final AdventureRunnerCubit runner = makeRunner();
      await runner.start();
      await runner.continueStory();
      expect(await dao.rewardsFor(profileId), isEmpty);
      await runner.close();
    });

    test('replaying does not duplicate the page', () async {
      await playThrough(makeRunner()).then((r) => r.close());
      await playThrough(makeRunner()).then((r) => r.close());

      expect((await dao.rewardsFor(profileId)).length, 1);
    });
  });

  group('Content errors', () {
    test('an unknown adventure reports a content error rather than crashing',
        () async {
      final AdventureRunnerCubit runner = AdventureRunnerCubit(
        bundle: bundle,
        adventureId: 'does_not_exist',
        profileId: profileId,
        storyDao: dao,
      );
      await runner.start();
      expect(runner.state.status, AdventureRunnerStatus.contentError);
      expect(runner.state.errorMessage, isNotNull);
      await runner.close();
    });
  });
}
