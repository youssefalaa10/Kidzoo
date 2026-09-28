
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

import 'support/disk_content_source.dart';

/// The three engines Adventure 2 added, and the half of `counting` it filled in.
///
/// Each one earned its place by claiming a capability key nothing else had, so
/// what is checked here is the thing that key describes: a program that runs
/// before it is judged, a quantity a child can change their mind about, and a
/// line that has to pass through points in order. The shared guarantees — that
/// a child always finishes, that generation is reproducible — are covered for
/// every engine in `engines_test.dart`; this file is about what makes these
/// three different.
void main() {
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
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
      seed: seed,
    ));
  }

  /// Parses a payload against its engine without going near a widget tree.
  T contentOf<T extends ActivityContent>(String activityId) {
    final ActivitySpec spec = bundle.requireActivity(activityId);
    return registry.require(spec.engineId).parseContent(
          spec,
          bundle.packResolver,
        ) as T;
  }

  // ============================================================== code_path

  group('code_path', () {
    CodePathContent boardFor({
      int columns = 4,
      int rows = 3,
      CommandMode mode = CommandMode.absolute,
      int maxCommands = 8,
    }) {
      return CodePathContent(
        columns: columns,
        rows: rows,
        commandMode: mode,
        maxCommands: maxCommands,
        routes: <PathRoute>[
          PathRoute(
            id: 'r',
            start: const GridCell(0, 2),
            startFacing: GridDirection.north,
            goal: const GridCell(3, 2),
            blocked: <GridCell>{const GridCell(1, 2)},
            label: const LocalizedText.empty(),
          ),
        ],
      );
    }

    test('a program that reaches the goal arrives', () {
      final CodePathContent content = boardFor();
      final PathRun run = PathRun.execute(
        content: content,
        route: content.routes.first,
        program: const <PathCommand>[
          PathCommand.north,
          PathCommand.east,
          PathCommand.east,
          PathCommand.east,
          PathCommand.south,
        ],
      );
      expect(run.outcome, RunOutcome.arrived);
      expect(run.finalCell, const GridCell(3, 2));
    });

    test('driving into a wall stops the vehicle rather than passing through',
        () {
      final CodePathContent content = boardFor();
      final PathRun run = PathRun.execute(
        content: content,
        route: content.routes.first,
        program: const <PathCommand>[PathCommand.east],
      );
      expect(run.outcome, RunOutcome.blocked);
      expect(run.finalCell, const GridCell(0, 2),
          reason: 'it stays where it was, so the child can see what stopped it');
      expect(run.frames.last.isBump, isTrue);
    });

    test('driving off the edge is blocked, not an escape', () {
      final CodePathContent content = boardFor();
      final PathRun run = PathRun.execute(
        content: content,
        route: content.routes.first,
        program: const <PathCommand>[PathCommand.south],
      );
      expect(run.outcome, RunOutcome.blocked);
    });

    test('a program that runs out early stops short', () {
      final CodePathContent content = boardFor();
      final PathRun run = PathRun.execute(
        content: content,
        route: content.routes.first,
        program: const <PathCommand>[PathCommand.north, PathCommand.east],
      );
      expect(run.outcome, RunOutcome.stoppedShort);
    });

    test('relative commands turn in place before they move', () {
      final CodePathContent content = boardFor(mode: CommandMode.relative);
      final PathRun run = PathRun.execute(
        content: content,
        route: content.routes.first,
        program: const <PathCommand>[
          PathCommand.turnRight,
          PathCommand.forward,
        ],
      );
      // Facing north, one right turn faces east; east of (0,2) is the wall.
      expect(run.outcome, RunOutcome.blocked);
      expect(run.frames[1].cell, const GridCell(0, 2),
          reason: 'a turn changes the heading and nothing else');
      expect(run.frames[1].facing, GridDirection.east);
    });

    test('the solver finds a way round the wall', () {
      final CodePathContent content = boardFor();
      final List<PathCommand> solution =
          PathRun.solve(content: content, route: content.routes.first);
      expect(solution, isNotEmpty);
      expect(
        PathRun.execute(
          content: content,
          route: content.routes.first,
          program: solution,
        ).outcome,
        RunOutcome.arrived,
      );
    });

    test('the solver works for relative commands too', () {
      final CodePathContent content = boardFor(
        mode: CommandMode.relative,
        maxCommands: 12,
      );
      final List<PathCommand> solution =
          PathRun.solve(content: content, route: content.routes.first);
      expect(solution, isNotEmpty);
      expect(
        PathRun.execute(
          content: content,
          route: content.routes.first,
          program: solution,
        ).outcome,
        RunOutcome.arrived,
      );
    });

    test('a longer route that still arrives is correct', () async {
      // There is no shortest-path bonus. A four-year-old whose working plan
      // wanders is right, and marking that wrong would teach them that there
      // is one blessed answer rather than that their plan worked.
      final CodePathCubit cubit =
          cubitFor('market_deliver') as CodePathCubit;
      await cubit.start();
      final CodePathStep step = cubit.state.engineStep! as CodePathStep;

      final List<PathCommand> wandering = <PathCommand>[
        PathCommand.north,
        PathCommand.south,
        PathCommand.north,
        ...step.solution.where((PathCommand c) => c != PathCommand.north),
      ];
      expect(
        cubit
            .judge(
              step,
              SequenceAttempt(
                wandering.map((PathCommand c) => c.name).toList(),
              ),
            )
            .isCorrect,
        isTrue,
      );
      await cubit.close();
    });

    test('going the right way and stopping short reads as a motor signal',
        () async {
      // Kept apart from driving into a wall on purpose: one child needs
      // another instruction, the other has misread the board, and collapsing
      // both into "wrong" destroys the only signal that says which.
      final CodePathCubit cubit = cubitFor('market_deliver') as CodePathCubit;
      await cubit.start();
      final CodePathStep step = cubit.state.engineStep! as CodePathStep;
      final List<String> short = step.solution
          .take(step.solution.length - 1)
          .map((PathCommand c) => c.name)
          .toList();

      expect(cubit.judge(step, SequenceAttempt(short)).outcome,
          AttemptOutcome.wrongSlotButRightItem);
      await cubit.close();
    });

    test('the instruction tray never shrinks as help escalates', () async {
      // The ladder narrows a tray of *answers*. Narrowing a tray of
      // instructions can make the journey impossible, so help here arrives as
      // showing rather than as removing.
      final CodePathCubit cubit = cubitFor('market_deliver') as CodePathCubit;
      await cubit.start();
      final CodePathStep step = cubit.state.engineStep! as CodePathStep;
      final int everything = step.content.commands.length;

      for (final ScaffoldLevel level in ScaffoldLevel.values) {
        expect(cubit.describe(step, level).liveOptionIds.length, everything,
            reason: 'at $level the child lost an instruction they may need');
      }
      expect(cubit.describe(step, ScaffoldLevel.narrowed).highlightOptionId,
          isNotNull,
          reason: 'help is the first instruction glowing');
      await cubit.close();
    });

    test('content that cannot be driven is rejected when it is authored', () {
      // An unreachable route would surface as a child trying forever, with the
      // demonstration itself unable to show them what to do.
      expect(
        () => registry.require('code_path').parseContent(
              ActivitySpec.fromJson(const <String, dynamic>{
                'instanceId': 'test.boxed_in',
                'engineId': 'code_path',
                'locales': <String>['en'],
                'payload': <String, dynamic>{
                  'grid': <int>[3, 3],
                  'routes': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'nowhere',
                      'start': <int>[0, 0],
                      'goal': <int>[2, 2],
                      'blocked': <List<int>>[
                        <int>[1, 0],
                        <int>[0, 1],
                        <int>[1, 1],
                      ],
                      'label': 'boxed in',
                    },
                  ],
                },
              }),
              bundle.packResolver,
            ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('the authored route is playable start to finish', () async {
      final CodePathCubit cubit = cubitFor('market_deliver') as CodePathCubit;
      await cubit.start();
      int guard = 0;
      while (cubit.state.status == ActivityStatus.running && guard++ < 20) {
        final CodePathStep step = cubit.state.engineStep! as CodePathStep;
        await cubit.submit(SequenceAttempt(
          step.solution.map((PathCommand c) => c.name).toList(),
        ));
      }
      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      await cubit.close();
    });
  });

  // ====================================================== balance_experiment

  group('balance_experiment', () {
    test('a load that matches the target is correct', () async {
      final BalanceCubit cubit =
          cubitFor('market_weigh_orders') as BalanceCubit;
      await cubit.start();
      final BalanceStep step = cubit.state.engineStep! as BalanceStep;
      expect(cubit.judge(step, QuantityAttempt(step.round.target)).isCorrect,
          isTrue);
      await cubit.close();
    });

    test('one unit out is a near miss, five units out is not', () async {
      // The parent report has to be able to tell a child who understood and
      // miscounted the last item from one who has not yet seen what the beam
      // is doing.
      final BalanceCubit cubit =
          cubitFor('market_weigh_orders') as BalanceCubit;
      await cubit.start();
      final BalanceStep step = cubit.state.engineStep! as BalanceStep;

      expect(cubit.judge(step, QuantityAttempt(step.round.target + 1)).outcome,
          AttemptOutcome.wrongSlotButRightItem);
      expect(cubit.judge(step, QuantityAttempt(step.round.target + 5)).outcome,
          AttemptOutcome.wrongItem);
      await cubit.close();
    });

    test('the counter never shrinks as help escalates', () async {
      // Taking produce away mid-experiment would break the one thing this
      // mechanic has that nothing else does: try it, see it, take it back.
      final BalanceCubit cubit =
          cubitFor('market_weigh_orders') as BalanceCubit;
      await cubit.start();
      final BalanceStep step = cubit.state.engineStep! as BalanceStep;
      final int everything =
          step.round.available.map((WeighedItem i) => i.id).toSet().length;

      for (final ScaffoldLevel level in ScaffoldLevel.values) {
        expect(cubit.describe(step, level).liveOptionIds.length, everything,
            reason: 'at $level the child lost something to experiment with');
      }
      await cubit.close();
    });

    test('every authored target can actually be made', () {
      final BalanceContent content =
          contentOf<BalanceContent>('market_weigh_orders');
      for (final BalanceRound round in content.rounds) {
        expect(round.isReachable, isTrue,
            reason: 'round "${round.id}" asks for ${round.target}, which no '
                'combination of what is on offer adds up to');
        expect(round.oneSolution, isNotEmpty);
        expect(
          round.oneSolution
              .fold<int>(0, (int sum, WeighedItem i) => sum + i.weight),
          round.target,
        );
      }
    });

    test('a target nothing adds up to is rejected when it is authored', () {
      expect(
        () => registry.require('balance_experiment').parseContent(
              ActivitySpec.fromJson(const <String, dynamic>{
                'instanceId': 'test.impossible',
                'engineId': 'balance_experiment',
                'locales': <String>['en'],
                'payload': <String, dynamic>{
                  'itemsRef': 'packs/market_goods',
                  'rounds': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'odd',
                      // Nothing weighing 2 or 5 can make 7 on its own here.
                      'target': 7,
                      'itemIds': <String>['cabbage'],
                      'prompt': 'impossible',
                    },
                  ],
                },
              }),
              bundle.packResolver,
            ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('an item with no weight cannot be put on a scale', () {
      expect(
        () => registry.require('balance_experiment').parseContent(
              ActivitySpec.fromJson(const <String, dynamic>{
                'instanceId': 'test.weightless',
                'engineId': 'balance_experiment',
                'locales': <String>['en'],
                'payload': <String, dynamic>{
                  'itemsRef': 'packs/animals',
                  'rounds': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'r',
                      'target': 2,
                      'itemIds': <String>['monkey'],
                      'prompt': 'weightless',
                    },
                  ],
                },
              }),
              bundle.packResolver,
            ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('playing it through completes', () async {
      final BalanceCubit cubit =
          cubitFor('market_weigh_orders') as BalanceCubit;
      await cubit.start();
      int guard = 0;
      while (cubit.state.status == ActivityStatus.running && guard++ < 20) {
        final BalanceStep step = cubit.state.engineStep! as BalanceStep;
        await cubit.submit(QuantityAttempt(step.round.target));
      }
      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      await cubit.close();
    });
  });

  // ============================================================= trace_path

  group('trace_path', () {
    TraceStep firstFigureOf(TraceCubit cubit) =>
        cubit.state.engineStep! as TraceStep;

    test('a stroke that visits every point in order is correct', () async {
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      final TraceStep step = firstFigureOf(cubit);
      final List<Offset> stroke = <Offset>[
        for (final TraceAnchor anchor in step.figure.walk) anchor.position,
      ];
      expect(cubit.judge(step, StrokeAttempt(points: stroke, strokeIndex: 0))
          .isCorrect, isTrue);
      await cubit.close();
    });

    test('a stroke that stops part-way reads as a motor signal', () async {
      // The hand ran out, not the understanding — which is a different thing
      // from a line that went somewhere else entirely.
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      final TraceStep step = firstFigureOf(cubit);
      final List<Offset> partial = <Offset>[
        step.figure.walk[0].position,
        step.figure.walk[1].position,
      ];
      expect(
        cubit.judge(step, StrokeAttempt(points: partial, strokeIndex: 0)).outcome,
        AttemptOutcome.wrongSlotButRightItem,
      );
      await cubit.close();
    });

    test('a stroke nowhere near the figure reads as not understanding it',
        () async {
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      final TraceStep step = firstFigureOf(cubit);
      expect(
        cubit
            .judge(
              step,
              const StrokeAttempt(
                points: <Offset>[Offset(0.98, 0.98), Offset(0.99, 0.99)],
                strokeIndex: 0,
              ),
            )
            .outcome,
        AttemptOutcome.wrongItem,
      );
      await cubit.close();
    });

    test('points visited out of order do not count', () async {
      // Order is the whole content of a dot-to-dot. A stroke that touches
      // every point backwards has drawn a different figure.
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      final TraceStep step = firstFigureOf(cubit);
      final List<Offset> backwards = <Offset>[
        for (final TraceAnchor anchor in step.figure.walk.reversed)
          anchor.position,
      ];
      expect(
        cubit
            .judge(step, StrokeAttempt(points: backwards, strokeIndex: 0))
            .isCorrect,
        isFalse,
      );
      await cubit.close();
    });

    test('tapping the last point finishes the figure; any other point does not',
        () async {
      // The board sends a tap only when it is wrong or when it is the one that
      // completes the figure — the ordinary taps in between are the child
      // drawing, and judging those would turn one drawing into six questions.
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      final TraceStep step = firstFigureOf(cubit);

      expect(
        cubit.judge(step, ChoiceAttempt(step.figure.lastAnchor.id)).isCorrect,
        isTrue,
      );
      expect(
        cubit.judge(step, ChoiceAttempt(step.figure.anchors[1].id)).isCorrect,
        isFalse,
      );
      await cubit.close();
    });

    test('a closed figure walks back to where it started', () {
      final TraceContent content = contentOf<TraceContent>('market_mend_sign');
      final TraceFigure closed =
          content.figures.firstWhere((TraceFigure f) => f.isClosed);
      expect(closed.walk.length, closed.anchors.length + 1);
      expect(closed.walk.last.id, closed.anchors.first.id);
      expect(closed.lastAnchor.id, closed.anchors.first.id);
    });

    test('numbered dots and a drawn road are the same model, not two engines',
        () {
      // One figure with numbers, one without a road: the dot-to-dot reading
      // and the tracing reading of the same state. If these had needed two
      // engines, the model would have been wrong.
      final TraceContent content = contentOf<TraceContent>('market_mend_sign');
      expect(content.figures.any((TraceFigure f) => f.showGuide), isTrue);
      expect(content.figures.any((TraceFigure f) => !f.showGuide), isTrue);
      expect(content.figures.every((TraceFigure f) => f.showNumbers), isTrue);
    });

    test('points closer together than the tolerance are rejected', () {
      // They would be one point to a child, and the figure would complete
      // itself the moment a finger landed anywhere near.
      expect(
        () => registry.require('trace_path').parseContent(
              ActivitySpec.fromJson(const <String, dynamic>{
                'instanceId': 'test.too_close',
                'engineId': 'trace_path',
                'locales': <String>['en'],
                'payload': <String, dynamic>{
                  'tolerancePercent': 20,
                  'figures': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'f',
                      'points': <List<int>>[
                        <int>[40, 40],
                        <int>[45, 40],
                      ],
                      'label': 'too close',
                    },
                  ],
                },
              }),
              bundle.packResolver,
            ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('a point outside the box is rejected', () {
      expect(
        () => registry.require('trace_path').parseContent(
              ActivitySpec.fromJson(const <String, dynamic>{
                'instanceId': 'test.off_the_box',
                'engineId': 'trace_path',
                'locales': <String>['en'],
                'payload': <String, dynamic>{
                  'figures': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'f',
                      'points': <List<int>>[
                        <int>[10, 10],
                        <int>[140, 10],
                      ],
                      'label': 'off the box',
                    },
                  ],
                },
              }),
              bundle.packResolver,
            ),
        throwsA(isA<ActivityContentException>()),
      );
    });

    test('playing it through completes', () async {
      final TraceCubit cubit = cubitFor('market_mend_sign') as TraceCubit;
      await cubit.start();
      int guard = 0;
      while (cubit.state.status == ActivityStatus.running && guard++ < 20) {
        final TraceStep step = firstFigureOf(cubit);
        await cubit.submit(ChoiceAttempt(step.figure.lastAnchor.id));
      }
      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      await cubit.close();
    });
  });

  // ===================================================== counting, giveN half

  group('counting in giveN mode', () {
    test('the authored activity really is the harder question', () {
      // `giveN` was in the schema from the start with no board behind it, so
      // an author could ask for the harder question and silently get the
      // easier one. This is the assertion that would have caught that.
      final CountingContent content =
          contentOf<CountingContent>('market_fruit_bowl');
      expect(content.mode, CountingMode.giveN);
      expect(content.isAuthored, isTrue);
    });

    testWidgets('the board offers a supply, a bowl and a way to hand it over',
        (WidgetTester tester) async {
      final ActivitySpec spec = bundle.requireActivity('market_fruit_bowl');
      final ActivityEngine<ActivityContent> engine =
          registry.require(spec.engineId);
      final ActivityCubit<ActivityContent, dynamic> cubit =
          cubitFor('market_fruit_bowl');
      await cubit.start();
      addTearDown(cubit.close);

      final List<ActivityAttempt> submitted = <ActivityAttempt>[];
      final ActivityBoardBuilder board = engine.createBoard();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) =>
                board(context, cubit.state, submitted.add),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byKey(giveNSupplyItemKey), findsOneWidget);
      expect(find.byKey(giveNHandOverKey), findsOneWidget);
      // Nothing in the bowl yet, so there is nothing in it to take back out.
      expect(find.byKey(giveNBowlItemKey), findsNothing);

      await tester.tap(find.byKey(giveNSupplyItemKey));
      await tester.pump();

      expect(find.byKey(giveNBowlItemKey), findsOneWidget);
      expect(submitted.whereType<TallyAttempt>().length, 1,
          reason: 'putting one in is counted out loud, not judged');
      expect(submitted.whereType<QuantityAttempt>(), isEmpty,
          reason: 'filling the bowl is not yet an answer');
    });

    testWidgets('the child can take one back out before handing it over',
        (WidgetTester tester) async {
      // A count you cannot correct is a count a four-year-old abandons.
      final ActivitySpec spec = bundle.requireActivity('market_fruit_bowl');
      final ActivityEngine<ActivityContent> engine =
          registry.require(spec.engineId);
      final ActivityCubit<ActivityContent, dynamic> cubit =
          cubitFor('market_fruit_bowl');
      await cubit.start();
      addTearDown(cubit.close);

      final List<ActivityAttempt> submitted = <ActivityAttempt>[];
      final ActivityBoardBuilder board = engine.createBoard();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) =>
                board(context, cubit.state, submitted.add),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byKey(giveNSupplyItemKey));
      await tester.pump();
      await tester.tap(find.byKey(giveNSupplyItemKey));
      await tester.pump();
      await tester.tap(find.byKey(giveNBowlItemKey));
      await tester.pump();
      await tester.tap(find.byKey(giveNHandOverKey));
      await tester.pump();

      final List<QuantityAttempt> answers =
          submitted.whereType<QuantityAttempt>().toList();
      expect(answers.length, 1);
      expect(answers.single.value, 1,
          reason: 'two in, one back out, so one is what was handed over');
    });

    test('playing it through completes', () async {
      final CountingCubit cubit = cubitFor('market_fruit_bowl') as CountingCubit;
      await cubit.start();
      int guard = 0;
      while (cubit.state.status == ActivityStatus.running && guard++ < 20) {
        final CountingStep step = cubit.state.engineStep! as CountingStep;
        await cubit.submit(QuantityAttempt(step.targetCount));
      }
      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      await cubit.close();
    });
  });

  // ======================================================= shared guarantees

  group('The new engines keep the promises every engine makes', () {
    for (final String activityId in <String>[
      'market_deliver',
      'market_weigh_orders',
      'market_mend_sign',
    ]) {
      test('$activityId: a child who gets everything wrong still finishes',
          () async {
        // The no-fail guarantee, checked on the three engines most likely to
        // break it: each one judges something richer than a tap, so each one
        // has a way for a mismatched attempt type to trap a child forever.
        final ActivityCubit<ActivityContent, dynamic> cubit =
            cubitFor(activityId);
        await cubit.start();
        int guard = 0;
        while (cubit.state.status == ActivityStatus.running && guard++ < 60) {
          await cubit.submit(const ChoiceAttempt('nonsense'));
        }
        expect(cubit.state.status, ActivityStatus.finished,
            reason: '$activityId trapped a child on a step');
        expect(cubit.state.result.completion, ActivityCompletion.completed);
        expect(cubit.state.result.score, greaterThan(0),
            reason: 'reaching the end is worth something even after every hint');
        await cubit.close();
      });

      test('$activityId: is reproducible under a seed', () async {
        final ActivityCubit<ActivityContent, dynamic> first =
            cubitFor(activityId, seed: 5);
        final ActivityCubit<ActivityContent, dynamic> second =
            cubitFor(activityId, seed: 5);
        await first.start();
        await second.start();
        expect(
          first.state.engineStep.toString(),
          second.state.engineStep.toString(),
        );
        expect(first.state.stepCount, second.state.stepCount);
        await first.close();
        await second.close();
      });
    }
  });
}
