import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_content.dart';

/// One journey to plan.
class CodePathStep extends ActivityStep {
  const CodePathStep({
    required String stepId,
    required this.route,
    required this.content,
    required this.solution,
  }) : super(stepId);

  final PathRoute route;
  final CodePathContent content;

  /// The shortest program that works. Shown when help is needed; **never**
  /// compared against the child's answer.
  final List<PathCommand> solution;
}

class CodePathCubit extends ActivityCubit<CodePathContent, CodePathStep> {
  CodePathCubit(super.session);

  @override
  List<CodePathStep> buildSteps() {
    return <CodePathStep>[
      for (int index = 0; index < content.routes.length; index++)
        CodePathStep(
          stepId: 'route_${index}_${content.routes[index].id}',
          route: content.routes[index],
          content: content,
          solution:
              PathRun.solve(content: content, route: content.routes[index]),
        ),
    ];
  }

  @override
  ActivityJudgement judge(CodePathStep step, ActivityAttempt attempt) {
    if (attempt is! SequenceAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    final List<PathCommand> program = <PathCommand>[
      for (final String token in attempt.orderedTokenIds)
        if (PathCommand.tryParse(token) case final PathCommand command)
          command,
    ];
    if (program.isEmpty) {
      return const ActivityJudgement.wrongItem();
    }

    final PathRun run = PathRun.execute(
      content: step.content,
      route: step.route,
      program: program,
    );
    switch (run.outcome) {
      case RunOutcome.arrived:
        // Any program that arrives is right, including a wandering one. There
        // is no shortest-route bonus: rewarding brevity here would teach a
        // four-year-old that their own working plan was the wrong answer.
        return const ActivityJudgement.correct();
      case RunOutcome.stoppedShort:
        // Went the right way and did not go far enough. Kept distinct from
        // driving into a wall on purpose — one child needs another instruction,
        // the other has misread the board, and telling them apart is the only
        // way the parent report says anything useful.
        return const ActivityJudgement.wrongSlotButRightItem();
      case RunOutcome.blocked:
        return const ActivityJudgement.wrongItem();
    }
  }

  @override
  ActivityStepView describe(CodePathStep step, ScaffoldLevel level) {
    // The command buttons stay live at **every** rung. Narrowing them is what
    // the ladder does for a tray of answers, and it is exactly wrong here:
    // taking away an instruction can make the journey impossible, so the help
    // has to arrive as showing rather than as removing.
    final List<String> allCommands = step.content.commands
        .map((PathCommand command) => command.name)
        .toList(growable: false);

    return ActivityStepView(
      prompt: step.route.label,
      revealLine: step.route.revealLine,
      liveOptionIds: allCommands,
      // At `narrowed`, the first instruction of a working program glows, so a
      // stuck child gets a way in without being handed the whole answer. At
      // `modelled` the board drives the ghost through all of it.
      highlightOptionId: switch (level) {
        ScaffoldLevel.narrowed || ScaffoldLevel.modelled =>
          step.solution.isEmpty ? null : step.solution.first.name,
        ScaffoldLevel.initial || ScaffoldLevel.gentleRetry => null,
      },
    );
  }
}

/// Plan a route, then watch it run.
///
/// The only mechanic in the app where the child commits to a whole plan before
/// seeing any of it happen. Everything else answers immediately, one tap at a
/// time; predict, run, watch, revise is a different thing to practise, and it
/// is the part of early computational thinking that no amount of content on
/// top of a sorting tray produces.
class CodePathEngine extends ActivityEngine<CodePathContent> {
  const CodePathEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'code_path',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.spatialReasoning},
        interactionModes: <InteractionMode>{InteractionMode.orderSequence},
        contentParameters: <ContentParameter>[
          ContentParameter.list('grid',
              isRequired: true, description: '[columns, rows]'),
          ContentParameter.list('routes',
              isRequired: true,
              description: 'each with id, start, goal, blocked squares, a '
                  'label saying why the journey matters, and an optional '
                  'revealLine spoken on arrival'),
          ContentParameter.enumeration(
            'commandMode',
            <String>['absolute', 'relative'],
            description: 'absolute arrows are readable straight off the '
                'screen; relative turns are the step up, and the only set '
                'that makes sense for something with a front',
          ),
          ContentParameter.integer('maxCommands',
              minValue: 2,
              maxValue: 20,
              description: 'how long a program may get — a cap so the strip '
                  'stays readable, not a target'),
          ContentParameter.text('vehicleImage'),
          ContentParameter.text('itemsRef'),
        ],
        adaptationAxis: 'maxCommands',
        // Nothing here is script-sensitive: a board is a board in both
        // directions, and the arrows point where the vehicle goes rather than
        // where the text runs, so they are not mirrored for Arabic.
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  CodePathContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseCodePathContent(spec, packs);

  @override
  Iterable<String> assetsFor(CodePathContent content) => content.assetPaths;

  @override
  ActivityCubit<CodePathContent, dynamic> createCubit(
    ActivitySession<CodePathContent> session,
  ) =>
      CodePathCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! CodePathStep) {
        return const SizedBox.shrink();
      }
      return CodePathBoard(step: step, state: state, submit: submit);
    };
  }
}
