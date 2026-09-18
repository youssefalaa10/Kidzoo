import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// What a child did on one step.
///
/// The set is capped at eight variants. A ninth deserves the same scrutiny as a
/// whole new engine, because it means engines are leaking their internals into
/// the shared contract rather than expressing themselves in content.
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
@immutable
class HelpRequestedAttempt extends ActivityAttempt {
  const HelpRequestedAttempt();
}
