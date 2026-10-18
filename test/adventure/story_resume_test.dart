import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/story/adventure_runner_cubit.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';
import 'package:kidzo/features/Adventure/story/ui/adventure_runner_screen.dart';

import 'support/disk_content_source.dart';
import 'support/echo_engine.dart';

/// A child who leaves comes back to where they were.
///
/// Every test here corresponds to a way an Adventure was observed restarting
/// itself, reproduced before it was fixed:
///
/// * a chapter finished once made **every later replay** restart at its first
///   line, because `isCompleted` outlived the run that set it;
/// * a node id that content had since renamed fell through `indexOfNode`'s
///   `-1` straight to index zero;
/// * nothing at all was stored *inside* an activity, so leaving during a
///   six-round mini-game meant replaying all six on a differently shuffled
///   board;
/// * the page celebration keyed off reaching the resolution node rather than
///   off earning the page, so it replayed on every return.
///
/// The framing that matters: at this age a session usually ends by the device
/// being taken away, not by the child finishing. Resume is not a convenience
/// here, it is whether the story is finishable at all.
/// Serves one already-built [AppLocalizations] with no async load, so a widget
/// test does not sit on a delegate future that never completes under a fake
/// clock.
class _SynchronousLocalizations
    extends LocalizationsDelegate<AppLocalizations> {
  const _SynchronousLocalizations(this.value);

  final AppLocalizations value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(value);

  @override
  bool shouldReload(_SynchronousLocalizations old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdventureContentBundle bundle;

  setUpAll(() async {
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
  });

  // ---------------------------------------------------------------- fixtures

  late AppDatabase database;
  late StoryDao dao;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = StoryDao(database);
    profileId = await database
        .into(database.profiles)
        .insert(ProfilesCompanion.insert(name: 'Test Child'));
  });

  tearDown(() async => database.close());

  AdventureRunnerCubit runnerFor(
    int forProfileId, {
    StoryDao? withDao,
    String adventureId = 'jungle',
  }) {
    return AdventureRunnerCubit(
      bundle: bundle,
      adventureId: adventureId,
      profileId: forProfileId,
      storyDao: withDao ?? dao,
    );
  }

  const ActivityResult finished = ActivityResult(
    completion: ActivityCompletion.completed,
    score: 30,
    maxScore: 40,
    stepsTotal: 4,
    stepsIndependent: 3,
    hintsUsed: 1,
    durationSeconds: 20,
  );

  /// Plays forward [nodes] nodes and leaves the runner sitting where it lands.
  Future<AdventureRunnerCubit> playForward(
    AdventureRunnerCubit runner,
    int nodes,
  ) async {
    await runner.start();
    for (int played = 0;
        played < nodes && runner.state.status == AdventureRunnerStatus.playing;
        played++) {
      if (runner.state.isOnActivity) {
        await runner.completeActivity(finished);
      } else {
        await runner.continueStory();
      }
    }
    return runner;
  }

  Future<AdventureRunnerCubit> playToTheEnd(AdventureRunnerCubit runner) async {
    await runner.start();
    int guard = 0;
    while (runner.state.status == AdventureRunnerStatus.playing && guard < 80) {
      guard++;
      if (runner.state.isOnActivity) {
        await runner.completeActivity(finished);
      } else {
        await runner.continueStory();
      }
    }
    return runner;
  }

  // ------------------------------------------------------------ story cursor

  group('Leaving and coming back', () {
    test('leaving during a story beat reopens on that same beat', () async {
      // Four nodes in, which in the jungle is the narration beat between the
      // sorting activity and the search. Leaving on the *first* node would
      // prove nothing: it is where an unresumed story starts anyway.
      final AdventureRunnerCubit first = await playForward(runnerFor(profileId), 4);
      final StoryNode left = first.state.node!;
      expect(left.isActivity, isFalse,
          reason: 'this test needs to leave on a narration beat');
      await first.close();

      final AdventureRunnerCubit second = runnerFor(profileId);
      await second.start();

      expect(second.state.node!.nodeId, left.nodeId);
      expect(second.state.node!.beat, left.beat,
          reason: 'the beat is replayed from its own beginning, not skipped');
      expect(second.state.didResume, isTrue);
      await second.close();
    });

    test('leaving after an activity reopens on the next unplayed node',
        () async {
      final AdventureRunnerCubit first = runnerFor(profileId);
      await first.start();
      await first.continueStory();
      final String activityNode = first.state.node!.nodeId;
      expect(first.state.isOnActivity, isTrue);
      await first.completeActivity(finished);
      final String nextNode = first.state.node!.nodeId;
      await first.close();

      final AdventureRunnerCubit second = runnerFor(profileId);
      await second.start();

      expect(second.state.node!.nodeId, nextNode);
      expect(second.state.completedNodeIds, contains(activityNode),
          reason: 'the activity that was finished stays finished');
      await second.close();
    });

    test('a replay already under way is not restarted', () async {
      // The reported bug, and the worst of the set: a child who had finished
      // the story once lost *all* progress on every single re-entry, because a
      // completed chapter forced the cursor back to zero no matter what the
      // stored node said.
      await playToTheEnd(runnerFor(profileId)).then((r) => r.close());

      final AdventureRunnerCubit replay = await playForward(runnerFor(profileId), 3);
      final String left = replay.state.node!.nodeId;
      expect(left, isNot(bundle.requireAdventure('jungle').nodes.first.nodeId));
      await replay.close();

      final AdventureRunnerCubit again = runnerFor(profileId);
      await again.start();
      expect(again.state.node!.nodeId, left);
      await again.close();
    });

    test('a finished adventure with nothing in flight still replays from the '
        'first line', () async {
      // The flip side of the rule above. "Finished" and "finished once and
      // being played again right now" are told apart by whether a live node is
      // stored, so this case must keep working.
      await playToTheEnd(runnerFor(profileId)).then((r) => r.close());

      final AdventureRunnerCubit again = runnerFor(profileId);
      await again.start();
      expect(again.state.node!.beat, StoryBeat.openingProblem);
      expect(again.state.didResume, isFalse);
      await again.close();
    });

    test('a node renamed by a content update does not restart the story',
        () async {
      // The second restart path, and the one that would have fired for every
      // child on the next content release rather than only for repeat players.
      final AdventureRunnerCubit first = await playForward(runnerFor(profileId), 3);
      final StoryNode left = first.state.node!;
      await first.close();

      // Simulate the release: the child is parked on a node id that the
      // shipped content no longer has.
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.renamed_in_a_later_release',
        beat: left.beat,
      );

      final AdventureRunnerCubit second = runnerFor(profileId);
      await second.start();

      expect(second.state.node!.nodeId,
          isNot(bundle.requireAdventure('jungle').nodes.first.nodeId),
          reason: 'a renamed node must not send the child back to line one');
      expect(second.state.completedNodeIds,
          isNot(contains(second.state.node!.nodeId)),
          reason: 'it lands on work the child has not already done');
      await second.close();
    });
  });

  group('The resume resolver', () {
    // The rules above, as a table. The runner exercises them through I/O; this
    // pins each branch on its own so a regression names the rule it broke.
    const StoryResumeResolver resolver = StoryResumeResolver();
    late Adventure adventure;

    setUpAll(() => adventure = bundle.requireAdventure('jungle'));

    StoryResumePoint point({
      String? nodeId,
      StoryBeat? beat,
      bool isCompleted = false,
    }) {
      return StoryResumePoint(
        profileId: 1,
        adventureId: 'jungle',
        nodeId: nodeId,
        beat: beat,
        isChapterCompleted: isCompleted,
        updatedAt: DateTime(2026),
      );
    }

    test('an untouched adventure starts at the first node', () {
      expect(
        resolver.resolve(
            adventure: adventure, resume: null, completedNodeIds: <String>{}),
        0,
      );
    });

    test('a stored node resolves to its own index', () {
      final String third = adventure.nodes[2].nodeId;
      expect(
        resolver.resolve(
          adventure: adventure,
          resume: point(nodeId: third),
          completedNodeIds: <String>{},
        ),
        2,
      );
    });

    test('a finished chapter with no live node restarts', () {
      expect(
        resolver.resolve(
          adventure: adventure,
          resume: point(isCompleted: true),
          completedNodeIds: <String>{},
        ),
        0,
      );
    });

    test('a finished chapter with a live node resumes there', () {
      expect(
        resolver.resolve(
          adventure: adventure,
          resume: point(nodeId: adventure.nodes[3].nodeId, isCompleted: true),
          completedNodeIds: <String>{},
        ),
        3,
      );
    });

    test('an unknown node falls back to the first unfinished one', () {
      final Set<String> done = <String>{
        adventure.nodes[0].nodeId,
        adventure.nodes[1].nodeId,
      };
      expect(
        resolver.resolve(
          adventure: adventure,
          resume: point(nodeId: 'gone'),
          completedNodeIds: done,
        ),
        2,
      );
    });

    test('an unknown node prefers an unfinished node in the stored beat', () {
      // The beat is the drift handle: it is what survives a node being renamed
      // when the shape of the story has not changed.
      final StoryBeat target = adventure.nodes.last.beat;
      final int expected =
          adventure.nodes.indexWhere((StoryNode n) => n.beat == target);
      expect(
        resolver.resolve(
          adventure: adventure,
          resume: point(nodeId: 'gone', beat: target),
          completedNodeIds: <String>{},
        ),
        expected,
      );
    });
  });

  // -------------------------------------------------------------- cold start

  group('A cold start', () {
    test('reopens where the child left off, from a database on disk', () async {
      // In-memory Drift cannot tell "the cubit was recreated" from "the process
      // died and came back", and those are different claims. This one closes
      // the whole database and opens a new one over the same file, which is
      // what a force-kill actually looks like.
      final Directory dir =
          Directory.systemTemp.createTempSync('kidzo_resume_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final File file = File('${dir.path}/kidzo.sqlite');

      AppDatabase coldDatabase = AppDatabase(NativeDatabase(file));
      StoryDao coldDao = StoryDao(coldDatabase);
      final int coldProfile = await coldDatabase
          .into(coldDatabase.profiles)
          .insert(ProfilesCompanion.insert(name: 'Cold Start Child'));

      final AdventureRunnerCubit before = await playForward(
        runnerFor(coldProfile, withDao: coldDao),
        3,
      );
      final String left = before.state.node!.nodeId;
      await before.close();
      // No graceful shutdown hook: nothing is flushed here on purpose, because
      // an app the OS kills gets no chance to flush.
      await coldDatabase.close();

      coldDatabase = AppDatabase(NativeDatabase(file));
      coldDao = StoryDao(coldDatabase);
      addTearDown(() => coldDatabase.close());

      final AdventureRunnerCubit after =
          runnerFor(coldProfile, withDao: coldDao);
      await after.start();

      expect(after.state.node!.nodeId, left,
          reason: 'progress is written as it happens, not on the way out');
      await after.close();
    });
  });

  // ---------------------------------------------------- inside one activity

  group('Inside an activity', () {
    const EchoEngine engine = EchoEngine();

    /// A session for the echo engine wired to a real checkpoint sink.
    ActivityCubit<ActivityContent, dynamic> echoRun({
      required RecordingActivityCheckpointSink sink,
      int seed = 99,
      int stepCount = 6,
      ActivityCheckpoint? resume,
      ActivitySpec? spec,
    }) {
      final ActivitySpec built = spec ?? echoSpec(stepCount: stepCount);
      return engine.createCubit(engine.createSession(
        spec: built,
        services: ActivityServices(
          narrator: RecordingActivityNarrator(),
          soundboard: RecordingActivitySoundboard(),
          random: Random(seed),
          checkpointSink: sink,
        ),
        packs: const MapItemPackResolver(<String, ItemPack>{}),
        storyNodeId: 'jungle.n3',
        seed: seed,
        resume: resume,
      ));
    }

    Future<void> answerCorrectly(
      ActivityCubit<ActivityContent, dynamic> cubit,
      int times,
    ) async {
      for (int i = 0; i < times; i++) {
        final Object? step = cubit.state.engineStep;
        if (step is! EchoStep) {
          return;
        }
        await cubit.submit(ChoiceAttempt(step.correctOptionId));
      }
    }

    test('a checkpoint is written on arrival, before anything is answered',
        () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final ActivityCubit<ActivityContent, dynamic> cubit = echoRun(sink: sink);
      await cubit.start();

      expect(sink.latest, isNotNull,
          reason: 'a child who opens an activity and is interrupted three '
              'seconds later has still arrived');
      expect(sink.latest!.stepIndex, 0);
      expect(sink.latest!.seed, 99);
      await cubit.close();
    });

    test('a checkpoint is written at every step boundary', () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final ActivityCubit<ActivityContent, dynamic> cubit = echoRun(sink: sink);
      await cubit.start();
      await answerCorrectly(cubit, 3);

      expect(sink.saved.map((ActivityCheckpoint c) => c.stepIndex),
          containsAllInOrder(<int>[0, 1, 2, 3]));
      await cubit.close();
    });

    test('leaving midway reopens on the step the child was on', () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final ActivityCubit<ActivityContent, dynamic> first = echoRun(sink: sink);
      await first.start();
      await answerCorrectly(first, 3);
      final int leftOnStep = first.state.stepIndex;
      final int scoreSoFar = first.state.result.score;
      await first.close();

      expect(leftOnStep, 3);

      final ActivityCubit<ActivityContent, dynamic> second = echoRun(
        sink: RecordingActivityCheckpointSink(),
        resume: sink.latest,
      );
      await second.start();

      expect(second.state.stepIndex, leftOnStep,
          reason: 'the three rounds already played are not replayed');
      expect(second.state.result.score, scoreSoFar,
          reason: 'points already earned come back with the child, and are not '
              'awarded a second time');
      expect(second.didResumeFromCheckpoint, isTrue);
      await second.close();
    });

    test('resuming reproduces the same board, not a reshuffled one', () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final ActivityCubit<ActivityContent, dynamic> first = echoRun(sink: sink);
      await first.start();
      await answerCorrectly(first, 2);
      final EchoStep leftOn = first.state.engineStep! as EchoStep;
      await first.close();

      final ActivityCubit<ActivityContent, dynamic> second = echoRun(
        sink: RecordingActivityCheckpointSink(),
        resume: sink.latest,
      );
      await second.start();
      final EchoStep resumedOn = second.state.engineStep! as EchoStep;

      expect(resumedOn.stepId, leftOn.stepId);
      expect(resumedOn.optionIds, leftOn.optionIds,
          reason: 'the stored seed is what makes "step two" mean the same step '
              'two; without it the index points into a board that no longer '
              'exists');
      await second.close();
    });

    test('finishing clears the checkpoint, so a replay starts over', () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final ActivityCubit<ActivityContent, dynamic> cubit =
          echoRun(sink: sink, stepCount: 2);
      await cubit.start();
      await answerCorrectly(cubit, 2);

      expect(cubit.state.status, ActivityStatus.finished);
      expect(sink.wasCleared, isTrue);
      await cubit.close();
    });

    test('backing out keeps the checkpoint, because that is the one to come '
        'back to', () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final ActivityCubit<ActivityContent, dynamic> cubit = echoRun(sink: sink);
      await cubit.start();
      await answerCorrectly(cubit, 2);
      await cubit.abandon();

      expect(sink.wasCleared, isFalse);
      expect(sink.latest!.stepIndex, 2);
      await cubit.close();
    });

    group('an unusable checkpoint restarts the activity, never the story', () {
      // Requirement, not a fallback. Every mismatch below means the same thing:
      // this cursor cannot be trusted to name a step in this run, so the child
      // replays one mini-game and keeps everything else.
      Future<void> expectRestart(ActivityCheckpoint? stale, String why) async {
        final ActivityCubit<ActivityContent, dynamic> cubit = echoRun(
          sink: RecordingActivityCheckpointSink(),
          resume: stale,
        );
        await cubit.start();
        expect(cubit.state.status, ActivityStatus.running, reason: why);
        expect(cubit.state.stepIndex, 0, reason: why);
        expect(cubit.didResumeFromCheckpoint, isFalse, reason: why);
        await cubit.close();
      }

      ActivityCheckpoint base({
        String activityId = 'test.echo',
        String engineId = 'echo',
        int engineSchemaVersion = 1,
        int seed = 99,
        int stepIndex = 3,
        int cursorVersion = ActivityCheckpoint.currentCursorVersion,
      }) {
        return ActivityCheckpoint(
          activityId: activityId,
          engineId: engineId,
          engineSchemaVersion: engineSchemaVersion,
          seed: seed,
          stepIndex: stepIndex,
          score: 30,
          stepsIndependent: 3,
          hintsUsed: 0,
          elapsedSeconds: 12,
          cursorVersion: cursorVersion,
        );
      }

      test('a newer cursor format', () async {
        await expectRestart(
          base(cursorVersion: ActivityCheckpoint.currentCursorVersion + 1),
          'a cursor written by a build that knows fields this one does not',
        );
      });

      test('an engine whose step generation has changed', () async {
        await expectRestart(base(engineSchemaVersion: 2),
            'the engine bumped its schema, so step three is a different step');
      });

      test('a different activity', () async {
        await expectRestart(base(activityId: 'test.something_else'),
            'a checkpoint for one activity must never apply to another');
      });

      test('a different engine', () async {
        await expectRestart(
            base(engineId: 'counting'), 'engines do not share step spaces');
      });

      test('a different seed', () async {
        await expectRestart(base(seed: 12345),
            'the index would point into a board that was never built');
      });

      test('a step index the content no longer has', () async {
        await expectRestart(base(stepIndex: 99),
            'content shortened since the cursor was written');
      });

      test('a corrupt stored cursor', () async {
        expect(ActivityCheckpoint.decode('{not json'), isNull);
        expect(ActivityCheckpoint.decode('[]'), isNull);
        expect(ActivityCheckpoint.decode('{"v": 1}'), isNull);
        expect(ActivityCheckpoint.decode(null), isNull);
        expect(ActivityCheckpoint.decode(''), isNull);
      });
    });

    test('a checkpoint survives a round trip through storage', () async {
      final ActivityCheckpoint written = const ActivityCheckpoint(
        activityId: 'test.echo',
        engineId: 'echo',
        engineSchemaVersion: 1,
        seed: 4242,
        stepIndex: 2,
        score: 20,
        stepsIndependent: 2,
        hintsUsed: 1,
        elapsedSeconds: 33,
      );
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n3',
        beat: StoryBeat.obstacle,
      );
      await dao.saveActivityCheckpoint(
        profileId: profileId,
        adventureId: 'jungle',
        checkpoint: written,
      );

      final StoryResumePoint? read =
          await dao.resumePointFor(profileId, 'jungle');
      expect(read!.activity!.stepIndex, 2);
      expect(read.activity!.seed, 4242);
      expect(read.activity!.score, 20);
      expect(read.beat, StoryBeat.obstacle);
      expect(read.nodeId, 'jungle.n3');
    });

    test('moving to another node drops the checkpoint; re-entering the same '
        'node keeps it', () async {
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n3',
        beat: StoryBeat.obstacle,
      );
      await dao.saveActivityCheckpoint(
        profileId: profileId,
        adventureId: 'jungle',
        checkpoint: const ActivityCheckpoint(
          activityId: 'test.echo',
          engineId: 'echo',
          engineSchemaVersion: 1,
          seed: 1,
          stepIndex: 2,
          score: 0,
          stepsIndependent: 0,
          hintsUsed: 0,
          elapsedSeconds: 0,
        ),
      );

      // Re-entering the same node is the resume path itself.
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n3',
        beat: StoryBeat.obstacle,
      );
      expect((await dao.resumePointFor(profileId, 'jungle'))!.activity,
          isNotNull);

      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n4',
        beat: StoryBeat.obstacle,
      );
      expect((await dao.resumePointFor(profileId, 'jungle'))!.activity, isNull,
          reason: 'a checkpoint belongs to the activity that wrote it');
    });

    test('backing out and going straight back in resumes mid-activity',
        () async {
      // The near miss in this whole design. The cursor survived a cold start
      // but not the commonest interruption of all — a child who backs out of a
      // mini-game and immediately taps "let's play" again. The runner had the
      // checkpoint only as a one-shot field set at `start`, so re-entering the
      // same node handed the engine nothing and the activity began again at
      // round one with the cursor still sitting in the database.
      final AdventureRunnerCubit runner = runnerFor(profileId);
      await runner.start();
      await runner.continueStory();
      final String activityNode = runner.state.node!.nodeId;
      final ActivitySpec spec = bundle.requireActivity(
          bundle.requireAdventure('jungle').nodeById(activityNode)!.activityRef!);

      // Four rounds in, the child backs out. The engine keeps its cursor on
      // abandon, which is the point of keeping it.
      await dao.saveActivityCheckpoint(
        profileId: profileId,
        adventureId: 'jungle',
        checkpoint: ActivityCheckpoint(
          activityId: spec.instanceId,
          engineId: spec.engineId,
          engineSchemaVersion: 1,
          seed: 31,
          stepIndex: 4,
          score: 40,
          stepsIndependent: 4,
          hintsUsed: 0,
          elapsedSeconds: 55,
        ),
      );
      await runner.completeActivity(const ActivityResult(
        completion: ActivityCompletion.abandoned,
        score: 40,
        maxScore: 60,
        stepsTotal: 6,
        stepsIndependent: 4,
        hintsUsed: 0,
        durationSeconds: 55,
      ));

      expect(runner.state.node!.nodeId, activityNode,
          reason: 'backing out keeps the child on the beat they never played');
      expect(runner.state.activityResume, isNotNull,
          reason: 'and going back in has to pick the mini-game up, not restart '
              'it — the cursor is right there');
      expect(runner.state.activityResume!.stepIndex, 4);
      await runner.close();
    });

    test('the runner hands the stored checkpoint to the node it belongs to',
        () async {
      final AdventureRunnerCubit first = runnerFor(profileId);
      await first.start();
      await first.continueStory();
      final String activityNode = first.state.node!.nodeId;
      await first.close();

      final ActivitySpec spec = bundle.requireActivity(
          bundle.requireAdventure('jungle').nodeById(activityNode)!.activityRef!);
      await dao.saveActivityCheckpoint(
        profileId: profileId,
        adventureId: 'jungle',
        checkpoint: ActivityCheckpoint(
          activityId: spec.instanceId,
          engineId: spec.engineId,
          engineSchemaVersion: 1,
          seed: 777,
          stepIndex: 1,
          score: 10,
          stepsIndependent: 1,
          hintsUsed: 0,
          elapsedSeconds: 8,
        ),
      );

      final AdventureRunnerCubit second = runnerFor(profileId);
      await second.start();
      expect(second.state.node!.nodeId, activityNode);
      expect(second.state.activityResume, isNotNull);
      expect(second.state.activityResume!.stepIndex, 1);
      await second.close();
    });
  });

  // ------------------------------------------------------- no double credit

  group('Coming back twice grants nothing twice', () {
    test('a repeated resume never duplicates the page', () async {
      await playToTheEnd(runnerFor(profileId)).then((r) => r.close());

      for (int again = 0; again < 3; again++) {
        final AdventureRunnerCubit runner = runnerFor(profileId);
        await runner.start();
        await runner.close();
      }

      expect((await dao.rewardsFor(profileId)).length, 1);
    });

    test('the page celebrates once, however often the child returns to the '
        'node that hands it over', () async {
      // The reward row was always idempotent. The *celebration* keyed off
      // reaching the node, so a child who closed the app on the resolution beat
      // watched the page fly into the book again on every return.
      final AdventureRunnerCubit first = runnerFor(profileId);
      await first.start();
      int guard = 0;
      while (first.state.status == AdventureRunnerStatus.playing &&
          first.state.justEarnedRewardId == null &&
          guard++ < 40) {
        if (first.state.isOnActivity) {
          await first.completeActivity(finished);
        } else {
          await first.continueStory();
        }
      }
      expect(first.state.justEarnedRewardId, isNotNull,
          reason: 'the first arrival is the one that earns it');
      await first.close();

      final AdventureRunnerCubit second = runnerFor(profileId);
      await second.start();
      expect(second.state.node!.rewardId, isNotNull,
          reason: 'this test only means anything if it lands on the same node');
      expect(second.state.justEarnedRewardId, isNull);
      await second.close();
    });

    test('a repeated resume never duplicates a node score', () async {
      final AdventureRunnerCubit first = runnerFor(profileId);
      await first.start();
      await first.continueStory();
      final String activityNode = first.state.node!.nodeId;
      await first.completeActivity(finished);
      await first.close();

      for (int again = 0; again < 3; again++) {
        final AdventureRunnerCubit runner = runnerFor(profileId);
        await runner.start();
        await runner.close();
      }

      final List<StoryNodeProgressData> rows =
          await dao.nodesFor(profileId, 'jungle');
      final Iterable<StoryNodeProgressData> forNode = rows.where(
          (StoryNodeProgressData row) => row.nodeId == activityNode);
      expect(forNode.length, 1);
      expect(forNode.first.score, 30,
          reason: 'one play, one row, one score — not an accumulating total');
    });

    test('replaying a node overwrites its row rather than adding one',
        () async {
      final AdventureRunnerCubit first = runnerFor(profileId);
      await first.start();
      await first.continueStory();
      final String activityNode = first.state.node!.nodeId;
      await first.completeActivity(finished);
      await first.close();

      // Park the child back on the node they already finished and play it
      // again, which is what a replay does.
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: activityNode,
        beat: StoryBeat.discovery,
      );
      final AdventureRunnerCubit second = runnerFor(profileId);
      await second.start();
      await second.completeActivity(finished);
      await second.close();

      final List<StoryNodeProgressData> rows =
          await dao.nodesFor(profileId, 'jungle');
      expect(
        rows.where((StoryNodeProgressData r) => r.nodeId == activityNode).length,
        1,
      );
    });
  });

  // --------------------------------------------------------------- profiles

  group('Two children on one tablet', () {
    test('do not share a resume point', () async {
      final int sibling = await database
          .into(database.profiles)
          .insert(ProfilesCompanion.insert(name: 'Sibling'));

      final AdventureRunnerCubit mine = await playForward(runnerFor(profileId), 4);
      final String myNode = mine.state.node!.nodeId;
      await mine.close();

      final AdventureRunnerCubit theirs = runnerFor(sibling);
      await theirs.start();
      expect(theirs.state.node!.nodeId,
          bundle.requireAdventure('jungle').nodes.first.nodeId,
          reason: 'a sibling opening the story for the first time starts it');
      expect(theirs.state.node!.nodeId, isNot(myNode));
      await theirs.close();

      // And mine is untouched by theirs having played.
      await theirs.close();
      final AdventureRunnerCubit mineAgain = runnerFor(profileId);
      await mineAgain.start();
      expect(mineAgain.state.node!.nodeId, myNode);
      await mineAgain.close();
    });

    test('do not share a page', () async {
      final int sibling = await database
          .into(database.profiles)
          .insert(ProfilesCompanion.insert(name: 'Sibling'));
      await playToTheEnd(runnerFor(profileId)).then((r) => r.close());

      expect(await dao.rewardsFor(sibling), isEmpty);
      expect((await dao.rewardsFor(profileId)).length, 1);
    });

    test('do not share an activity checkpoint', () async {
      final int sibling = await database
          .into(database.profiles)
          .insert(ProfilesCompanion.insert(name: 'Sibling'));
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n3',
        beat: StoryBeat.obstacle,
      );
      await dao.saveActivityCheckpoint(
        profileId: profileId,
        adventureId: 'jungle',
        checkpoint: const ActivityCheckpoint(
          activityId: 'jungle.count_watchers',
          engineId: 'counting',
          engineSchemaVersion: 1,
          seed: 5,
          stepIndex: 2,
          score: 0,
          stepsIndependent: 0,
          hintsUsed: 0,
          elapsedSeconds: 0,
        ),
      );

      expect(await dao.resumePointFor(sibling, 'jungle'), isNull);
    });
  });

  // ------------------------------------------------- stale callbacks & UI

  group('A superseded callback cannot move the story', () {
    test('a continue tagged with the previous node is ignored', () async {
      // A narration future resolving after the story has moved, a failsafe
      // timer firing late, a second tap landing during the hand-off: all of
      // them arrive carrying the node they were issued for. Advancing on one
      // would skip a beat the child never saw, silently.
      final AdventureRunnerCubit runner = runnerFor(profileId);
      await runner.start();
      final String first = runner.state.node!.nodeId;
      await runner.continueStory(fromNodeId: first);
      final String second = runner.state.node!.nodeId;
      expect(second, isNot(first));

      await runner.continueStory(fromNodeId: first);
      expect(runner.state.node!.nodeId, second,
          reason: 'the late callback belonged to a beat already left behind');
      await runner.close();
    });

    test('an activity result tagged with the previous node is ignored',
        () async {
      final AdventureRunnerCubit runner = runnerFor(profileId);
      await runner.start();
      final String beatNode = runner.state.node!.nodeId;
      await runner.continueStory(fromNodeId: beatNode);
      final String activityNode = runner.state.node!.nodeId;

      await runner.completeActivity(finished, fromNodeId: beatNode);

      expect(runner.state.node!.nodeId, activityNode);
      final List<StoryNodeProgressData> rows =
          await dao.nodesFor(profileId, 'jungle');
      expect(
        rows.where((StoryNodeProgressData r) => r.nodeId == activityNode),
        isEmpty,
        reason: 'a stale result must not be written against the current node',
      );
      await runner.close();
    });

    test('a stale callback cannot move a story that was just restored',
        () async {
      final AdventureRunnerCubit first = await playForward(runnerFor(profileId), 3);
      final String staleNode =
          bundle.requireAdventure('jungle').nodes.first.nodeId;
      await first.close();

      final AdventureRunnerCubit restored = runnerFor(profileId);
      await restored.start();
      final String resumedAt = restored.state.node!.nodeId;
      expect(resumedAt, isNot(staleNode));

      await restored.continueStory(fromNodeId: staleNode);
      expect(restored.state.node!.nodeId, resumedAt);
      await restored.close();
    });
  });

  group('The screen', () {
    late ActivityEngineRegistry registry;
    late PreloadedAdventureContentSource content;
    late AdventureContentBundle preloaded;
    late AppLocalizations englishL10n;

    setUpAll(() async {
      registry = buildDefaultEngineRegistry();
      content = await PreloadedAdventureContentSource.load();
      preloaded = await AdventureContentLoader(content).load();
      englishL10n = AppLocalizations(
        const Locale('en', ''),
        (json.decode(File('assets/lang/en.json').readAsStringSync())
                as Map<String, dynamic>)
            .map((String key, dynamic value) =>
                MapEntry<String, String>(key, '$value')),
      );
    });

    Widget runnerScreen() {
      return BlocProvider<LanguageCubit>(
        create: (_) => LanguageCubit(),
        child: MaterialApp(
          locale: const Locale('en', ''),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            _SynchronousLocalizations(englishL10n),
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdventureRunnerScreen(
            bundle: preloaded,
            registry: registry,
            adventureId: 'jungle',
            profileId: profileId,
            storyDao: dao,
            narrator: RecordingActivityNarrator(),
            soundboard: RecordingActivitySoundboard(),
          ),
        ),
      );
    }

    Future<void> settle(WidgetTester tester) async {
      for (int frame = 0; frame < 16; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    testWidgets('a rotation does not reset the story', (WidgetTester tester) async {
      // An orientation change rebuilds the tree and re-runs layout. Anything
      // that lived only in a widget's state — which is where "where am I" used
      // to live between saves — would be lost here.
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);

      await tester.pumpWidget(runnerScreen());
      await settle(tester);

      final StoryNode second = preloaded.requireAdventure('jungle').nodes[1];
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: second.nodeId,
        beat: second.beat,
      );

      tester.view.physicalSize = const Size(800, 400);
      await settle(tester);

      expect(tester.takeException(), isNull);
      final StoryChapterProgressData? chapter =
          await dao.chapterFor(profileId, 'jungle');
      expect(chapter!.currentNodeId, second.nodeId,
          reason: 'rebuilding is not progress, and must not overwrite it');
    });

    testWidgets('opening an incomplete adventure continues it with no dialog',
        (WidgetTester tester) async {
      // A four-year-old cannot read "Do you want to resume?". The tap is the
      // whole of the affordance.
      final Adventure adventure = preloaded.requireAdventure('jungle');
      final StoryNode fifth = adventure.nodes[4];
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: fifth.nodeId,
        beat: fifth.beat,
      );

      await tester.pumpWidget(runnerScreen());
      await settle(tester);

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text(fifth.lines.first.resolve('en')),
        findsOneWidget,
        reason: 'it opened straight onto the beat the child left off on',
      );
    });
  });
}
