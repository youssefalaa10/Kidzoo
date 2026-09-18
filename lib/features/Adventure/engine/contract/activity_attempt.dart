import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// What a child did on one step.
///
/// The **judged** set is capped at eight variants — the ones [ActivityCubit]
/// hands to `judge`. A ninth judged variant deserves the same scrutiny as a
/// whole new engine, because it means engines are leaking their internals into
/// the shared contract rather than expressing themselves in content.
///
/// Alongside them sit the *control* attempts — [HelpRequestedAttempt] and
/// [TallyAttempt] — which never reach `judge`, never count against the
/// no-fail ladder's attempt budget and never change the score. They are here
/// rather than on a second channel because a board already has exactly one way
/// to talk to the cubit, and giving it a second one to say "speak this" would
/// be two paths where one will do.
///
/// [TextAttempt] and [StrokeAttempt] ship with **no consumer**. That is
/// deliberate: they are the seam for Arabic literacy engines (tracing, phonics,
/// word building), which need real letterform content before they can be built.
/// Reserving them now means adding the first literacy engine is a new folder,
/// not a change to the contract every existing engine depends on.
@immutable
sealed class ActivityAttempt {
  const ActivityAttempt();
}

/// Picked one option from a set. Quizzes, pick-the-number, pick-the-picture.
@immutable
class ChoiceAttempt extends ActivityAttempt {
  const ChoiceAttempt(this.optionId);
  final String optionId;
}

/// Put a token onto a target. Sorting bins, matching pairs.
///
/// [droppedAtDistance] is the normalized distance from the target's centre when
/// released, or null when the child used tap-to-select. It is what lets the
/// base cubit tell "reached for the right bin and missed" (a motor problem)
/// from "chose the wrong bin" (a knowledge problem). Never conflate those: one
/// means bigger targets, the other means more teaching.
@immutable
class PlacementAttempt extends ActivityAttempt {
  const PlacementAttempt({
    required this.tokenId,
    required this.targetId,
    this.droppedAtDistance,
  });
  final String tokenId;
  final String targetId;
  final double? droppedAtDistance;
}

/// Ordered a set of tokens. Patterns, story ordering, sequencing.
@immutable
class SequenceAttempt extends ActivityAttempt {
  const SequenceAttempt(this.orderedTokenIds);
  final List<String> orderedTokenIds;
}

/// Stated or produced a quantity. Counting, give-N.
@immutable
class QuantityAttempt extends ActivityAttempt {
  const QuantityAttempt(this.value);
  final int value;
}

/// Tapped a point in a scene. Hidden-object searches.
@immutable
class TapPointAttempt extends ActivityAttempt {
  const TapPointAttempt(this.normalized);

  /// Both components in 0..1, relative to the scene box, so a scene works at
  /// any size and in either text direction without re-authoring.
  final Offset normalized;
}

/// Built a word or phrase from graphemes. **Reserved — no consumer in V1.**
@immutable
class TextAttempt extends ActivityAttempt {
  const TextAttempt(this.graphemes);
  final List<String> graphemes;
}

/// Traced one stroke. **Reserved — no consumer in V1.**
@immutable
class StrokeAttempt extends ActivityAttempt {
  const StrokeAttempt({required this.points, required this.strokeIndex});
  final List<Offset> points;
  final int strokeIndex;
}

/// The child asked for help rather than answering. Never counts as wrong, but
/// it does advance the scaffold ladder so asking twice gets real help.
///
/// A **control** attempt: never judged.
@immutable
class HelpRequestedAttempt extends ActivityAttempt {
  const HelpRequestedAttempt();
}

/// The child tagged one more object while counting. A **control** attempt.
///
/// Counting out loud is the activity, not a step toward it: the one-to-one
/// principle needs the child to hear each object land on a number as they touch
/// it. The board cannot say that itself — it has no narrator, deliberately — so
/// it reports the running total and the cubit speaks it.
///
/// It is explicitly *not* an answer. It is not judged, not recorded, does not
/// advance the ladder and does not lock the board, because a child sweeping
/// across five animals must not be throttled by narration between taps.
@immutable
class TallyAttempt extends ActivityAttempt {
  const TallyAttempt(this.runningCount);

  /// How many distinct objects are now tagged, counting from one.
  final int runningCount;
}
