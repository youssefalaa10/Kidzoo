import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_content.dart';

/// One board to get across.
@immutable
class CurrentRiderStep extends ActivityStep {
  const CurrentRiderStep({
    required String stepId,
    required this.round,
    required this.roundIndex,
    required this.roundCount,
    required this.riderImage,
    required this.goalImage,
    required this.rockImage,
    this.accentColorValue,
  }) : super(stepId);

  final CurrentRound round;
  final int roundIndex;
  final int roundCount;
  final String riderImage;
  final String goalImage;
  final String rockImage;
  final int? accentColorValue;

  /// How far down the descent this board is, 0..1.
  ///
  /// The board draws the water darker as it rises, so getting through one is
  /// visibly getting deeper rather than scoring a point. That is the world
  /// reacting, and it is why this engine needs no progress bar.
  double get depth => roundCount <= 1 ? 1 : roundIndex / (roundCount - 1);

  bool get isLast => roundIndex == roundCount - 1;

  /// How a board reports a configuration back to the cubit: one token per
  /// gate, `gateId=direction`, in the gate order content declared.
  static List<String> tokensFor(
      CurrentRound round, Map<String, Drift> setting) {
    return <String>[
      for (final CurrentGate gate in round.gates)
        '${gate.id}=${(setting[gate.id] ?? gate.initial).name}',
    ];
  }

  /// The inverse. Unknown gates and unparseable directions fall back to what
  /// the gate was already set to, so a malformed attempt is judged as "that
  /// did not work" rather than throwing under a four-year-old.
  Map<String, Drift> settingFrom(List<String> tokens) {
    final Map<String, Drift> setting =
        Map<String, Drift>.of(round.initialSetting);
    for (final String token in tokens) {
      final int split = token.indexOf('=');
      if (split <= 0) {
        continue;
      }
      final String gateId = token.substring(0, split);
      final String direction = token.substring(split + 1);
      if (!setting.containsKey(gateId)) {
        continue;
      }
      for (final Drift flow in Drift.values) {
        if (flow.name == direction) {
          setting[gateId] = flow;
          break;
        }
      }
    }
    return setting;
  }
}

class CurrentRiderCubit
    extends ActivityCubit<CurrentRiderContent, CurrentRiderStep> {
  CurrentRiderCubit(super.session);

  @override
  List<CurrentRiderStep> buildSteps() {
    return <CurrentRiderStep>[
      for (int index = 0; index < content.rounds.length; index++)
        CurrentRiderStep(
          stepId: 'ride_${content.rounds[index].id}',
          round: content.rounds[index],
          roundIndex: index,
          roundCount: content.rounds.length,
          riderImage: content.riderImage,
          goalImage: content.goalImage,
          rockImage: content.rockImage,
          accentColorValue: content.accentColorValue,
        ),
    ];
  }

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  @override
  ActivityJudgement judge(CurrentRiderStep step, ActivityAttempt attempt) {
    if (attempt is! SequenceAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    // The rules are one call to a pure function that content already proved
    // has an answer. Nothing here knows what water is — it walks a grid.
    final Ride ride =
        step.round.ride(step.settingFrom(attempt.orderedTokenIds));
    if (ride.arrived) {
      return const ActivityJudgement.correct();
    }
    // Going round in circles is a different mistake from driving into a rock:
    // one is a child who has not read the gate they are standing on, the other
    // is a child who has read it and aimed badly. Both come back to the last
    // safe water, and only the reporting tells them apart.
    return ride.outcome == RideOutcome.circled
        ? const ActivityJudgement.wrongItem()
        : const ActivityJudgement.wrongSlotButRightItem();
  }

  @override
  ActivityStepView describe(CurrentRiderStep step, ScaffoldLevel level) {
    final List<String> gateIds = step.round.gates
        .map((CurrentGate gate) => gate.id)
        .toList(growable: false);
    // Nothing is taken away as the ladder climbs — a gate that vanished would
    // change the board the child is reasoning about, which is worse than being
    // stuck on it.
    //
    // There is deliberately no `highlightOptionId` here either. Which gate is
    // wrong depends on how the child has already turned them, and the cubit
    // cannot know that: the setting lives on the board, and `judge` is pure so
    // it cannot quietly remember the last one. The board asks
    // [CurrentRound.gateToTurn] with the setting it is actually showing, which
    // is the only place the true answer exists. A hint computed from the
    // opening setting would point at a gate the child had already fixed.
    return ActivityStepView(
      prompt: step.round.prompt,
      revealLine: step.round.revealLine,
      liveOptionIds: gateIds,
    );
  }
}
