import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_content.dart';

/// One thing to find in the dark.
@immutable
class FlashlightStep extends ActivityStep {
  const FlashlightStep({
    required String stepId,
    required this.target,
    required this.alreadyFound,
    required this.content,
    required this.isLast,
  }) : super(stepId);

  /// What the beam is looking for right now.
  final DarkFind target;

  /// Everything found before this step, in order.
  ///
  /// Carried on the step rather than accumulated inside the board, so the
  /// board stays a pure function of the state and a child who leaves halfway
  /// comes back to the scene they had lit rather than to a dark one. It is
  /// also what makes the world change visible without a counter: the picture
  /// gets more legible as they work, and that *is* the progress display.
  final List<DarkFind> alreadyFound;

  final FlashlightContent content;

  final bool isLast;
}

class FlashlightCubit extends ActivityCubit<FlashlightContent, FlashlightStep> {
  FlashlightCubit(super.session);

  @override
  List<FlashlightStep> buildSteps() {
    return <FlashlightStep>[
      for (int index = 0; index < content.finds.length; index++)
        FlashlightStep(
          stepId: 'find_${content.finds[index].id}',
          target: content.finds[index],
          alreadyFound:
              List<DarkFind>.unmodifiable(content.finds.sublist(0, index)),
          content: content,
          isLast: index == content.finds.length - 1,
        ),
    ];
  }

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  @override
  ActivityJudgement judge(FlashlightStep step, ActivityAttempt attempt) {
    // Touching the lit object. The ordinary route, and the one the board uses,
    // because by the time a thing is lit the board already knows which thing
    // it is and guessing from coordinates would only add a way to be wrong.
    if (attempt is ChoiceAttempt) {
      return attempt.optionId == step.target.id
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }
    // Touching the scene. Kept because it is the honest model of what the
    // child did — they pointed at a place, not at an id — and because it lets
    // the rules be tested as a table of coordinates with no widget tree.
    if (attempt is TapPointAttempt) {
      final double distance =
          (attempt.normalized - step.target.position).distance;
      if (distance <= content.hitToleranceFraction) {
        return const ActivityJudgement.correct();
      }
      // Near-misses are a motor signal, not a knowledge one. A child who found
      // the compass and missed it by four millimetres has not failed to find
      // the compass, and recording that as "did not find it" would be a
      // measurement error that then feeds adaptation.
      if (distance <= content.hitToleranceFraction * 2) {
        return const ActivityJudgement.wrongSlotButRightItem();
      }
      return const ActivityJudgement.wrongItem();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(FlashlightStep step, ScaffoldLevel level) {
    final List<String> allIds =
        content.finds.map((DarkFind find) => find.id).toList(growable: false);
    // The ladder narrows *what can be answered*, never what can be seen. A
    // dark scene that starts deleting objects when a child hesitates takes
    // away the thing they were looking at, which reads as the app breaking
    // rather than as help.
    final List<String> live = services.coach.liveOptionsFor(
      level: level,
      allOptionIds: allIds,
      correctOptionId: step.target.id,
      random: services.random,
    );
    return ActivityStepView(
      prompt: step.target.label,
      revealLine: step.target.revealLine,
      liveOptionIds: live,
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.target.id : null,
    );
  }
}
