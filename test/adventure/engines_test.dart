import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/hidden_clue_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/multiple_choice/multiple_choice_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';

import 'support/disk_content_source.dart';

/// Every engine, against the real authored content.
///
/// Two things are checked for all of them: the shared base-cubit guarantees
/// still hold (a child always finishes), and generation is deterministic under
/// a seed — an engine whose output cannot be reproduced cannot be tested.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle = await const AdventureContentLoader(DiskAdventureContentSource())
        .load();
  });

  ActivityCubit<ActivityContent, dynamic> cubitFor(
    String activityId, {
    int seed = 11,
    String languageCode = 'en',
  }) {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    return engine.createCubit(engine.createSession(
      spec: spec,
      services: ActivityServices.forTest(seed: seed, languageCode: languageCode),
      packs: bundle.packResolver,
      storyNodeId: 'test.node',
    ));
  }

  group('Shared guarantees hold for every authored activity', () {
    test('each one starts, runs and exposes a step', () async {
      for (final String activityId in bundle.activities.keys) {
        final ActivityCubit<ActivityContent, dynamic> cubit =
            cubitFor(activityId);
        await cubit.start();
        expect(cubit.state.status, ActivityStatus.running,
            reason: '$activityId failed to start');
        expect(cubit.state.stepCount, greaterThan(0));
        expect(cubit.state.engineStep, isNotNull,
            reason: '$activityId published no step for its board to render');
        await cubit.close();
      }
    });

    test('generation is deterministic under a seed', () async {
      for (final String activityId in bundle.activities.keys) {
        final ActivityCubit<ActivityContent, dynamic> a =
            cubitFor(activityId, seed: 99);
        final ActivityCubit<ActivityContent, dynamic> b =
            cubitFor(activityId, seed: 99);
        await a.start();
        await b.start();
        expect(a.state.stepCount, b.state.stepCount,
            reason: '$activityId is not reproducible under one seed');
        expect(
          a.state.view!.liveOptionIds,
          b.state.view!.liveOptionIds,
          reason: '$activityId produced different options for the same seed',
        );
        await a.close();
        await b.close();
      }
    });

    test('a locked board rejects input', () async {
      for (final String activityId in bundle.activities.keys) {
        final ActivityCubit<ActivityContent, dynamic> cubit =
            cubitFor(activityId);
        // Never started, so still loading.
        await cubit.submit(const ChoiceAttempt('x'));
        expect(cubit.state.status, ActivityStatus.loading);
        await cubit.close();
      }
    });

    test('Arabic content reaches the child in Arabic', () async {
      for (final String activityId in bundle.activities.keys) {
        final ActivityCubit<ActivityContent, dynamic> cubit =
            cubitFor(activityId, languageCode: 'ar');
        await cubit.start();
        final String prompt = cubit.state.view!.prompt.resolve('ar');
        expect(prompt, isNotEmpty);
        expect(RegExp('[؀-ۿ]').hasMatch(prompt), isTrue,
            reason: '$activityId showed non-Arabic text to an Arabic child');
        await cubit.close();
      }
    });
  });

  group('counting', () {
    test('the correct numeral is always among the options', () async {
      // Otherwise the step is unanswerable and the ladder cannot terminate.
      for (int seed = 0; seed < 200; seed++) {
        final CountingCubit cubit =
            cubitFor('jungle_count_watchers', seed: seed) as CountingCubit;
        await cubit.start();
        for (final step in cubit.buildSteps()) {
          expect(step.numeralOptions, contains(step.targetCount),
              reason: 'seed $seed produced a step with no correct answer');
        }
        await cubit.close();
      }
    });

    test('the target stays inside the authored range', () async {
      for (int seed = 0; seed < 200; seed++) {
        final CountingCubit cubit =
            cubitFor('jungle_count_watchers', seed: seed) as CountingCubit;
        await cubit.start();
        for (final step in cubit.buildSteps()) {
          expect(step.targetCount, inInclusiveRange(2, 5));
        }
        await cubit.close();
      }
    });

    test('options are near neighbours, never wild guesses', () async {
      // Offering 3 against 9 teaches nothing: a child can eliminate 9 without
      // counting anything.
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      for (final step in cubit.buildSteps()) {
        for (final int option in step.numeralOptions) {
          expect((option - step.targetCount).abs(), lessThanOrEqualTo(3));
          expect(option, greaterThanOrEqualTo(1));
        }
      }
      await cubit.close();
    });

    test('options are sorted, so the answer never moves between attempts',
        () async {
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      for (final step in cubit.buildSteps()) {
        final List<int> sorted = List<int>.of(step.numeralOptions)..sort();
        expect(step.numeralOptions, sorted);
      }
      await cubit.close();
    });

    test('judging is pure and answers only to the target', () async {
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      final step = cubit.currentStep;
      expect(cubit.judge(step, QuantityAttempt(step.targetCount)).isCorrect,
          isTrue);
      expect(cubit.judge(step, QuantityAttempt(step.targetCount + 1)).isCorrect,
          isFalse);
      // Calling judge repeatedly must not change anything.
      expect(cubit.judge(step, QuantityAttempt(step.targetCount)).isCorrect,
          isTrue);
      expect(cubit.state.stepIndex, 0);
      await cubit.close();
    });

    test('playing it through completes', () async {
      final CountingCubit cubit =
          cubitFor('jungle_count_watchers') as CountingCubit;
      await cubit.start();
      while (cubit.state.status == ActivityStatus.running) {
        await cubit.submit(QuantityAttempt(cubit.currentStep.targetCount));
      }
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      await cubit.close();
    });
  });

  group('multiple_choice', () {
    test('the correct item is always offered', () async {
      for (int seed = 0; seed < 50; seed++) {
        final MultipleChoiceCubit cubit =
            cubitFor('jungle_ask_animals', seed: seed) as MultipleChoiceCubit;
        await cubit.start();
        for (final step in cubit.buildSteps()) {
          expect(
            step.orderedItems.map((i) => i.id),
            contains(step.question.correctItem.id),
          );
        }
        await cubit.close();
      }
    });

    test('every question has a reveal line, so the answer moves the story',
        () async {
      // This is what makes the activity causal rather than decorative: the
      // animal does not merely get picked, it says what it saw.
      final MultipleChoiceCubit cubit =
          cubitFor('jungle_ask_animals') as MultipleChoiceCubit;
      await cubit.start();
      for (final step in cubit.buildSteps()) {
        expect(step.question.revealLine.isEmpty, isFalse,
            reason: '${step.question.id} has no reveal line');
        expect(step.question.revealLine.hasLanguage('ar'), isTrue);
      }
      await cubit.close();
    });

    test('playing it through completes', () async {
      final MultipleChoiceCubit cubit =
          cubitFor('jungle_ask_animals') as MultipleChoiceCubit;
      await cubit.start();
      while (cubit.state.status == ActivityStatus.running) {
        await cubit.submit(
            ChoiceAttempt(cubit.currentStep.question.correctItem.id));
      }
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      expect(cubit.state.result.stepsIndependent, 3);
      await cubit.close();
    });
  });

  group('hidden_clue', () {
    test('a tap on the clue counts, a tap far away does not', () async {
      final HiddenClueCubit cubit =
          cubitFor('jungle_find_page') as HiddenClueCubit;
      await cubit.start();
      final step = cubit.currentStep;

      expect(cubit.judge(step, TapPointAttempt(step.clue.position)).isCorrect,
          isTrue);
      expect(
        cubit
            .judge(step, const TapPointAttempt(Offset(0.02, 0.02)))
            .isCorrect,
        isFalse,
      );
      await cubit.close();
    });

    test('a near miss is forgiven', () async {
      // A child who found the clue but missed it by a few millimetres has a
      // motor problem; scoring that as "did not find it" is a measurement error.
      final HiddenClueCubit cubit =
          cubitFor('jungle_find_page') as HiddenClueCubit;
      await cubit.start();
      final step = cubit.currentStep;
      final Offset nearMiss =
          step.clue.position + const Offset(0.05, 0.05);
      expect(cubit.judge(step, TapPointAttempt(nearMiss)).isCorrect, isTrue);
      await cubit.close();
    });

    test('decoys never sit on top of the clue', () async {
      // Otherwise the search becomes luck rather than looking.
      for (int seed = 0; seed < 100; seed++) {
        final HiddenClueCubit cubit =
            cubitFor('jungle_find_page', seed: seed) as HiddenClueCubit;
        await cubit.start();
        for (final step in cubit.buildSteps()) {
          for (final entry in step.noisePositions) {
            expect((entry.value - step.clue.position).distance,
                greaterThan(0.1),
                reason: 'seed $seed put a decoy on the clue');
          }
        }
        await cubit.close();
      }
    });

    test('decoy positions stay inside the scene', () async {
      for (int seed = 0; seed < 100; seed++) {
        final HiddenClueCubit cubit =
            cubitFor('jungle_find_page', seed: seed) as HiddenClueCubit;
        await cubit.start();
        for (final step in cubit.buildSteps()) {
          for (final entry in step.noisePositions) {
            expect(entry.value.dx, inInclusiveRange(0.0, 1.0));
            expect(entry.value.dy, inInclusiveRange(0.0, 1.0));
          }
        }
        await cubit.close();
      }
    });
  });

  group('sorting', () {
    test('every token has a bin that accepts it', () async {
      final SortingCubit cubit =
          cubitFor('jungle_sort_watchers') as SortingCubit;
      await cubit.start();
      for (final step in cubit.buildSteps()) {
        expect(step.binById(step.correctBinId), isNotNull);
      }
      await cubit.close();
    });

    test('a near-miss drop is recorded as motor, not knowledge', () async {
      final SortingCubit cubit =
          cubitFor('jungle_sort_watchers') as SortingCubit;
      await cubit.start();
      final step = cubit.currentStep;
      final String wrongBin = step.bins
          .firstWhere((b) => b.id != step.correctBinId)
          .id;

      final judgement = cubit.judge(
        step,
        PlacementAttempt(
          tokenId: step.item.id,
          targetId: wrongBin,
          droppedAtDistance: 0.1,
        ),
      );
      expect(judgement.outcome, AttemptOutcome.wrongSlotButRightItem,
          reason: 'one means bigger targets, the other means more teaching');

      final far = cubit.judge(
        step,
        PlacementAttempt(
          tokenId: step.item.id,
          targetId: wrongBin,
          droppedAtDistance: 0.9,
        ),
      );
      expect(far.outcome, AttemptOutcome.wrongItem);
      await cubit.close();
    });

    test('bins are carried on the step so the board needs no cubit', () async {
      final SortingCubit cubit =
          cubitFor('jungle_sort_watchers') as SortingCubit;
      await cubit.start();
      expect(cubit.currentStep.bins.length, greaterThanOrEqualTo(2));
      await cubit.close();
    });

    test('playing it through completes', () async {
      final SortingCubit cubit =
          cubitFor('jungle_sort_watchers') as SortingCubit;
      await cubit.start();
      while (cubit.state.status == ActivityStatus.running) {
        await cubit.submit(PlacementAttempt(
          tokenId: cubit.currentStep.item.id,
          targetId: cubit.currentStep.correctBinId,
        ));
      }
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      await cubit.close();
    });
  });

  group('The world answers, rather than a verdict', () {
    // The two adaptations Adventure 3 made to shipped engines. Both exist for
    // the same reason: an activity whose only sign that anything happened is a
    // sound and a step counter is a quiz wearing the story's clothes.

    test('a bin says which way it sends things', () async {
      final SortingCubit cubit =
          cubitFor('ocean_float_or_sink') as SortingCubit;
      await cubit.start();

      final Map<String, SettleMotion> motions = <String, SettleMotion>{
        for (final SortingBin bin in cubit.currentStep.bins)
          bin.id: bin.settleMotion,
      };
      expect(motions['surface'], SettleMotion.rise);
      expect(motions['seabed'], SettleMotion.sink);
      // The board turns this into the correction a misplaced float gets: it
      // drifts back up out of the sea floor, which tells the child what the
      // thing *is* rather than only that they were wrong.
      expect(SettleMotion.rise.direction, lessThan(0));
      expect(SettleMotion.sink.direction, greaterThan(0));
      await cubit.close();
    });

    test('a bin without a declared motion just settles', () async {
      // Every sorting activity written before this stays exactly as it was.
      final SortingCubit cubit =
          cubitFor('jungle_sort_watchers') as SortingCubit;
      await cubit.start();
      for (final SortingBin bin in cubit.currentStep.bins) {
        expect(bin.settleMotion, SettleMotion.settle);
      }
      await cubit.close();
    });

    test('what has been sorted stays visible in the bin it went to', () async {
      // The lift the child is building has to be on screen, so the history is
      // carried on the step rather than accumulated in the board — which also
      // means it survives a child leaving half way and coming back.
      final SortingCubit cubit =
          cubitFor('ocean_float_or_sink') as SortingCubit;
      await cubit.start();

      expect(cubit.currentStep.alreadySorted, isEmpty);
      int placed = 0;
      while (cubit.state.status == ActivityStatus.running) {
        final SortingStep step = cubit.currentStep;
        expect(step.alreadySorted.length, placed,
            reason: 'the bins must hold exactly what has been sorted so far');
        for (final SortedToken token in step.alreadySorted) {
          expect(step.sortedInto(token.binId), contains(token));
        }
        await cubit.submit(PlacementAttempt(
          tokenId: step.item.id,
          targetId: step.correctBinId,
        ));
        placed++;
      }
      await cubit.close();
    });

    test('a finished trace figure stays lit while the next is drawn', () async {
      final TraceCubit cubit = cubitFor('ocean_light_the_wall') as TraceCubit;
      await cubit.start();

      final List<TraceStep> steps = cubit.buildSteps();
      expect(steps.first.alreadyDrawn, isEmpty,
          reason: 'nothing is drawn before the first figure');
      expect(steps.last.alreadyDrawn, hasLength(steps.length - 1),
          reason: 'the whole route has to be on screen at the end, or the '
              'child only ever sees the last stroke of what they made');
      await cubit.close();
    });

    test('a trace activity that did not ask for it keeps the old behaviour',
        () async {
      // Two unrelated shapes in one box would pile up. Off by default.
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      for (final TraceStep step in cubit.buildSteps()) {
        expect(step.alreadyDrawn, isEmpty);
      }
      await cubit.close();
    });
  });

  group('The no-fail ladder terminates for every engine', () {
    test('three wrong answers always reach modelled, then completion',
        () async {
      for (final String activityId in bundle.activities.keys) {
        final ActivityCubit<ActivityContent, dynamic> cubit =
            cubitFor(activityId);
        await cubit.start();

        bool everReachedModelled = false;
        bool everNamedTheAnswer = false;

        int guard = 0;
        while (cubit.state.status == ActivityStatus.running && guard < 200) {
          guard++;
          // A deliberately invalid attempt: wrong for every engine.
          await cubit.submit(const ChoiceAttempt('__definitely_wrong__'));
          if (cubit.state.scaffoldLevel == ScaffoldLevel.modelled) {
            everReachedModelled = true;
            // Where an engine's answer *is* one option, the board now offers
            // only that one, so feeding back the id it highlighted is how a
            // real child finishes. Where the answer is a configuration or a
            // remembered order there is no such id, and the run still has to
            // end — the base cubit credits the step after modelling, which is
            // what the `finished` assertion below actually proves.
            final String? correct = cubit.state.view?.highlightOptionId;
            if (correct != null) {
              everNamedTheAnswer = true;
              await cubit.submit(ChoiceAttempt(correct));
            }
          }
        }

        expect(cubit.state.status, ActivityStatus.finished,
            reason: '$activityId never terminated under repeated wrong input');
        expect(cubit.state.result.completion, ActivityCompletion.completed);
        expect(cubit.state.result.score, greaterThan(0),
            reason: 'never-zero is the house rule');

        // An engine whose answer is a single option must still name it, or the
        // modelled rung has nothing to demonstrate and the child is carried
        // through by the credit path instead of being taught anything.
        const Set<InteractionMode> picksOneThing = <InteractionMode>{
          InteractionMode.chooseOne,
          InteractionMode.dragToTarget,
          InteractionMode.tapInScene,
        };
        final ActivityEngineDescriptor descriptor = registry
            .require(bundle.requireActivity(activityId).engineId)
            .descriptor;
        if (everReachedModelled &&
            descriptor.interactionModes.any(picksOneThing.contains)) {
          expect(everNamedTheAnswer, isTrue,
              reason: '$activityId reached modelled without naming the '
                  'correct option, so the child is never shown what to do');
        }
        await cubit.close();
      }
    });
  });

  group('Randomness', () {
    /// Builds a counting activity from an inline payload.
    ///
    /// The authored Adventure now uses fixed rounds, so it is the wrong fixture
    /// for a question about randomness. This one exercises the generated path
    /// the engine still offers to content whose counts carry no story weight.
    CountingCubit generatedCounting({required int seed, int roundCount = 3}) {
      final ActivitySpec spec = ActivitySpec.fromJson(
        <String, dynamic>{
          'instanceId': 'test.generated_counting',
          'engineId': 'counting',
          'locales': const <String>['en'],
          'narration': const <String, dynamic>{
            'prompt': <String, String>{'en': 'How many?'},
          },
          'payload': <String, dynamic>{
            'mode': 'countAndPick',
            'layout': 'tenFrame',
            'countRange': const <int>[2, 6],
            'roundCount': roundCount,
            'itemsRef': 'packs/animals',
            'itemIds': const <String>['monkey', 'bird', 'rabbit'],
          },
        },
        sourcePath: 'test/generated_counting.json',
      );
      final ActivityEngine<ActivityContent> engine = registry.require('counting');
      return engine.createCubit(engine.createSession(
        spec: spec,
        services: ActivityServices.forTest(seed: seed),
        packs: bundle.packResolver,
        storyNodeId: 'test.node',
      )) as CountingCubit;
    }

    test('different seeds do produce different activities', () async {
      // The mirror of the determinism test: a "random" engine that ignores its
      // seed would pass that one and still be broken.
      final Set<String> firstTargets = <String>{};
      for (int seed = 0; seed < 25; seed++) {
        final CountingCubit cubit = generatedCounting(seed: seed);
        await cubit.start();
        firstTargets.add(cubit.currentStep.targetCount.toString());
        await cubit.close();
      }
      expect(firstTargets.length, greaterThan(1));
    });

    test('a generated activity does not ask the same question twice', () async {
      // Regression. Rounds used to be drawn independently, so a three-round
      // counting activity could deal 4, 4, 4 — which a child reads not as bad
      // luck but as the app being stuck. Distinct answers are now drawn without
      // replacement while the range has any left.
      for (int seed = 0; seed < 60; seed++) {
        final CountingCubit cubit = generatedCounting(seed: seed);
        await cubit.start();
        final List<int> targets = cubit
            .buildSteps()
            .map((CountingStep step) => step.targetCount)
            .toList();
        expect(targets.toSet().length, targets.length,
            reason: 'seed $seed repeated a count within one activity: $targets');
        await cubit.close();
      }
    });

    test('authored rounds are the same every time, on purpose', () async {
      // The opposite guarantee, and it is just as load-bearing: the story beat
      // after this activity says "nine watchers", and it can only say that
      // because the counts do not move between runs.
      final Set<String> shapes = <String>{};
      for (int seed = 0; seed < 25; seed++) {
        final CountingCubit cubit =
            cubitFor('jungle_count_watchers', seed: seed) as CountingCubit;
        await cubit.start();
        shapes.add(cubit
            .buildSteps()
            .map((CountingStep step) => '${step.item.id}x${step.targetCount}')
            .join(','));
        await cubit.close();
      }
      expect(shapes.length, 1,
          reason: 'authored counts must not vary with the seed');
      expect(shapes.single, 'monkeyx3,birdx4,rabbitx2');
    });

    test('an injected Random is actually used', () {
      final ActivityServices services = ActivityServices.forTest(seed: 3);
      expect(services.random, isA<Random>());
    });
  });
}
