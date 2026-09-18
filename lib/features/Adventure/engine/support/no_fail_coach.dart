import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';

/// The escalation ladder, owned by the base cubit so **no engine implements
/// its own**. That is the single biggest source of drift between the existing
/// games: each invented its own idea of what a wrong answer costs.
///
/// The regime is errorless. Structuring acquisition so the learner rarely errs
/// produces faster, more extinction-resistant learning, and the reference
/// products for this age — Sago Mini, Busy Shapes — have no points, no levels
/// and no failure state at all. So a wrong attempt here never subtracts, never
/// buzzes, and never ends anything. It only adds help.
@immutable
class NoFailCoach {
  const NoFailCoach({this.minimumPointsPerStep = 4});

  /// Never zero. Reaching the end of a step is worth something even if every
  /// attempt needed help; the house rule already exists as
  /// `kSorterMinRoundScore = 4`.
  final int minimumPointsPerStep;

  /// Points for a step completed after [wrongAttempts] wrong tries.
  int pointsForStep(int wrongAttempts) {
    const int full = 10;
    final int scored = full - (wrongAttempts * 3);
    return max(minimumPointsPerStep, scored);
  }

  /// The level a step is at after [wrongAttempts] wrong attempts.
  ScaffoldLevel levelFor(int wrongAttempts) {
    if (wrongAttempts <= 0) {
      return ScaffoldLevel.initial;
    }
    if (wrongAttempts == 1) {
      return ScaffoldLevel.gentleRetry;
    }
    if (wrongAttempts == 2) {
      return ScaffoldLevel.narrowed;
    }
    return ScaffoldLevel.modelled;
  }

  /// Which option ids stay live at [level].
  ///
  /// Options removed from the live set are **not** removed from the board: they
  /// keep their slot and fade, so a tray does not reflow under a finger that is
  /// already moving. That behaviour already exists in `KidPickCard`'s `done`
  /// state and is preserved here.
  ///
  /// [correctOptionId] is always live — that is what makes the ladder
  /// terminate rather than trap a child on a step they cannot pass.
  List<String> liveOptionsFor({
    required ScaffoldLevel level,
    required List<String> allOptionIds,
    required String correctOptionId,
    required Random random,
  }) {
    assert(allOptionIds.contains(correctOptionId),
        'the correct option must be among the options');
    switch (level) {
      case ScaffoldLevel.initial:
      case ScaffoldLevel.gentleRetry:
        return List<String>.of(allOptionIds);
      case ScaffoldLevel.narrowed:
        if (allOptionIds.length <= 2) {
          return List<String>.of(allOptionIds);
        }
        final List<String> distractors = allOptionIds
            .where((String id) => id != correctOptionId)
            .toList(growable: true);
        final String keptDistractor =
            distractors[random.nextInt(distractors.length)];
        // Preserve the board's original order so nothing jumps position.
        return allOptionIds
            .where((String id) => id == correctOptionId || id == keptDistractor)
            .toList(growable: false);
      case ScaffoldLevel.modelled:
        return <String>[correctOptionId];
    }
  }

  /// Whether the correct action should be demonstrated before the child acts.
  bool shouldModel(ScaffoldLevel level) => level == ScaffoldLevel.modelled;
}
