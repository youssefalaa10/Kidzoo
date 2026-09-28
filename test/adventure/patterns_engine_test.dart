import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_cubit.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

import 'support/disk_content_source.dart';

/// `patterns`, the engine Adventure 3 added and then stopped shipping.

/// Adventure 3's climax moved to `sound_sequence` — a rhythm you hold in your
/// head rather than a strip you read off the board — so no activity file uses
/// `patterns` today. The engine stays registered and stays tested, and its
/// fixture moved from the Ocean file on disk to [patternsFixture] below. That
/// is the whole of the change: an engine with no current content is still an
/// engine, and deleting a tested, reusable mechanic because this chapter went
/// another way would be paying for it twice.
///
/// It claims `patterning | dragToTarget`, a domain the contract has declared
/// since Phase 1 with nothing behind it. What is worth checking here is the one
/// thing that makes it not `sorting`: the same tile is right in one position
/// and wrong in the next, and the content has to be arranged so that a child
/// who has not read the rule cannot get there another way. Most of this file is
/// about *those other ways* — elimination, momentum, copying a fixed distance
/// back — because each is a route to a right answer that teaches nothing.
///
/// The guarantees every engine makes (a child always finishes; generation is
/// reproducible under a seed) are covered for all of them in `engines_test.dart`.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
  });

  /// The board this file exercises, held here rather than read from disk.
  ///
  /// It is the reef ledge Adventure 3 used to end on, kept verbatim because it
  /// is a good hard case: three rounds whose unit grows AB, AAB, ABC, gaps
  /// that never fall on the same position twice, and a spare tile in the tray
  /// so the last hole of a round cannot be filled by elimination.
  ActivitySpec patternsFixture() => ActivitySpec.fromJson(
        const <String, dynamic>{
          'instanceId': 'ocean.read_the_current.patterns_fixture',
          'engineId': 'patterns',
          'locales': <String>['en', 'ar'],
          'presentation': <String, dynamic>{'accent': '#4A9FD8'},
          'narration': <String, dynamic>{
            'prompt': <String, String>{'en': 'put back what the storm tore out', 'ar': 'x'},
            'success': <String, String>{'en': 'the gate is open', 'ar': 'x'},
          },
          'payload': <String, dynamic>{
            'itemsRef': 'packs/tide_pool',
            'itemIds': <String>[
              'coral',
              'spiral_shell',
              'tropical_fish',
              'kelp',
              'crab',
            ],
            'revealedRepeats': 2,
            'trayExtraCount': 1,
            'mode': 'extend',
            'rounds': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'the_swell',
                'unit': <String>['coral', 'spiral_shell'],
                'repeats': 4,
                'gaps': <int>[6, 7],
                'mode': 'extend',
                'prompt': <String, String>{
                  'en': 'Coral, shell, coral, shell. Say it to the end.',
                  'ar': 'x',
                },
                'revealLine': <String, String>{
                  'en': 'The water moved.',
                  'ar': 'x',
                },
              },
              <String, dynamic>{
                'id': 'the_backwash',
                'unit': <String>['coral', 'coral', 'spiral_shell'],
                'repeats': 3,
                'gaps': <int>[6, 7],
                'mode': 'fillGap',
                'prompt': <String, String>{
                  'en': 'This one goes two, then one.',
                  'ar': 'x',
                },
                'revealLine': <String, String>{
                  'en': 'Longer this time.',
                  'ar': 'x',
                },
              },
              <String, dynamic>{
                'id': 'the_gate_beat',
                'unit': <String>['coral', 'spiral_shell', 'tropical_fish'],
                'repeats': 3,
                'gaps': <int>[6, 8],
                'mode': 'extend',
                'prompt': <String, String>{
                  'en': 'Three things now, over and over.',
                  'ar': 'x',
                },
                'revealLine': <String, String>{
                  'en': 'The whole ledge ran.',
                  'ar': 'x',
                },
              },
            ],
          },
        },
        sourcePath: 'test fixture > patterns',
      );

  PatternsCubit cubitFor({
    int seed = 11,
    String languageCode = 'en',
    ActivityCheckpointSink? checkpointSink,
    ActivityCheckpoint? resume,
  }) {
    final ActivitySpec spec = patternsFixture();
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    return engine.createCubit(engine.createSession(
      spec: spec,
      services: ActivityServices.forTest(
        seed: seed,
        languageCode: languageCode,
        checkpointSink: checkpointSink,
      ),
      packs: bundle.packResolver,
      storyNodeId: 'ocean.n8',
      seed: seed,
      resume: resume,
    )) as PatternsCubit;
  }

  PatternsContent authored() =>
      registry.require('patterns').parseContent(
            patternsFixture(),
            bundle.packResolver,
          ) as PatternsContent;

  /// Parses a payload straight from a map, so a rejection can be provoked
  /// without a file on disk.
  PatternsContent parse(Map<String, dynamic> payload) =>
      registry.require('patterns').parseContent(
            ActivitySpec.fromJson(<String, dynamic>{
              'instanceId': 'test.pattern',
              'engineId': 'patterns',
              'locales': const <String>['en'],
              'payload': payload,
            }),
            bundle.packResolver,
          ) as PatternsContent;

  Map<String, dynamic> payloadWith({
    List<String> unit = const <String>['coral', 'spiral_shell'],
    int repeats = 4,
    List<int> gaps = const <int>[6, 7],
    String mode = 'extend',
    int revealedRepeats = 2,
    int trayExtraCount = 1,
  }) =>
      <String, dynamic>{
        'itemsRef': 'packs/tide_pool',
        'revealedRepeats': revealedRepeats,
        'trayExtraCount': trayExtraCount,
        'rounds': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'r',
            'unit': unit,
            'repeats': repeats,
            'gaps': gaps,
            'mode': mode,
            'prompt': 'go on',
          },
        ],
      };

  // ======================================================== the rule itself

  group('The rule is what is being judged', () {
    test('a tile is right in one position and wrong in the next', () async {
      // The whole reason this is not `sorting`. There, a judgement about an
      // item holds wherever it is dropped; here it is a judgement about a
      // *position*, and the same shell is correct at index six and wrong at
      // index seven.
      final PatternsContent content = authored();
      final PatternRound round = content.rounds.first;

      expect(round.itemIdAt(6), isNot(round.itemIdAt(7)));
      expect(round.itemIdAt(0), round.itemIdAt(round.unitItemIds.length));
    });

    test('the correct tile is decided by position modulo the unit', () {
      final PatternsContent content = parse(payloadWith(
        unit: <String>['coral', 'coral', 'spiral_shell'],
        repeats: 3,
        gaps: <int>[6, 7],
        mode: 'fillGap',
      ));
      final PatternRound round = content.rounds.single;

      expect(
        <int>[0, 1, 2, 3, 4, 5].map(round.itemIdAt),
        <String>[
          'coral',
          'coral',
          'spiral_shell',
          'coral',
          'coral',
          'spiral_shell',
        ],
      );
    });

    test('an open strip shows everything except the gaps', () {
      final PatternRound round = parse(payloadWith()).rounds.single;
      final List<String?> open = round.openStrip;

      expect(open.length, 8);
      expect(open[6], isNull);
      expect(open[7], isNull);
      expect(open.take(6).every((String? tile) => tile != null), isTrue);
    });
  });

  // ================================================== the ways round reading

  group('Content cannot let a child answer without reading the pattern', () {
    test('rejects a unit with only one distinct item', () {
      // AAAA is not a pattern; every position is the same answer, and a child
      // fills the hole by matching its neighbour.
      expect(
        () => parse(payloadWith(unit: <String>['coral', 'coral'])),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('rejects gaps that all fall on the same position in the unit', () {
      // Two holes three apart in an ABC pattern are one question asked twice:
      // copy the tile one repeat back, without ever working out the unit.
      expect(
        () => parse(payloadWith(
          unit: <String>['coral', 'spiral_shell', 'tropical_fish'],
          repeats: 4,
          gaps: <int>[6, 9],
          mode: 'fillGap',
        )),
        throwsA(predicate((Object? e) =>
            e is ActivityContentException &&
            e.toString().contains('same position'))),
      );
    });

    test('rejects a first gap that arrives before the promised repeats', () {
      // The scaffolding dial has to be true, not declared. Claiming two whole
      // repetitions and opening a hole inside the first one is not a harder
      // round; it is a round whose help silently is not there.
      expect(
        () => parse(payloadWith(gaps: <int>[3, 7], revealedRepeats: 2)),
        throwsA(predicate((Object? e) =>
            e is ActivityContentException &&
            e.toString().contains('repetitions'))),
      );
    });

    test('rejects a strip that is all gaps', () {
      expect(
        () => parse(payloadWith(
          repeats: 2,
          gaps: <int>[0, 1, 2, 3],
          revealedRepeats: 1,
        )),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('rejects a gap outside the strip', () {
      expect(
        () => parse(payloadWith(gaps: <int>[6, 99])),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('rejects the same gap listed twice', () {
      expect(
        () => parse(payloadWith(gaps: <int>[7, 7])),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('rejects a unit shown only once', () {
      expect(
        () => parse(payloadWith(repeats: 1, gaps: <int>[1], revealedRepeats: 1)),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('rejects an item the pack does not have', () {
      expect(
        () => parse(payloadWith(unit: <String>['coral', 'wildebeest'])),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('rejects an extend round that does not open the end of the strip', () {
      // "What comes next" has to actually be at the end, or the mode is a
      // label rather than a description. Gaps 4 and 5 sit at different
      // positions in the unit, so this reaches the rule it is named for
      // rather than tripping the one above it.
      expect(
        () => parse(payloadWith(gaps: <int>[4, 5], mode: 'extend')),
        throwsA(predicate((Object? e) =>
            e is ActivityContentException && e.toString().contains('END'))),
        reason: 'must fail on the end-of-strip rule, not an earlier one',
      );
    });

    test('rejects two rounds asking the identical question', () {
      expect(
        () => parse(<String, dynamic>{
          'itemsRef': 'packs/tide_pool',
          'rounds': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a',
              'unit': <String>['coral', 'spiral_shell'],
              'repeats': 4,
              'gaps': <int>[6, 7],
              'prompt': 'one',
            },
            <String, dynamic>{
              'id': 'b',
              'unit': <String>['coral', 'spiral_shell'],
              'repeats': 4,
              'gaps': <int>[7, 6],
              'prompt': 'two',
            },
          ],
        }),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('a round with no gap is rejected', () {
      expect(
        () => parse(payloadWith(gaps: <int>[])),
        throwsA(isA<ActivityContentException>()),
      );
    });
  });

  // ============================================================== the tray

  group('The tray', () {
    test('always holds the answer to every gap', () async {
      // An invariant, not a check. A tray that cannot answer the question is
      // not a harder activity, it is a stuck one.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();

      while (cubit.state.status == ActivityStatus.running) {
        final PatternStep step = cubit.state.engineStep! as PatternStep;
        expect(
          step.tray.map((PackItem item) => item.id),
          contains(step.correctItemId),
          reason: 'gap ${step.slotIndex} of ${step.round.id} cannot be filled',
        );
        await cubit.submit(ChoiceAttempt(step.correctItemId));
      }
      await cubit.close();
    });

    test('holds at least one tile that belongs in no gap', () async {
      // Without a spare, the last hole of a round is answerable by
      // elimination: one tile left, so it must go in. A child who does that
      // has practised counting the tray rather than reading the reef.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();

      final PatternStep step = cubit.state.engineStep! as PatternStep;
      final Set<String> needed = step.round.unitItemIds.toSet();
      expect(
        step.tray.where((PackItem item) => !needed.contains(item.id)),
        isNotEmpty,
      );
      await cubit.close();
    });

    test('does not change between the holes of one round', () async {
      // Reshuffling mid-round would move a target out from under a finger
      // already travelling toward it, and would imply the tray means
      // something, which it does not.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();

      final PatternStep first = cubit.state.engineStep! as PatternStep;
      await cubit.submit(ChoiceAttempt(first.correctItemId));
      final PatternStep second = cubit.state.engineStep! as PatternStep;

      if (second.round.id == first.round.id) {
        expect(
          second.tray.map((PackItem item) => item.id),
          first.tray.map((PackItem item) => item.id),
        );
      }
      await cubit.close();
    });
  });

  // ============================================================== judging

  group('Judging', () {
    test('the right tile in the wrong hole is aim, not a misread', () async {
      // Two different mistakes deserve two different answers: one is a finger,
      // the other is the rule.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();
      final PatternStep step = cubit.state.engineStep! as PatternStep;

      expect(
        cubit
            .judge(
              step,
              PlacementAttempt(
                tokenId: step.correctItemId,
                targetId: 'slot_999',
              ),
            )
            .outcome,
        AttemptOutcome.wrongSlotButRightItem,
      );
      await cubit.close();
    });

    test('drag and tap-then-tap are judged identically', () async {
      final PatternsCubit cubit = cubitFor();
      await cubit.start();
      final PatternStep step = cubit.state.engineStep! as PatternStep;

      final ActivityJudgement dragged = cubit.judge(
        step,
        PlacementAttempt(tokenId: step.correctItemId, targetId: step.slotId),
      );
      final ActivityJudgement tapped =
          cubit.judge(step, ChoiceAttempt(step.correctItemId));

      expect(dragged.isCorrect, isTrue);
      expect(tapped.isCorrect, dragged.isCorrect);
      await cubit.close();
    });

    test('a wrong tile is a wrong tile however close it lands', () async {
      final PatternsCubit cubit = cubitFor();
      await cubit.start();
      final PatternStep step = cubit.state.engineStep! as PatternStep;
      final String wrong = step.tray
          .map((PackItem item) => item.id)
          .firstWhere((String id) => id != step.correctItemId);

      expect(
        cubit.judge(step, ChoiceAttempt(wrong)).isCorrect,
        isFalse,
      );
      await cubit.close();
    });
  });

  // ============================================================ the strip

  group('The strip carries its own history', () {
    test('a filled gap stays filled for the next step', () async {
      // Carried on the step rather than accumulated in the board, so a child
      // who leaves mid-round comes back to the strip they left.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();

      final PatternStep first = cubit.state.engineStep! as PatternStep;
      expect(first.strip[first.slotIndex], isNull);
      await cubit.submit(ChoiceAttempt(first.correctItemId));

      final PatternStep second = cubit.state.engineStep! as PatternStep;
      if (second.round.id == first.round.id) {
        expect(second.strip[first.slotIndex], first.correctItemId);
      }
      await cubit.close();
    });

    test('the completed strip has no holes and obeys the rule', () async {
      final PatternsCubit cubit = cubitFor();
      await cubit.start();

      PatternStep? last;
      while (cubit.state.status == ActivityStatus.running) {
        final PatternStep step = cubit.state.engineStep! as PatternStep;
        if (step.isLastGapOfRound) {
          last = step;
        }
        await cubit.submit(ChoiceAttempt(step.correctItemId));
      }

      final List<String> finished = last!.completedStrip;
      expect(finished.length, last.round.length);
      for (int index = 0; index < finished.length; index++) {
        expect(finished[index], last.round.itemIdAt(index));
      }
      await cubit.close();
    });

    test('only the hole that finishes a round earns the reveal', () async {
      // The first hole of a two-hole round has not made anything happen yet,
      // and telling the child it has would be the app saying something they
      // can see is not true.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();

      while (cubit.state.status == ActivityStatus.running) {
        final PatternStep step = cubit.state.engineStep! as PatternStep;
        final ActivityStepView view = cubit.describe(step, ScaffoldLevel.initial);
        if (step.isLastGapOfRound) {
          expect(view.revealLine, isNotNull);
        } else {
          expect(view.revealLine, isNull);
        }
        await cubit.submit(ChoiceAttempt(step.correctItemId));
      }
      await cubit.close();
    });
  });

  // ======================================================= reuse and locale

  group('The engine names no subject', () {
    test('claims a capability key no other reusable engine claims', () {
      final ActivityEngineDescriptor patterns =
          registry.require('patterns').descriptor;

      for (final ActivityEngine<ActivityContent> other in registry.engines) {
        if (other.descriptor.engineId == 'patterns') {
          continue;
        }
        final bool sameKey = other.descriptor.learningDomains
                .difference(patterns.learningDomains)
                .isEmpty &&
            patterns.learningDomains
                .difference(other.descriptor.learningDomains)
                .isEmpty &&
            other.descriptor.interactionModes
                .difference(patterns.interactionModes)
                .isEmpty;
        expect(sameKey, isFalse,
            reason: '${other.descriptor.engineId} claims the same key');
      }
      expect(patterns.learningDomains, <LearningDomain>{
        LearningDomain.patterning,
      });
    });

    test('the same content runs in Arabic with no code path of its own',
        () async {
      // Nothing here holds words. A unit is a list of item ids, so the only
      // thing that changes between locales is the wording around it.
      final PatternsCubit english = cubitFor();
      final PatternsCubit arabic = cubitFor(languageCode: 'ar');
      await english.start();
      await arabic.start();

      final PatternStep en = english.state.engineStep! as PatternStep;
      final PatternStep ar = arabic.state.engineStep! as PatternStep;

      expect(ar.slotIndex, en.slotIndex);
      expect(ar.correctItemId, en.correctItemId);
      expect(ar.round.unitItemIds, en.round.unitItemIds,
          reason: 'the unit order must NOT mirror in RTL: a reversed pattern '
              'is a different pattern, and the answer would change');
      await english.close();
      await arabic.close();
    });
  });

  // =============================================================== resume

  group('Leaving mid-pattern', () {
    test('comes back to the same hole, on the same board', () async {
      // The cursor is two facts, not one: a step index AND the seed that
      // decided what that step is. The tray is shuffled, so an index restored
      // under a different seed would point into a board that was never built —
      // which is worse than starting over, because it looks like it worked.
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final PatternsCubit first = cubitFor(checkpointSink: sink);
      await first.start();

      final PatternStep opening = first.state.engineStep! as PatternStep;
      await first.submit(ChoiceAttempt(opening.correctItemId));
      final PatternStep left = first.state.engineStep! as PatternStep;
      await first.close();

      final PatternsCubit second =
          cubitFor(checkpointSink: sink, resume: sink.latest);
      await second.start();
      final PatternStep resumed = second.state.engineStep! as PatternStep;

      expect(resumed.stepId, left.stepId);
      expect(resumed.slotIndex, left.slotIndex);
      expect(resumed.correctItemId, left.correctItemId);
      expect(
        resumed.tray.map((PackItem item) => item.id),
        left.tray.map((PackItem item) => item.id),
        reason: 'the same seed has to rebuild the same tray, in the same order',
      );
      await second.close();
    });

    test('the hole already filled is still filled on return', () async {
      final RecordingActivityCheckpointSink sink =
          RecordingActivityCheckpointSink();
      final PatternsCubit first = cubitFor(checkpointSink: sink);
      await first.start();

      final PatternStep opening = first.state.engineStep! as PatternStep;
      await first.submit(ChoiceAttempt(opening.correctItemId));
      await first.close();

      final PatternsCubit second =
          cubitFor(checkpointSink: sink, resume: sink.latest);
      await second.start();
      final PatternStep resumed = second.state.engineStep! as PatternStep;

      if (resumed.round.id == opening.round.id) {
        expect(resumed.strip[opening.slotIndex], opening.correctItemId,
            reason: 'a child who filled a hole should not find it empty again');
      }
      await second.close();
    });
  });

  // ================================================================ board

  group('The board', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      final PatternsCubit cubit = cubitFor();
      await cubit.start();
      addTearDown(cubit.close);

      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ActivityBoardBuilder board =
          registry.require('patterns').createBoard();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) =>
                board(context, cubit.state, (ActivityAttempt _) {}),
          ),
        ),
      ));
      await tester.pump();
    }

    for (final Size size in <Size>[
      const Size(360, 640),
      const Size(780, 390),
      const Size(800, 1200),
      const Size(1200, 800),
    ]) {
      testWidgets('lays out without overflow at ${size.width}x${size.height}',
          (WidgetTester tester) async {
        await pumpAt(tester, size);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('offers a tappable tile for every tray entry',
        (WidgetTester tester) async {
      // Tap-then-tap is not a fallback: drag fails often at this age, and
      // WCAG 2.2 SC 2.5.7 requires a single-pointer alternative to every drag.
      final PatternsCubit cubit = cubitFor();
      await cubit.start();
      addTearDown(cubit.close);
      final PatternStep step = cubit.state.engineStep! as PatternStep;

      tester.view
        ..physicalSize = const Size(800, 1200)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ActivityBoardBuilder board =
          registry.require('patterns').createBoard();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) =>
                board(context, cubit.state, (ActivityAttempt _) {}),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(GestureDetector), findsWidgets);
      expect(step.tray, isNotEmpty);
    });
  });
}
