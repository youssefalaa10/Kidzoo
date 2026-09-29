import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_content.dart';

@immutable
class MixStep extends ActivityStep {
  const MixStep({
    required String stepId,
    required this.round,
    required this.content,
  }) : super(stepId);

  final MixRound round;
  final MixLabContent content;

  /// What the child is trying to make.
  MixResult get target => content.resultOf(round.target)!;
}

class MixLabCubit extends ActivityCubit<MixLabContent, MixStep> {
  MixLabCubit(super.session);

  @override
  List<MixStep> buildSteps() => <MixStep>[
        for (final MixRound round in content.rounds)
          MixStep(stepId: 'mix_${round.id}', round: round, content: content),
      ];

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  /// The board sends the set of inks in the vessel when the child commits.
  /// Order means nothing — red then yellow is yellow then red.
  @override
  ActivityJudgement judge(MixStep step, ActivityAttempt attempt) {
    if (attempt is! SequenceAttempt || attempt.orderedTokenIds.isEmpty) {
      return const ActivityJudgement.wrongItem();
    }
    return MixLabContent.keyFor(attempt.orderedTokenIds.toSet()) ==
            MixLabContent.keyFor(step.round.target)
        ? const ActivityJudgement.correct()
        : const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(MixStep step, ScaffoldLevel level) {
    // The ladder never takes an ink away — a child who cannot use the wrong
    // ones cannot find out they are wrong. It points at the right ones
    // instead: one at narrowed, all of them once modelled.
    final List<String> pointed = switch (level) {
      ScaffoldLevel.initial || ScaffoldLevel.gentleRetry => const <String>[],
      ScaffoldLevel.narrowed => <String>[step.round.target.first],
      ScaffoldLevel.modelled => step.round.target,
    };
    return ActivityStepView(
      prompt: step.round.label,
      revealLine: step.round.revealLine,
      liveOptionIds: <String>[for (final MixInk ink in content.inks) ink.id],
      highlightOptionId: pointed.isEmpty ? null : pointed.join('+'),
    );
  }
}
