import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

import 'support/disk_content_source.dart';

/// Adventure 4, as a mystery rather than as five files.
///
/// The per-layer suites prove the shared machinery. What is checked here is
/// what only this chapter can be responsible for: that each of the three new
/// engines holds the rule it claims to teach, that the parsers refuse the
/// content that would let a child answer without using that rule, and that
/// the clues really do run from one activity into the next.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;
  late Adventure stars;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
    stars = bundle.requireAdventure('stars');
  });

  List<String> activityIds() => <String>[
        for (final StoryNode node in stars.nodes)
          if (node.isActivity) node.activityRef!.split('/').last,
      ];

  T contentOf<T extends ActivityContent>(String activityId) {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    return registry.require(spec.engineId).parseContent(
          spec,
          bundle.packResolver,
        ) as T;
  }

  /// The activity file as raw JSON, so a test can break one rule in it and
  /// check the parser names that rule.
  Map<String, dynamic> rawActivity(String activityId) =>
      jsonDecode(File('assets/adventures/activities/$activityId.json')
          .readAsStringSync()) as Map<String, dynamic>;

  void expectRejected(
    String activityId,
    void Function(Map<String, dynamic> payload) breakIt,
    String because,
  ) {
    final Map<String, dynamic> json = rawActivity(activityId);
    breakIt(json['payload'] as Map<String, dynamic>);
    final ActivitySpec spec = ActivitySpec.fromJson(json, sourcePath: 'test');
    expect(
      () => registry.require(spec.engineId).parseContent(spec, bundle.packResolver),
      throwsA(isA<ActivityContentException>().having(
          (ActivityContentException e) => e.message, 'message', contains(because))),
    );
  }

  Future<ActivityCubit<ActivityContent, dynamic>> started(
    String activityId, {
    String languageCode = 'en',
    ActivityCheckpointSink? checkpointSink,
    ActivityCheckpoint? resume,
    ActivitySoundboard? soundboard,
    RecordingActivityNarrator? narrator,
  }) async {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    final ActivityEngine<ActivityContent> engine =
        registry.require(spec.engineId);
    final ActivityServices base = ActivityServices.forTest(
      languageCode: languageCode,
      checkpointSink: checkpointSink,
    );
    final ActivityCubit<ActivityContent, dynamic> cubit =
        engine.createCubit(engine.createSession(
      spec: spec,
      services: ActivityServices(
        narrator: narrator ?? base.narrator,
        soundboard: soundboard ?? base.soundboard,
        random: base.random,
        checkpointSink: base.checkpointSink,
        languageCode: languageCode,
      ),
      packs: bundle.packResolver,
      storyNodeId: 'stars.test',
      seed: 11,
      resume: resume,
    ));
    await cubit.start();
    return cubit;
  }

  ActivityAttempt answerFor(ActivityState state) {
    final Object? step = state.engineStep;
    if (step is SpotDiffStep) {
      return ChoiceAttempt(state.view!.liveOptionIds.first);
    }
    if (step is ShadowStep) {
      return QuantityAttempt(step.round.targetPercent);
    }
    if (step is MixStep) {
      return SequenceAttempt(step.round.target);
    }
    if (step is TraceStep) {
      return ChoiceAttempt(step.figure.lastAnchor.id);
    }
    if (step is DeductionStep) {
      final Set<String> aside = state.view!.dimmedOptionIds.toSet();
      return ChoiceAttempt(step.content
          .ruledOutBy(step.clueIndex)
          .map((PackItem item) => item.id)
          .firstWhere((String id) => !aside.contains(id)));
    }
    throw StateError('no answer known for ${step.runtimeType}');
  }

  // ======================================================== the chapter shape

  group('The chapter is five different things', () {
    test('it contains exactly five activities', () {
      expect(activityIds(), hasLength(5));
    });

    test('no engine and no interaction mode is used twice', () {
      final List<ActivityEngineDescriptor> descriptors = <ActivityEngineDescriptor>[
        for (final String id in activityIds())
          registry.require(bundle.requireActivity(id).engineId).descriptor,
      ];
      expect(descriptors.map((ActivityEngineDescriptor d) => d.engineId).toSet(),
          hasLength(5));
      final List<InteractionMode> modes = <InteractionMode>[
        for (final ActivityEngineDescriptor d in descriptors)
          ...d.interactionModes,
      ];
      expect(modes.toSet(), hasLength(modes.length));
    });

    test('the climax is solved by ruling out, and the mix is not a quiz', () {
      // The two banned shapes for this chapter, checked by capability rather
      // than by name: nothing here is answered by picking one option.
      for (final String id in activityIds()) {
        final ActivityEngineDescriptor d =
            registry.require(bundle.requireActivity(id).engineId).descriptor;
        expect(d.interactionModes, isNot(contains(InteractionMode.chooseOne)),
            reason: '$id is a multiple-choice question');
      }
      final StoryNode climax =
          stars.nodes.firstWhere((StoryNode n) => n.beat == StoryBeat.climax);
      expect(bundle.requireActivity(climax.activityRef!).engineId, 'deduction');
    });

    test('every activity parses in both locales', () {
      for (final String id in activityIds()) {
        expect(bundle.requireActivity(id).locales, containsAll(<String>['en', 'ar']));
        contentOf<ActivityContent>(id);
      }
    });
  });

  // ================================================================ the chain

  group('The clues run from one activity into the next', () {
    test('each relit star is the witness for the clue in the same place', () {
      // The chain is literal: the orange star says it went above the clouds,
      // and the first clue is the orange star's. If the rounds or the clues
      // are reordered separately, the climax quotes a star about something it
      // never said.
      final MixLabContent mix = contentOf<MixLabContent>('stars_relight');
      final DeductionContent deduce =
          contentOf<DeductionContent>('stars_who_carries_it');
      expect(deduce.clues, hasLength(mix.rounds.length));
      for (int i = 0; i < mix.rounds.length; i++) {
        final String colour = mix.resultOf(mix.rounds[i].target)!.label.resolve('en');
        expect(deduce.clues[i].label.resolve('en'), contains(colour),
            reason: 'clue $i does not name the $colour star that gave it');
      }
    });

    test('the shadow round that ends the experiment casts the page', () {
      final ShadowPlayContent shadow =
          contentOf<ShadowPlayContent>('stars_what_covers_them');
      expect(shadow.rounds.last.item.id, 'page',
          reason: 'the discovery the next beat is built on is that the '
              'shadow is a page');
    });

    test('the answer the clues leave is the one the story resolves on', () {
      final DeductionContent deduce =
          contentOf<DeductionContent>('stars_who_carries_it');
      expect(deduce.answer.id, 'comet');
    });

    test('the missing stars lie on one line, low left to high right', () {
      final List<Offset> spots = <Offset>[
        for (final DiffSpot spot
            in contentOf<SpotDiffContent>('stars_missing_stars').spots)
          spot.fractionLeft,
      ]..sort((Offset a, Offset b) => a.dx.compareTo(b.dx));
      for (int i = 1; i < spots.length; i++) {
        expect(spots[i].dy, lessThan(spots[i - 1].dy),
            reason: 'the success line says the stars went out in a line');
      }
    });
  });

  // ============================================================ spot_the_diff

  group('Differences are found in the order the child sees them', () {
    test('finding them backwards is right first time, every time', () async {
      // The regression. Steps used to carry a precomputed "already found" set
      // from a shuffled order, so a child who found the second one first was
      // told a correct tap was wrong on a later step.
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_missing_stars');
      addTearDown(cubit.close);
      final List<String> ids = List<String>.of(cubit.state.view!.liveOptionIds);
      for (final String id in ids.reversed) {
        await cubit.submit(ChoiceAttempt(id));
      }
      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.stepsIndependent, ids.length);
    });

    test('the reveal spoken is the one for the star actually found', () async {
      final RecordingActivityNarrator narrator = RecordingActivityNarrator();
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_missing_stars', narrator: narrator);
      addTearDown(cubit.close);
      await cubit.submit(const ChoiceAttempt('high_right'));
      expect(narrator.spoken.last,
          'Gone. And the dark is still moving on from here.');
    });

    test('a star already found is not found twice', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_missing_stars');
      addTearDown(cubit.close);
      await cubit.submit(const ChoiceAttempt('low_left'));
      await cubit.submit(const ChoiceAttempt('low_left'));
      expect(cubit.state.lastOutcome, AttemptOutcome.wrongItem);
      expect(cubit.state.stepIndex, 1);
    });

    test('nothing marks a difference before the child asks for help', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_missing_stars');
      addTearDown(cubit.close);
      expect(cubit.state.view!.highlightOptionId, isNull);
      await cubit.submit(const HelpRequestedAttempt());
      expect(cubit.state.view!.highlightOptionId, isNotNull);
    });

    test('the same picture twice, or two spots in one tap, is refused', () {
      expectRejected('stars_missing_stars',
          (Map<String, dynamic> p) => p['imageRight'] = p['imageLeft'],
          'same picture');
      expectRejected('stars_missing_stars', (Map<String, dynamic> p) {
        final List<dynamic> spots = p['spots'] as List<dynamic>;
        (spots[1] as Map<String, dynamic>)['posLeft'] =
            (spots[0] as Map<String, dynamic>)['posLeft'];
      }, 'overlap');
    });
  });

  // ============================================================== shadow_play

  group('The shadow obeys the light', () {
    test('nearer the light is always a bigger shadow', () {
      final ShadowPlayContent shadow =
          contentOf<ShadowPlayContent>('stars_what_covers_them');
      double previous = double.infinity;
      for (int p = shadow.trackMinPercent; p <= shadow.trackMaxPercent; p += 5) {
        final double scale = shadow.shadowScaleAt(p.toDouble());
        expect(scale, lessThan(previous));
        previous = scale;
      }
    });

    test('inside the window fits; just outside is a near miss; far is wrong',
        () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_what_covers_them');
      addTearDown(cubit.close);
      final ShadowStep step = cubit.state.engineStep! as ShadowStep;
      final ShadowPlayCubit shadow = cubit as ShadowPlayCubit;
      final int target = step.round.targetPercent;
      final int tolerance = step.content.tolerancePercent;
      expect(shadow.judge(step, QuantityAttempt(target)).isCorrect, isTrue);
      expect(shadow.judge(step, QuantityAttempt(target + tolerance)).isCorrect,
          isTrue);
      expect(shadow.judge(step, QuantityAttempt(target - tolerance - 2)).outcome,
          AttemptOutcome.wrongSlotButRightItem);
      expect(shadow.judge(step, QuantityAttempt(target + tolerance * 3)).outcome,
          AttemptOutcome.wrongItem);
    });

    test('no round starts solved, and the rule is needed both ways', () {
      final ShadowPlayContent shadow =
          contentOf<ShadowPlayContent>('stars_what_covers_them');
      for (final ShadowRound round in shadow.rounds) {
        expect((round.startPercent - round.targetPercent).abs(),
            greaterThan(shadow.tolerancePercent * 2));
      }
      expect(shadow.rounds.map((ShadowRound r) => r.growsShadow).toSet(),
          <bool>{true, false});
    });

    test('the parser refuses content that teaches a direction, not a rule', () {
      expectRejected('stars_what_covers_them', (Map<String, dynamic> p) {
        for (final dynamic round in p['rounds'] as List<dynamic>) {
          (round as Map<String, dynamic>)['startPercent'] = 78;
          round['targetPercent'] =
              (p['rounds'] as List<dynamic>).indexOf(round) * 15 + 28;
        }
      }, 'same way');
      expectRejected('stars_what_covers_them', (Map<String, dynamic> p) {
        final Map<String, dynamic> round =
            (p['rounds'] as List<dynamic>).first as Map<String, dynamic>;
        round['startPercent'] = (round['targetPercent'] as int) + 4;
      }, 'solved before');
    });

    testWidgets('moving the object judges nothing; the light is the answer',
        (WidgetTester tester) async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await tester.runAsync(() => started('stars_what_covers_them'))
              as ActivityCubit<ActivityContent, dynamic>;
      addTearDown(cubit.close);
      final List<ActivityAttempt> sent = <ActivityAttempt>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => registry
                .require('shadow_play')
                .createBoard()(context, cubit.state, sent.add),
          ),
        ),
      ));
      await tester.tap(find.bySemanticsLabel('closer to the light'));
      await tester.tap(find.bySemanticsLabel('closer to the light'));
      await tester.pump();
      expect(sent, isEmpty, reason: 'experimenting must not be judged');

      await tester.tap(find.bySemanticsLabel('shine'));
      final ShadowStep step = cubit.state.engineStep! as ShadowStep;
      expect(sent, hasLength(1));
      expect((sent.single as QuantityAttempt).value,
          lessThan(step.round.startPercent),
          reason: 'the object moved toward the light before it was judged');
    });
  });

  // ================================================================== mix_lab

  group('A colour is made, not picked', () {
    test('order does not matter; the set does', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_relight');
      addTearDown(cubit.close);
      final MixStep step = cubit.state.engineStep! as MixStep;
      final MixLabCubit mix = cubit as MixLabCubit;
      expect(
          mix.judge(step, SequenceAttempt(step.round.target.reversed.toList()))
              .isCorrect,
          isTrue);
      expect(mix.judge(step, SequenceAttempt(<String>[step.round.target.first]))
          .isCorrect, isFalse,
          reason: 'half the recipe is a different colour');
      expect(mix.judge(step, const SequenceAttempt(<String>['red', 'yellow', 'blue']))
          .isCorrect, isFalse,
          reason: 'everything at once is mud, not orange');
    });

    test('no round can be answered by the one dust that looks like it', () {
      final MixLabContent mix = contentOf<MixLabContent>('stars_relight');
      for (final MixRound round in mix.rounds) {
        expect(round.target.length, greaterThanOrEqualTo(2));
      }
    });

    test('every combination a child can make is declared', () {
      final MixLabContent mix = contentOf<MixLabContent>('stars_relight');
      expect(mix.results, hasLength((1 << mix.inks.length) - 1));
    });

    test('an incomplete table and look-alike results are refused', () {
      expectRejected('stars_relight',
          (Map<String, dynamic> p) => (p['mixes'] as List<dynamic>).removeLast(),
          'missing');
      expectRejected('stars_relight', (Map<String, dynamic> p) {
        final List<dynamic> mixes = p['mixes'] as List<dynamic>;
        (mixes[1] as Map<String, dynamic>)['color'] =
            (mixes[0] as Map<String, dynamic>)['color'];
      }, 'same colour');
    });

    testWidgets('tapping dust in and out judges nothing; the light does',
        (WidgetTester tester) async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await tester.runAsync(() => started('stars_relight'))
              as ActivityCubit<ActivityContent, dynamic>;
      addTearDown(cubit.close);
      final List<ActivityAttempt> sent = <ActivityAttempt>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => registry
                .require('mix_lab')
                .createBoard()(context, cubit.state, sent.add),
          ),
        ),
      ));
      await tester.tap(find.bySemanticsLabel('yellow stardust'));
      await tester.tap(find.bySemanticsLabel('blue stardust'));
      await tester.tap(find.bySemanticsLabel('blue stardust'));
      await tester.tap(find.bySemanticsLabel('red stardust'));
      await tester.pump();
      expect(sent, isEmpty);

      await tester.tap(find.bySemanticsLabel('use this'));
      expect((sent.single as SequenceAttempt).orderedTokenIds,
          <String>['red', 'yellow']);
    });
  });

  // ================================================================ deduction

  group('The answer is what the clues leave', () {
    test('each clue is one step per card it rules out', () {
      final DeductionContent deduce =
          contentOf<DeductionContent>('stars_who_carries_it');
      int expected = 0;
      for (int i = 0; i < deduce.clues.length; i++) {
        final int ruledOut = deduce.ruledOutBy(i).length;
        expect(ruledOut, greaterThan(0), reason: 'clue $i does nothing');
        expected += ruledOut;
      }
      expect(expected, deduce.candidates.length - 1);
    });

    test('setting aside a card the clue keeps is refused', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_who_carries_it');
      addTearDown(cubit.close);
      await cubit.submit(const ChoiceAttempt('comet'));
      expect(cubit.state.lastOutcome, AttemptOutcome.wrongItem);
      await cubit.submit(const ChoiceAttempt('dragon'));
      expect(cubit.state.lastOutcome, AttemptOutcome.wrongItem,
          reason: 'the dragon flies high; the first clue keeps it');
    });

    test('a card the NEXT clue rules out is not yet ruled out', () async {
      // Apply the clue you have, not the one you guess is coming.
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_who_carries_it');
      addTearDown(cubit.close);
      await cubit.submit(const ChoiceAttempt('satellite'));
      expect(cubit.state.lastOutcome, AttemptOutcome.wrongItem);
    });

    test('within a clue, any order the child chooses is right', () async {
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_who_carries_it');
      addTearDown(cubit.close);
      for (final String id in <String>[
        'kite', 'owl', 'satellite', 'flying_saucer', 'dragon',
      ]) {
        await cubit.submit(ChoiceAttempt(id));
      }
      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.stepsIndependent, 5);
    });

    test('each clue is summed up once it is fully applied, not before',
        () async {
      final RecordingActivityNarrator narrator = RecordingActivityNarrator();
      final ActivityCubit<ActivityContent, dynamic> cubit =
          await started('stars_who_carries_it', narrator: narrator);
      addTearDown(cubit.close);
      const String summary = 'Only things that fly that high are left.';
      await cubit.submit(const ChoiceAttempt('owl'));
      expect(narrator.spoken, isNot(contains(summary)),
          reason: 'the kite is still standing');
      await cubit.submit(const ChoiceAttempt('kite'));
      expect(narrator.spoken, contains(summary));
    });

    test('unsolvable and do-nothing clues are refused before anyone plays', () {
      expectRejected('stars_who_carries_it',
          (Map<String, dynamic> p) => (p['clues'] as List<dynamic>).removeLast(),
          'exactly one');
      expectRejected('stars_who_carries_it', (Map<String, dynamic> p) {
        final List<dynamic> clues = p['clues'] as List<dynamic>;
        clues.add(Map<String, dynamic>.of(clues.first as Map<String, dynamic>)
          ..['id'] = 'again');
      }, 'rules nobody out');
      expectRejected('stars_who_carries_it', (Map<String, dynamic> p) {
        ((p['clues'] as List<dynamic>).first
            as Map<String, dynamic>)['attribute'] = 'colour';
      }, 'says nothing about');
    });
  });

  // ============================================== the words and the pictures

  group('The pictures say what the content says', () {
    Future<(int, int, Uint8List)> pixelsOf(String asset) async {
      final ui.Codec codec =
          await ui.instantiateImageCodec(File(asset).readAsBytesSync());
      final ui.Image image = (await codec.getNextFrame()).image;
      final ByteData data = (await image.toByteData())!;
      return (image.width, image.height, data.buffer.asUint8List());
    }

    testWidgets('every authored difference is really in the art, and nothing '
        'else is', (WidgetTester tester) async {
      // Spots are coordinates typed into JSON over a picture drawn elsewhere.
      // If they drift, the child taps the gap they can see and is told there
      // is nothing there.
      await tester.runAsync(() async {
        final SpotDiffContent content =
            contentOf<SpotDiffContent>('stars_missing_stars');
        final (int w, int h, Uint8List left) =
            await pixelsOf(content.imageLeft);
        final (int w2, int h2, Uint8List right) =
            await pixelsOf(content.imageRight);
        expect((w2, h2), (w, h));

        bool insideASpot(int x, int y) => content.spots.any((DiffSpot s) =>
            (Offset(x / w, y / h) - s.fractionLeft).distance <= s.hitRadius);

        int strayDifferences = 0;
        final List<double> spotDifference =
            List<double>.filled(content.spots.length, 0);
        for (int y = 0; y < h; y += 2) {
          for (int x = 0; x < w; x += 2) {
            final int o = 4 * (y * w + x);
            final int delta = (left[o] - right[o]).abs() +
                (left[o + 1] - right[o + 1]).abs() +
                (left[o + 2] - right[o + 2]).abs();
            if (delta < 24) {
              continue;
            }
            if (!insideASpot(x, y)) {
              strayDifferences++;
            }
            for (int i = 0; i < content.spots.length; i++) {
              if ((Offset(x / w, y / h) - content.spots[i].fractionLeft)
                      .distance <=
                  content.spots[i].hitRadius) {
                spotDifference[i]++;
              }
            }
          }
        }
        expect(strayDifferences, 0,
            reason: 'the pictures differ somewhere no spot is authored');
        for (int i = 0; i < content.spots.length; i++) {
          expect(spotDifference[i], greaterThan(20),
              reason: '"${content.spots[i].id}" is authored where the two '
                  'pictures are the same');
        }
      });
    });

    testWidgets('the Silver Page is silver', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final (_, _, Uint8List bytes) = await pixelsOf(stars.rewardArt!);
        int opaque = 0;
        int silver = 0;
        for (int o = 0; o + 3 < bytes.length; o += 4) {
          if (bytes[o + 3] < 200) {
            continue;
          }
          opaque++;
          final int high = <int>[bytes[o], bytes[o + 1], bytes[o + 2]]
              .reduce((int a, int b) => a > b ? a : b);
          final int low = <int>[bytes[o], bytes[o + 1], bytes[o + 2]]
              .reduce((int a, int b) => a < b ? a : b);
          if (high - low < 28 && high > 140) {
            silver++;
          }
        }
        expect(silver / opaque, greaterThan(0.8),
            reason: '${stars.rewardArt} is what the child is told is silver');
      });
    });
  });

  // ============================================ silent phones and interruption

  group('The chapter survives a silent phone and an interruption', () {
    test('every activity runs to the end with no audio device at all',
        () async {
      for (final String id in activityIds()) {
        final ActivityCubit<ActivityContent, dynamic> cubit =
            await started(id, soundboard: const SilentActivitySoundboard());
        int guard = 0;
        while (cubit.state.status == ActivityStatus.running && guard < 60) {
          guard++;
          await cubit.submit(answerFor(cubit.state));
        }
        expect(cubit.state.result.completion, ActivityCompletion.completed,
            reason: '$id could not be finished without sound');
        await cubit.close();
      }
    });

    test('leaving mid-activity keeps what the child had already worked out',
        () async {
      for (final String id in <String>[
        'stars_missing_stars',
        'stars_who_carries_it',
      ]) {
        final RecordingActivityCheckpointSink sink =
            RecordingActivityCheckpointSink();
        final ActivityCubit<ActivityContent, dynamic> first =
            await started(id, checkpointSink: sink);
        await first.submit(answerFor(first.state));
        final List<String> doneBefore =
            List<String>.of(first.state.view!.dimmedOptionIds);
        expect(doneBefore, isNotEmpty);
        await first.abandon();
        await first.close();

        final ActivityCubit<ActivityContent, dynamic> second =
            await started(id, checkpointSink: sink, resume: sink.latest);
        addTearDown(second.close);
        expect(second.state.stepIndex, 1, reason: '$id restarted');
        expect(second.state.view!.dimmedOptionIds, doneBefore,
            reason: '$id forgot what was already found');
      }
    });
  });
}
