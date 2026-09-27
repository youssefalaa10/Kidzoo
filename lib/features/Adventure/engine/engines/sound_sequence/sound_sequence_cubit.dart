import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/sound_sequence/sound_sequence_content.dart';

/// One rhythm to hear and give back.
@immutable
class SoundSequenceStep extends ActivityStep {
  const SoundSequenceStep({
    required String stepId,
    required this.round,
    required this.roundIndex,
    required this.roundCount,
    required this.voices,
    required this.beatMilliseconds,
    this.accentColorValue,
  }) : super(stepId);

  final SoundRound round;
  final int roundIndex;
  final int roundCount;

  /// Every voice on screen, in a stable order for the whole activity.
  ///
  /// Stable rather than shuffled per round on purpose. The child is being
  /// asked to remember an order of *sounds*; moving the pictures between
  /// rounds adds a search task on top of that, and would make the second round
  /// harder for a reason that has nothing to do with rhythm.
  final List<SoundVoice> voices;

  final int beatMilliseconds;
  final int? accentColorValue;

  /// How far open the gate already is when this round starts, 0..1.
  ///
  /// The gate keeps what the child has earned: one leaf per rhythm, and it
  /// never shuts all the way back. That is the whole progress display — no
  /// bar, no counter, just a way through that is visibly more open than it was.
  double get gateOpenAtStart => roundCount == 0 ? 0 : roundIndex / roundCount;

  double get gateOpenWhenDone =>
      roundCount == 0 ? 1 : (roundIndex + 1) / roundCount;

  bool get isLast => roundIndex == roundCount - 1;
}

class SoundSequenceCubit
    extends ActivityCubit<SoundSequenceContent, SoundSequenceStep> {
  SoundSequenceCubit(super.session);

  @override
  List<SoundSequenceStep> buildSteps() {
    return <SoundSequenceStep>[
      for (int index = 0; index < content.rounds.length; index++)
        SoundSequenceStep(
          stepId: 'rhythm_${content.rounds[index].id}',
          round: content.rounds[index],
          roundIndex: index,
          roundCount: content.rounds.length,
          voices: content.voices,
          beatMilliseconds: content.beatMilliseconds,
          accentColorValue: content.accentColorValue,
        ),
    ];
  }

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  @override
  ActivityJudgement judge(SoundSequenceStep step, ActivityAttempt attempt) {
    if (attempt is! SequenceAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    final List<String> given = attempt.orderedTokenIds;
    if (given.length != step.round.length) {
      return const ActivityJudgement.wrongItem();
    }
    for (int index = 0; index < given.length; index++) {
      if (given[index] != step.round.sequence[index]) {
        // Right voices, wrong order is a different mistake from the wrong
        // voices, and the one worth separating: it says the child heard the
        // rhythm and lost the sequence, which is a memory signal rather than a
        // discrimination one. It is the near-miss that the "right item, wrong
        // slot" outcome exists for.
        final List<String> sortedGiven = List<String>.of(given)..sort();
        final List<String> sortedWanted = List<String>.of(step.round.sequence)
          ..sort();
        return sortedGiven.join() == sortedWanted.join()
            ? const ActivityJudgement.wrongSlotButRightItem()
            : const ActivityJudgement.wrongItem();
      }
    }
    return const ActivityJudgement.correct();
  }

  @override
  ActivityStepView describe(SoundSequenceStep step, ScaffoldLevel level) {
    final List<String> allIds =
        step.voices.map((SoundVoice voice) => voice.id).toList(growable: false);
    // Everything stays tappable at every rung. Narrowing the voices would
    // change the rhythm's alphabet halfway through a round the child is part
    // way into answering, and they would be left holding a sequence that no
    // longer has anything to put in it.
    //
    // What the ladder does here instead is in the board: the gate replays the
    // rhythm slower, and at `modelled` it plays each beat with the creature
    // that makes it lit up, so the child is shown the answer and then asked to
    // perform it themselves.
    return ActivityStepView(
      prompt: step.round.prompt,
      revealLine: step.round.revealLine,
      liveOptionIds: allIds,
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.round.sequence.first : null,
    );
  }
}
