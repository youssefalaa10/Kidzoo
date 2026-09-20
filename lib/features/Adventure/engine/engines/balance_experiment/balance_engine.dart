import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_content.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One order to weigh out.
class BalanceStep extends ActivityStep {
  const BalanceStep({
    required String stepId,
    required this.round,
    required this.tolerance,
    required this.unitLabel,
    required this.targetImage,
    required this.accentColorValue,
  }) : super(stepId);

  final BalanceRound round;
  final int tolerance;
  final LocalizedText unitLabel;
  final String? targetImage;
  final int? accentColorValue;

  bool isLevel(int total) => (total - round.target).abs() <= tolerance;
}

class BalanceCubit extends ActivityCubit<BalanceContent, BalanceStep> {
  BalanceCubit(super.session);

  @override
  List<BalanceStep> buildSteps() {
    return <BalanceStep>[
      for (int index = 0; index < content.rounds.length; index++)
        BalanceStep(
          stepId: 'weigh_${index}_${content.rounds[index].id}',
          round: content.rounds[index],
          tolerance: content.tolerance,
          unitLabel: content.unitLabel,
          targetImage: content.targetImage,
          accentColorValue: content.accentColorValue,
        ),
    ];
  }

  @override
  ActivityJudgement judge(BalanceStep step, ActivityAttempt attempt) {
    if (attempt is! QuantityAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    if (step.isLevel(attempt.value)) {
      return const ActivityJudgement.correct();
    }
    // Off by one unit is a child who has understood the task and miscounted
    // the last item; off by five is one who has not yet seen what the scale is
    // doing. The report needs to be able to tell those apart, and the
    // distinction costs nothing to record here.
    final int miss = (attempt.value - step.round.target).abs();
    return miss <= step.tolerance + 1
        ? const ActivityJudgement.wrongSlotButRightItem()
        : const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(BalanceStep step, ScaffoldLevel level) {
    // Everything on the counter stays available at every rung. Taking produce
    // away from a child mid-experiment would break the one thing this mechanic
    // has that no other activity does: you can try something, see what happens,
    // and undo it. Help arrives as the scale showing more, not as the counter
    // offering less.
    final List<String> everything = step.round.available
        .map((WeighedItem item) => item.id)
        .toSet()
        .toList(growable: false);

    final List<WeighedItem> solution = step.round.oneSolution;

    return ActivityStepView(
      prompt: step.round.prompt,
      revealLine: step.round.revealLine,
      liveOptionIds: everything,
      highlightOptionId: level == ScaffoldLevel.modelled && solution.isNotEmpty
          ? solution.first.id
          : null,
    );
  }
}

/// A beam balance the child can experiment on.
///
/// The distinguishing thing is not the arithmetic, it is the order of events.
/// Every other activity in the app asks a question and waits for an answer;
/// here the child can put something on, watch the beam move, take it off and
/// watch it move back, as many times as they like, before anything is judged.
/// Only handing the basket over is an answer — and getting that wrong costs
/// nothing but a sentence from the seller and another go.
class BalanceExperimentEngine extends ActivityEngine<BalanceContent> {
  const BalanceExperimentEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'balance_experiment',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.arithmetic},
        interactionModes: <InteractionMode>{InteractionMode.dragToTarget},
        contentParameters: <ContentParameter>[
          ContentParameter.text('itemsRef', isRequired: true),
          ContentParameter.list('rounds',
              isRequired: true,
              description: 'each with id, target, itemIds, its own prompt and '
                  'an optional revealLine spoken once the pans come level'),
          ContentParameter.text('weightAttribute',
              description: 'which pack attribute carries the quantity, so a '
                  'story about cargo can balance on "mass" and one about '
                  'floating on something else entirely'),
          ContentParameter.integer('tolerance',
              minValue: 0,
              maxValue: 3,
              description: 'how far off level still counts as level; zero for '
                  'whole units, which is the honest default'),
          ContentParameter.text('targetImage'),
          ContentParameter.text('unitLabel'),
        ],
        adaptationAxis: 'tolerance',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  BalanceContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseBalanceContent(spec, packs);

  @override
  Iterable<String> assetsFor(BalanceContent content) => content.assetPaths;

  @override
  ActivityCubit<BalanceContent, dynamic> createCubit(
    ActivitySession<BalanceContent> session,
  ) =>
      BalanceCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! BalanceStep) {
        return const SizedBox.shrink();
      }
      return BalanceBoard(step: step, state: state, submit: submit);
    };
  }
}
