import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_content.dart';

/// The option id a board highlights when it demonstrates where to put the
/// object. There is one answer per round, so it is a constant, not an item.
const String shadowTargetOptionId = 'shadow_target';

@immutable
class ShadowStep extends ActivityStep {
  const ShadowStep({
    required String stepId,
    required this.round,
    required this.content,
  }) : super(stepId);

  final ShadowRound round;
  final ShadowPlayContent content;
}

class ShadowPlayCubit extends ActivityCubit<ShadowPlayContent, ShadowStep> {
  ShadowPlayCubit(super.session);

  @override
  List<ShadowStep> buildSteps() => <ShadowStep>[
        for (final ShadowRound round in content.rounds)
          ShadowStep(stepId: 'shadow_${round.id}', round: round, content: content),
      ];

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  /// The board reports where the object was left, as a track percentage.
  ///
  /// Close but outside the window is the motor verdict, not the knowledge
  /// one: a child who moved it the right way and stopped a finger short has
  /// understood the shadow.
  @override
  ActivityJudgement judge(ShadowStep step, ActivityAttempt attempt) {
    if (attempt is! QuantityAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    final int miss = (attempt.value - step.round.targetPercent).abs();
    if (miss <= content.tolerancePercent) {
      return const ActivityJudgement.correct();
    }
    if (miss <= content.tolerancePercent * 2) {
      return const ActivityJudgement.wrongSlotButRightItem();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(ShadowStep step, ScaffoldLevel level) {
    return ActivityStepView(
      prompt: step.round.label,
      revealLine: step.round.revealLine,
      liveOptionIds: const <String>[shadowTargetOptionId],
      highlightOptionId:
          level == ScaffoldLevel.modelled ? shadowTargetOptionId : null,
    );
  }
}
