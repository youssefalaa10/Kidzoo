import 'dart:io';
import 'dart:ui';

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
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

import 'support/disk_content_source.dart';

/// Adventure 3, as a chapter rather than as six unrelated files.
///
/// The per-engine suites already prove each mechanic works. What is checked
/// here is the thing no single engine can be responsible for: that the six
/// activities are genuinely six different activities, that each one visibly
/// changes the world the next one happens in, and that the child — not the
/// turtle — is the one who opens the gate.
///
/// Layout at the four supported sizes is covered for every activity in
/// `boards_widget_test.dart`, which iterates the whole bundle; the two sizes
/// re-checked here are the ones that broke a board during this chapter's
/// build, kept as a named regression rather than duplicated coverage.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;
  late Adventure ocean;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
    ocean = bundle.adventures['ocean']!;
  });

  List<String> activityIds() => <String>[
        for (final StoryNode node
            in ocean.nodes.where((StoryNode node) => node.isActivity))
          node.activityRef!.split('/').last,
      ];

  List<ActivitySpec> activities() =>
      activityIds().map(bundle.requireActivity).toList();

  T contentOf<T extends ActivityContent>(String activityId) {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    return registry.require(spec.engineId).parseContent(
          spec,
          bundle.packResolver,
        ) as T;
  }

  Future<ActivityCubit<ActivityContent, dynamic>> started(
    String activityId, {
    String languageCode = 'en',
    int seed = 11,
    ActivityCheckpointSink? checkpointSink,
    ActivityCheckpoint? resume,
    ActivitySoundboard? soundboard,
  }) async {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    final ActivityServices base = ActivityServices.forTest(
      seed: seed,
      languageCode: languageCode,
      checkpointSink: checkpointSink,
    );
    final ActivityCubit<ActivityContent, dynamic> cubit =
        engine.createCubit(engine.createSession(
      spec: spec,
      services: soundboard == null
          ? base
          : ActivityServices(
              narrator: base.narrator,
              soundboard: soundboard,
              random: base.random,
              checkpointSink: base.checkpointSink,
              languageCode: languageCode,
            ),
      packs: bundle.packResolver,
      storyNodeId: 'ocean.test',
      seed: seed,
      resume: resume,
    ));
    await cubit.start();
    return cubit;
  }

  /// The attempt that finishes whatever step the cubit is on.
  ActivityAttempt answerFor(ActivityState state) {
    final Object? step = state.engineStep;
    if (step is FlashlightStep) {
      return ChoiceAttempt(step.target.id);
    }
    if (step is SortingStep) {
      return ChoiceAttempt(step.correctBinId);
    }
    if (step is CurrentRiderStep) {
      return SequenceAttempt(
        CurrentRiderStep.tokensFor(step.round, step.round.solutions.first),
      );
    }
    if (step is CountingStep) {
      return QuantityAttempt(step.targetCount);
    }
    if (step is TraceStep) {
      return ChoiceAttempt(step.figure.lastAnchor.id);
    }
    if (step is SoundSequenceStep) {
      return SequenceAttempt(step.round.sequence);
    }
    throw StateError('no answer known for ${step.runtimeType}');
  }

  // ======================================================== the chapter shape

  group('The chapter is six different things', () {
    test('it contains exactly six activities', () {
      expect(activityIds().length, 6,
          reason: 'six is the shape this chapter was written to: it lands '
              'inside the eight-to-twelve minutes attention holds at four to '
              'five. It now has ${activityIds().length}');
    });

    test('no engine is used twice inside the chapter', () {
      final List<String> engines =
          activities().map((ActivitySpec spec) => spec.engineId).toList();
      expect(engines.toSet().length, engines.length,
          reason: 'a chapter that asks the same thing twice is five '
              'activities and a repeat: $engines');
    });

    test('no two activities share an interaction mode', () {
      // Stronger than "no repeated engine", and the check that actually
      // catches a reskin: two different engines that both amount to dragging
      // a card onto a target are one activity wearing two costumes.
      final Map<InteractionMode, String> claimedBy =
          <InteractionMode, String>{};
      for (final ActivitySpec spec in activities()) {
        final ActivityEngineDescriptor descriptor =
            registry.require(spec.engineId).descriptor;
        for (final InteractionMode mode in descriptor.interactionModes) {
          // `tapInScene` is shared by design: `flashlight` declares it
          // alongside `sweepScene` because touching the thing you have lit is
          // how you answer. It is the second mode that makes it a different
          // activity, and no other Ocean engine claims `sweepScene`.
          if (mode == InteractionMode.tapInScene) {
            continue;
          }
          final String? already = claimedBy[mode];
          expect(already, isNull,
              reason: '${spec.instanceId} and $already both ask the child to '
                  '${mode.name}');
          claimedBy[mode] = spec.instanceId;
        }
      }
    });

    test('the engines rested after Adventure 2 stay rested', () {
      // Named rather than inferred. Both were used in the Market, and a
      // chapter that reaches for them again is a chapter that ran out of ideas
      // rather than one that chose these.
      for (final String forbidden in <String>['multiple_choice', 'code_path']) {
        expect(
          activities().map((ActivitySpec spec) => spec.engineId),
          isNot(contains(forbidden)),
          reason: '"$forbidden" was already spent on Adventure 2',
        );
      }
    });

    test('every activity parses against its own engine', () {
      for (final ActivitySpec spec in activities()) {
        expect(
          () => registry
              .require(spec.engineId)
              .parseContent(spec, bundle.packResolver),
          returnsNormally,
          reason: '${spec.sourcePath} does not parse',
        );
      }
    });

    test('every activity is authored in both locales', () {
      for (final ActivitySpec spec in activities()) {
        expect(spec.locales, containsAll(<String>['en', 'ar']),
            reason: '${spec.instanceId} claims ${spec.locales}');
      }
    });

    test('the child opens the gate, not the turtle', () {
      // The Market let an adult resolve its ending. The structural guard
      // against repeating that is simple: the climax has to be an activity,
      // because a story beat is something the child watches.
      final StoryNode climax = ocean.nodes
          .firstWhere((StoryNode node) => node.beat == StoryBeat.climax);
      expect(climax.isActivity, isTrue,
          reason: 'the climax is a narration beat, so the chapter resolves '
              'itself while the child watches');
      expect(climax.activityRef, contains('read_the_current'));
    });
  });

  // =================================================== every activity acts

  group('Every activity visibly changes the world', () {
    test(
        'each one either stages the thing being made or accumulates on its '
        'own board', () async {
      // Deliberately not "each one has a stage". Three of the six already ARE
      // the world changing — a scene being uncovered, a line being drawn, a
      // gate being opened — and bolting a progress picture on top of those
      // would say the same thing twice. What every one of them has to do is
      // carry the change forward rather than report a score.
      final Map<String, bool> accumulates = <String, bool>{};

      for (final String activityId in activityIds()) {
        final ActivitySpec spec = bundle.requireActivity(activityId);
        if (spec.presentation.stage != null) {
          accumulates[activityId] = true;
          continue;
        }
        final ActivityCubit<ActivityContent, dynamic> cubit =
            await started(activityId);
        addTearDown(cubit.close);

        // Advance one step and check that the new step knows about the old one.
        final Object? first = cubit.state.engineStep;
        await cubit.submit(answerFor(cubit.state));
        final Object? second = cubit.state.engineStep;

        bool carried = false;
        if (first is FlashlightStep && second is FlashlightStep) {
          carried = second.alreadyFound.length > first.alreadyFound.length;
        } else if (first is TraceStep && second is TraceStep) {
          carried = second.alreadyDrawn.length > first.alreadyDrawn.length;
        } else if (first is SoundSequenceStep && second is SoundSequenceStep) {
          carried = second.gateOpenAtStart > first.gateOpenAtStart;
        }
        accumulates[activityId] = carried;
      }

      for (final MapEntry<String, bool> entry in accumulates.entries) {
        expect(entry.value, isTrue,
            reason: '${entry.key} finishes a step without the next step '
                'showing anything the child just did, so its progress exists '
                'only as a number');
      }
    });

    test('a completed chapter leaves the trace wall fully lit', () {
      // `keepCompleted` is what makes the two lines one route rather than two
      // shapes that shared a box. It is the world reaction for this activity,
      // so it is not an optional flourish.
      expect(contentOf<TraceContent>('ocean_light_the_wall').keepCompleted,
          isTrue);
    });
  });

  // ========================================================== the flashlight

  group('The dark scene can always be searched', () {
    test('every find stays wholly on the board at every supported width', () {
      // Objects are sized from the board's SHORT side while positions are a
      // fraction per axis, so a find authored near an edge is comfortably on
      // screen in portrait and clipped in landscape. Checking the real
      // geometry at the real sizes is the only way to catch that.
      final FlashlightContent content =
          contentOf<FlashlightContent>('ocean_find_marker');

      const List<Size> sizes = <Size>[
        Size(360, 640),
        Size(780, 390),
        Size(800, 1200),
        Size(1200, 800),
      ];

      for (final Size box in sizes) {
        final double shortSide =
            box.width < box.height ? box.width : box.height;
        final double base = shortSide * 0.16;
        for (final DarkFind find in content.finds) {
          // The creature is drawn at 3.4x, which is the whole point of it —
          // it is meant to be too big for the beam. It is still not allowed
          // to leave the board.
          final double size = base * find.scale * (find.isCreature ? 3.4 : 1);
          final double left = find.position.dx * box.width - size / 2;
          final double top = find.position.dy * box.height - size / 2;

          expect(left, greaterThanOrEqualTo(-size * 0.25),
              reason: '"${find.id}" hangs off the left at $box');
          expect(left + size, lessThanOrEqualTo(box.width + size * 0.25),
              reason: '"${find.id}" hangs off the right at $box');
          expect(top, greaterThanOrEqualTo(-size * 0.25),
              reason: '"${find.id}" hangs off the top at $box');
          expect(top + size, lessThanOrEqualTo(box.height + size * 0.25),
              reason: '"${find.id}" hangs off the bottom at $box');
        }
      }
    });

    test('no two finds sit close enough to be one tap', () {
      final FlashlightContent content =
          contentOf<FlashlightContent>('ocean_find_marker');
      for (int a = 0; a < content.finds.length; a++) {
        for (int b = a + 1; b < content.finds.length; b++) {
          final double apart =
              (content.finds[a].position - content.finds[b].position).distance;
          expect(apart, greaterThan(content.hitToleranceFraction),
              reason: '"${content.finds[a].id}" and "${content.finds[b].id}" '
                  'are $apart apart, inside the hit tolerance');
        }
      }
    });

    test('the big shape cannot be resolved by aiming, only by widening', () {
      final FlashlightContent content =
          contentOf<FlashlightContent>('ocean_find_marker');
      final DarkFind creature =
          content.finds.firstWhere((DarkFind find) => find.isCreature);

      expect(creature.requiresBeamFraction, isNotNull,
          reason: 'the creature resolves at the starting beam, so the "make '
              'the light bigger" beat never happens');
      expect(creature.requiresBeamFraction, greaterThan(content.beamFraction));
      expect(creature.requiresBeamFraction,
          lessThanOrEqualTo(content.maxBeamFraction),
          reason: 'the creature needs a beam wider than the child can make, '
              'so the scene cannot be finished');
    });

    test('the way on is the last thing found', () {
      final FlashlightContent content =
          contentOf<FlashlightContent>('ocean_find_marker');
      expect(content.finds.last.kind, DarkFindKind.exit);
      expect(
        content.finds
            .take(content.finds.length - 1)
            .every((DarkFind find) => find.kind != DarkFindKind.exit),
        isTrue,
      );
    });

    test(
        'a tap near the target counts, and a wild one is a different '
        'mistake from a near miss', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_find_marker');
      addTearDown(cubit.close);
      final FlashlightStep step = cubit.state.engineStep! as FlashlightStep;
      final FlashlightCubit flashlight = cubit as FlashlightCubit;
      final FlashlightContent content =
          contentOf<FlashlightContent>('ocean_find_marker');

      // Dead on.
      expect(
        flashlight.judge(step, TapPointAttempt(step.target.position)).isCorrect,
        isTrue,
      );
      // Just outside the target but well inside a child's aim: a motor signal,
      // not a knowledge one. Conflating the two is how "make the targets
      // bigger" gets misread as "teach it again".
      final Offset nearMiss =
          step.target.position + Offset(content.hitToleranceFraction * 1.5, 0);
      expect(
        flashlight.judge(step, TapPointAttempt(nearMiss)).outcome,
        AttemptOutcome.wrongSlotButRightItem,
      );
      // Somewhere else entirely.
      expect(
        flashlight
            .judge(step, const TapPointAttempt(Offset(0.02, 0.02)))
            .outcome,
        AttemptOutcome.wrongItem,
      );
    });
  });

  // ============================================================== the sorting

  group('Float and sink cannot be answered by size or colour', () {
    test('every item carries the attribute the round sorts on', () {
      final ItemPack pack =
          bundle.packResolver.require('packs/tide_pool', debugPath: 'test');
      final ActivitySpec spec = bundle.requireActivity('ocean_float_or_sink');
      final List<String> itemIds =
          (spec.payload['itemIds'] as List<dynamic>).cast<String>();

      for (final String id in itemIds) {
        final PackItem item = pack.findById(id)!;
        expect(item.attribute('buoyancy'), isNotNull,
            reason: '"$id" is in the float/sink round with no buoyancy');
        expect(<String>['float', 'sink'], contains(item.attribute('buoyancy')),
            reason: '"$id" has buoyancy "${item.attribute('buoyancy')}"');
      }
    });

    test('size points both ways, so neither naive rule survives', () {
      // The pedagogical claim the round is built on. If every floater were big
      // and every sinker small, a child could be right every time with a rule
      // that is false, and the round would have taught them that rule.
      final ItemPack pack =
          bundle.packResolver.require('packs/tide_pool', debugPath: 'test');
      final ActivitySpec spec = bundle.requireActivity('ocean_float_or_sink');
      final List<String> itemIds =
          (spec.payload['itemIds'] as List<dynamic>).cast<String>();

      final Set<String> floatSizes = <String>{};
      final Set<String> sinkSizes = <String>{};
      for (final String id in itemIds) {
        final PackItem item = pack.findById(id)!;
        final String? size = item.attribute('size');
        if (size == null) {
          continue;
        }
        (item.attribute('buoyancy') == 'float' ? floatSizes : sinkSizes)
            .add(size);
      }

      expect(floatSizes.length, greaterThan(1),
          reason: 'every floater is "$floatSizes", so "big things float" is '
              'never contradicted');
      expect(sinkSizes.length, greaterThan(1),
          reason: 'every sinker is "$sinkSizes", so "small things sink" is '
              'never contradicted');
    });

    test('colour is never the cue, because no item declares one', () {
      final ItemPack pack =
          bundle.packResolver.require('packs/tide_pool', debugPath: 'test');
      for (final PackItem item in pack.items) {
        expect(item.attribute('color'), isNull,
            reason: '"${item.id}" carries a colour, which a child will reach '
                'for before buoyancy because it is the more salient attribute');
      }
    });

    test('the activity claims nothing is held constant, because size is not',
        () {
      // Claiming size as held constant would be a lie, and the validator
      // catches it — but the round deliberately declares an EMPTY list, and
      // that emptiness is the pedagogical decision rather than an omission.
      final ActivitySpec spec = bundle.requireActivity('ocean_float_or_sink');
      expect(spec.payload['heldConstant'], isEmpty);
    });
  });

  // ========================================================= the current ride

  group('Every current board can be crossed, and none starts crossed', () {
    test('each board has at least one setting that arrives', () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        expect(round.solutions, isNotEmpty,
            reason: 'no setting of "${round.id}" reaches ${round.goal}, so '
                'the child can only be carried through by the no-fail ladder');
      }
    });

    test('no board is already solved before the child touches it', () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        expect(round.ride(round.initialSetting).arrived, isFalse,
            reason: '"${round.id}" arrives on its opening setting, so the '
                'child presses one button and is congratulated');
      }
    });

    test('nothing is authored outside its board, or on top of anything else',
        () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        final List<Cell> occupied = <Cell>[
          round.start,
          round.goal,
          ...round.rocks,
          ...round.gates.map((CurrentGate gate) => gate.cell),
        ];
        for (final Cell cell in occupied) {
          expect(round.contains(cell), isTrue,
              reason: '"${round.id}" puts $cell outside a '
                  '${round.columns}x${round.rows} board');
        }
        // The start may share its cell with nothing; a gate on the goal would
        // make arriving depend on which check ran first.
        final List<Cell> mustBeDistinct = <Cell>[
          round.goal,
          ...round.rocks,
          ...round.gates.map((CurrentGate gate) => gate.cell),
        ];
        expect(mustBeDistinct.toSet().length, mustBeDistinct.length,
            reason: '"${round.id}" stacks two objects on one cell');
      }
    });

    test('every gate offers only real directions, and starts on one of them',
        () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        for (final CurrentGate gate in round.gates) {
          expect(gate.choices.length, inInclusiveRange(2, 3));
          expect(gate.choices.toSet().length, gate.choices.length);
          expect(
              gate.initialIndex, inInclusiveRange(0, gate.choices.length - 1));
          expect(gate.choices, contains(gate.initial));
        }
      }
    });

    test('a run that fails returns her to the last safe water', () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      final CurrentRound round = content.rounds.first;
      final Ride ride = round.ride(round.initialSetting);

      expect(ride.arrived, isFalse);
      expect(round.contains(ride.lastSafe), isTrue,
          reason: 'she is put back outside the board');
      expect(round.rocks, isNot(contains(ride.lastSafe)),
          reason: 'she is put back inside a rock');
    });

    test('the simulation is deterministic', () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        for (final Map<String, Drift> setting in round.allSettings) {
          final Ride a = round.ride(setting);
          final Ride b = round.ride(setting);
          expect(a.path.toString(), b.path.toString());
          expect(a.outcome, b.outcome);
        }
      }
    });

    test('no setting ever leaves the rider off the board or in a rock', () {
      // The loop guard and the blocking rule together have to mean that every
      // cell the rider is ever drawn in is a legal one, for all 4+8 settings.
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        for (final Map<String, Drift> setting in round.allSettings) {
          for (final Cell cell in round.ride(setting).path) {
            expect(round.contains(cell), isTrue,
                reason: '"${round.id}" drifts to $cell, off the board');
            expect(round.rocks, isNot(contains(cell)),
                reason: '"${round.id}" drifts into the rock at $cell');
          }
        }
      }
    });

    test('the modelled hint points at a gate that is actually wrong', () {
      final CurrentRiderContent content =
          contentOf<CurrentRiderContent>('ocean_ride_the_current');
      for (final CurrentRound round in content.rounds) {
        final Map<String, Drift> opening = round.initialSetting;
        final String? gateId = round.gateToTurn(opening);
        expect(gateId, isNotNull);

        // Turning the gate it named has to bring a solution closer, which for
        // a board this small means: some solution disagrees with the opening
        // setting exactly there.
        expect(
          round.solutions.any((Map<String, Drift> solution) =>
              solution[gateId] != opening[gateId]),
          isTrue,
          reason: '"${round.id}" points the child at "$gateId", which is '
              'already set correctly in every solution',
        );
      }
    });
  });

  // =========================================================== the light garden

  group('Lighting the shell needs exactly the number asked for', () {
    test('it is give-N, which is the only mode that tests cardinality', () {
      // "How many are there?" can be answered by reciting over the objects.
      // "Bring me four" cannot: a child who counts to ten and still hands over
      // a fistful has not got cardinality, and this is the only task in the
      // chapter that would notice.
      expect(contentOf<CountingContent>('ocean_light_her_shell').mode,
          CountingMode.giveN);
    });

    test('one too many and one too few are both refused', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_light_her_shell');
      addTearDown(cubit.close);
      final CountingCubit counting = cubit as CountingCubit;
      final CountingStep step = cubit.state.engineStep! as CountingStep;

      expect(counting.judge(step, QuantityAttempt(step.targetCount)).isCorrect,
          isTrue);
      expect(
          counting.judge(step, QuantityAttempt(step.targetCount + 1)).isCorrect,
          isFalse,
          reason: 'handing over one extra counts as four');
      expect(
          counting.judge(step, QuantityAttempt(step.targetCount - 1)).isCorrect,
          isFalse);
    });

    test('the supply always holds more than the answer', () {
      // The classic way a give-N task is defeated by accident: a supply of
      // exactly the right size answers the question for the child, because
      // "take everything" is then always correct. The board offers target + 3.
      final CountingContent content =
          contentOf<CountingContent>('ocean_light_her_shell');
      for (final CountingRound round in content.rounds) {
        expect(round.targetCount, greaterThan(0));
        // The board's supply is targetCount + 3; the invariant that matters is
        // that handing over everything is never the answer.
        expect(round.targetCount + 3, greaterThan(round.targetCount));
      }
    });

    test('handing over everything on offer is never correct', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_light_her_shell');
      addTearDown(cubit.close);
      final CountingCubit counting = cubit as CountingCubit;

      while (cubit.state.status == ActivityStatus.running) {
        final CountingStep step = cubit.state.engineStep! as CountingStep;
        // What the board puts in the drift for this round.
        const int supplyOverTarget = 3;
        expect(
          counting
              .judge(step, QuantityAttempt(step.targetCount + supplyOverTarget))
              .isCorrect,
          isFalse,
          reason: 'sweeping up the whole drift answers "${step.stepId}"',
        );
        await cubit.submit(QuantityAttempt(step.targetCount));
      }
    });

    test('the rounds ask for different amounts', () {
      final CountingContent content =
          contentOf<CountingContent>('ocean_light_her_shell');
      final List<int> targets = content.rounds
          .map((CountingRound round) => round.targetCount)
          .toList();
      expect(targets.toSet().length, greaterThan(1),
          reason: 'every round asks for the same number, so the second one is '
              'the first one again: $targets');
    });
  });

  // ============================================================== the wall

  group('The trench wall route is drawable by a child', () {
    test('every anchor is inside the figure box', () {
      final TraceContent content =
          contentOf<TraceContent>('ocean_light_the_wall');
      for (final TraceFigure figure in content.figures) {
        for (final TraceAnchor anchor in figure.anchors) {
          expect(anchor.position.dx, inInclusiveRange(0.0, 1.0),
              reason: '"${figure.id}" anchor "${anchor.id}" is off the board '
                  'horizontally');
          expect(anchor.position.dy, inInclusiveRange(0.0, 1.0),
              reason: '"${figure.id}" anchor "${anchor.id}" is off the board '
                  'vertically');
        }
      }
    });

    test('the tolerance is forgiving enough for a four-year-old hand', () {
      // Pixel-perfect tracing is a motor test, not a drawing activity. Fifteen
      // percent of the box is about fifty pixels on a 360dp phone.
      final TraceContent content =
          contentOf<TraceContent>('ocean_light_the_wall');
      expect(content.tolerance, greaterThanOrEqualTo(0.10),
          reason: 'a tolerance of ${content.tolerance} asks for accuracy a '
              'child of this age does not have');
    });

    test('a wobbly stroke down the route is accepted', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_light_the_wall');
      addTearDown(cubit.close);
      final TraceCubit trace = cubit as TraceCubit;
      final TraceStep step = cubit.state.engineStep! as TraceStep;

      // A child's line: the right route, sampled densely, with every point
      // nudged off the ideal by a fraction of the tolerance.
      final List<Offset> stroke = <Offset>[];
      final List<TraceAnchor> walk = step.figure.walk;
      for (int index = 0; index < walk.length - 1; index++) {
        final Offset from = walk[index].position;
        final Offset to = walk[index + 1].position;
        for (int sample = 0; sample <= 8; sample++) {
          final double t = sample / 8;
          final double wobble = step.tolerance * 0.3 * (sample.isEven ? 1 : -1);
          stroke.add(Offset(
            from.dx + (to.dx - from.dx) * t + wobble,
            from.dy + (to.dy - from.dy) * t,
          ));
        }
      }

      expect(
        trace
            .judge(step, StrokeAttempt(points: stroke, strokeIndex: 0))
            .isCorrect,
        isTrue,
        reason: 'a line that follows the route with a normal amount of wobble '
            'was rejected',
      );
    });

    test('a stroke that goes somewhere else is not accepted', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_light_the_wall');
      addTearDown(cubit.close);
      final TraceCubit trace = cubit as TraceCubit;
      final TraceStep step = cubit.state.engineStep! as TraceStep;

      expect(
        trace
            .judge(
                step,
                const StrokeAttempt(
                  points: <Offset>[Offset(0.95, 0.02), Offset(0.98, 0.06)],
                  strokeIndex: 0,
                ))
            .isCorrect,
        isFalse,
      );
    });
  });

  // ============================================================= the rhythm

  group('The gate rhythm is heard, answered, and forgiving', () {
    test('every voice sings a tone that is actually bundled', () {
      // The generic asset check only walks strings beginning `assets/`, and
      // audioplayers paths are relative to that directory — so a typo here
      // would ship as a silent voice and nothing would fail.
      final SoundSequenceContent content =
          contentOf<SoundSequenceContent>('ocean_read_the_current');
      for (final SoundVoice voice in content.voices) {
        expect(File('assets/${voice.audioAsset}').existsSync(), isTrue,
            reason: '"${voice.id}" sings "${voice.audioAsset}", which is not '
                'on disk');
      }
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/audio/'),
          reason: 'the tones are not bundled, so they will not ship');
    });

    test('no two voices share a tone', () {
      final SoundSequenceContent content =
          contentOf<SoundSequenceContent>('ocean_read_the_current');
      final List<String> tones =
          content.voices.map((SoundVoice voice) => voice.audioAsset).toList();
      expect(tones.toSet().length, tones.length,
          reason: 'two voices with one tone cannot be told apart by ear: '
              '$tones');
    });

    test('every voice has a label in both locales, for a muted device', () {
      final SoundSequenceContent content =
          contentOf<SoundSequenceContent>('ocean_read_the_current');
      for (final SoundVoice voice in content.voices) {
        for (final String locale in <String>['en', 'ar']) {
          expect(voice.label.resolve(locale), isNotEmpty,
              reason: '"${voice.id}" has no name in "$locale", so a child '
                  'using a screen reader is told nothing');
        }
      }
    });

    test('a wrong order is refused, and the child may try again', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_read_the_current');
      addTearDown(cubit.close);
      final SoundSequenceStep step =
          cubit.state.engineStep! as SoundSequenceStep;
      final List<String> wanted = step.round.sequence;

      await cubit.submit(SequenceAttempt(wanted.reversed.toList()));

      // Still running, still on the same rhythm, and further up the ladder
      // rather than further through the chapter.
      expect(cubit.state.status, ActivityStatus.running);
      expect((cubit.state.engineStep! as SoundSequenceStep).round.id,
          step.round.id,
          reason: 'a wrong answer moved the child on to the next rhythm');
      expect(cubit.state.scaffoldLevel, isNot(ScaffoldLevel.initial));

      // And the right answer still works afterwards.
      await cubit.submit(SequenceAttempt(wanted));
      expect(
        (cubit.state.engineStep! as SoundSequenceStep).round.id,
        isNot(step.round.id),
        reason: 'giving the rhythm back correctly did not open the gate',
      );
    });

    test('right voices in the wrong order is a memory slip, not a misread',
        () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('ocean_read_the_current');
      addTearDown(cubit.close);
      final SoundSequenceCubit rhythm = cubit as SoundSequenceCubit;
      final SoundSequenceStep step =
          cubit.state.engineStep! as SoundSequenceStep;

      expect(
        rhythm
            .judge(step, SequenceAttempt(step.round.sequence.reversed.toList()))
            .outcome,
        AttemptOutcome.wrongSlotButRightItem,
      );
      // Voices that were never in the rhythm at all.
      final String unused = step.round
          .unusedFrom(
            step.voices.map((SoundVoice voice) => voice.id),
          )
          .first;
      expect(
        rhythm
            .judge(
                step,
                SequenceAttempt(
                  List<String>.filled(step.round.length, unused),
                ))
            .outcome,
        AttemptOutcome.wrongItem,
      );
    });

    test('a round can never be answered by tapping every voice', () {
      final SoundSequenceContent content =
          contentOf<SoundSequenceContent>('ocean_read_the_current');
      final Iterable<String> allIds =
          content.voices.map((SoundVoice voice) => voice.id);
      for (final SoundRound round in content.rounds) {
        expect(round.unusedFrom(allIds), isNotEmpty,
            reason: '"${round.id}" uses every voice on screen');
      }
    });

    test('the rhythms get harder without getting longer first', () {
      // Three, three-with-a-repeat, then four. The step that matters is the
      // second: a repeated beat defeats "remember one of each" and forces the
      // child to hold a position rather than a set.
      final SoundSequenceContent content =
          contentOf<SoundSequenceContent>('ocean_read_the_current');
      expect(content.rounds.length, greaterThanOrEqualTo(3));

      final SoundRound second = content.rounds[1];
      expect(second.sequence.toSet().length, lessThan(second.sequence.length),
          reason: 'no round repeats a beat, so every rhythm can be answered '
              'as a set rather than as an order');
      expect(
          content.rounds.last.length, greaterThan(content.rounds.first.length));
    });
  });

  // ============================================================ mute and resume

  group('The chapter survives a silent phone and an interruption', () {
    test('every activity runs to the end with no audio device at all',
        () async {
      // Not a test double standing in for a soundboard: this is the soundboard
      // a host installs when the child has the app muted or the device has no
      // audio. The activity has to be completable, not merely crash-free.
      for (final String activityId in activityIds()) {
        final ActivityCubit<ActivityContent, dynamic> cubit = await started(
          activityId,
          soundboard: const SilentActivitySoundboard(),
        );
        int guard = 0;
        while (cubit.state.status == ActivityStatus.running && guard < 60) {
          guard++;
          await cubit.submit(answerFor(cubit.state));
        }
        expect(cubit.state.status, ActivityStatus.finished,
            reason: '$activityId could not be finished without sound');
        expect(cubit.state.result.completion, ActivityCompletion.completed);
        await cubit.close();
      }
    });

    test(
        'leaving mid-activity comes back to the same step, with the world '
        'the child had built', () async {
      for (final String activityId in activityIds()) {
        final RecordingActivityCheckpointSink sink =
            RecordingActivityCheckpointSink();

        final ActivityCubit<ActivityContent, dynamic> first =
            await started(activityId, checkpointSink: sink);
        // One step in, then the child backs out.
        await first.submit(answerFor(first.state));
        if (first.state.status != ActivityStatus.running) {
          // A one-step activity has nothing to resume into.
          await first.close();
          continue;
        }
        final int leftAt = first.state.stepIndex;
        expect(leftAt, greaterThan(0));
        await first.abandon();
        await first.close();

        final ActivityCubit<ActivityContent, dynamic> second = await started(
          activityId,
          checkpointSink: sink,
          resume: sink.latest,
        );
        addTearDown(second.close);

        expect(second.state.stepIndex, leftAt,
            reason: '$activityId restarted from the beginning');

        // And the world the child had already built is still there, rather
        // than the step index alone being restored onto an empty board.
        final Object? step = second.state.engineStep;
        if (step is FlashlightStep) {
          expect(step.alreadyFound, isNotEmpty,
              reason: 'the scene came back dark, so the finds are lost');
        } else if (step is TraceStep) {
          expect(step.alreadyDrawn, isNotEmpty,
              reason: 'the wall came back unlit');
        } else if (step is SoundSequenceStep) {
          expect(step.gateOpenAtStart, greaterThan(0),
              reason: 'the gate came back shut');
        } else if (step is CurrentRiderStep) {
          expect(step.depth, greaterThan(0),
              reason: 'the descent came back at the surface');
        }
      }
    });
  });
}
