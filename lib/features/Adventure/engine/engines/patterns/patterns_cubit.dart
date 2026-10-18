import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_content.dart';

/// One gap to fill.
///
/// A round with two holes is two steps, not one, because the no-fail ladder is
/// per step: a child who needs help with the second hole should get it there,
/// rather than having the whole round narrowed because they hesitated once.
@immutable
class PatternStep extends ActivityStep {
  const PatternStep({
    required String stepId,
    required this.round,
    required this.roundIndex,
    required this.gapOrdinal,
    required this.slotIndex,
    required this.strip,
    required this.tray,
    required this.correctItemId,
    required this.isLastGapOfRound,
    this.accentColorValue,
  }) : super(stepId);

  final PatternRound round;
  final int roundIndex;

  /// Which hole in this round, from zero.
  final int gapOrdinal;

  /// Where that hole sits in the strip.
  final int slotIndex;

  /// The strip as it stands: every authored tile, plus the gaps filled so far,
  /// with `null` at the positions still open.
  ///
  /// Carried on the step rather than accumulated in the board, so the board is
  /// a pure function of the state and a child who leaves mid-round comes back
  /// to the strip they left rather than an empty one.
  final List<String?> strip;

  /// The tiles on offer, in a stable order for the whole round.
  final List<PackItem> tray;

  final String correctItemId;

  /// True on the step that makes the pattern whole — the one the wave runs on.
  final bool isLastGapOfRound;

  /// The chapter's accent, so the board reaches for content rather than a
  /// literal of its own.
  final int? accentColorValue;

  String get slotId => 'slot_$slotIndex';

  /// The finished strip, as it will look the instant this step is answered.
  /// The board needs it to run the wave over a pattern with no holes in it.
  List<String> get completedStrip => <String>[
        for (int index = 0; index < strip.length; index++)
          index == slotIndex ? correctItemId : (strip[index] ?? round.itemIdAt(index)),
      ];
}

class PatternsCubit extends ActivityCubit<PatternsContent, PatternStep> {
  PatternsCubit(super.session);

  @override
  List<PatternStep> buildSteps() {
    final List<PatternStep> steps = <PatternStep>[];

    for (int roundIndex = 0; roundIndex < content.rounds.length; roundIndex++) {
      final PatternRound round = content.rounds[roundIndex];

      // One tray for the whole round. Reshuffling between holes would move a
      // target out from under a finger already on its way to it, and would
      // also suggest the tray means something, which it does not.
      final List<PackItem> tray = _trayFor(round);

      final List<String?> strip = round.openStrip;
      for (int ordinal = 0; ordinal < round.gaps.length; ordinal++) {
        final int slot = round.gaps[ordinal];
        steps.add(PatternStep(
          stepId: 'pattern_${round.id}_$slot',
          round: round,
          roundIndex: roundIndex,
          gapOrdinal: ordinal,
          slotIndex: slot,
          strip: List<String?>.unmodifiable(strip),
          tray: tray,
          correctItemId: round.itemIdAt(slot),
          isLastGapOfRound: ordinal == round.gaps.length - 1,
          accentColorValue: content.accentColorValue,
        ));
        strip[slot] = round.itemIdAt(slot);
      }
    }
    return steps;
  }

  /// Every distinct tile the round's gaps need, plus decoys.
  ///
  /// The correct tile for every gap is in here by construction — an invariant
  /// rather than a check, because a tray that cannot answer the question is not
  /// a harder activity, it is a stuck one.
  List<PackItem> _trayFor(PatternRound round) {
    final List<PackItem> tray = <PackItem>[];
    for (final String id in round.unitItemIds.toSet()) {
      final PackItem? item = content.itemById(id);
      if (item != null) {
        tray.add(item);
      }
    }
    final List<PackItem> decoys = content.items
        .where((PackItem item) => !round.unitItemIds.contains(item.id))
        .toList()
      ..shuffle(services.random);
    tray.addAll(decoys.take(content.trayExtraCount));
    tray.shuffle(services.random);
    return List<PackItem>.unmodifiable(tray);
  }

  @override
  ActivityJudgement judge(PatternStep step, ActivityAttempt attempt) {
    // Tap a tile, then tap the hole. The route for a child who cannot drag,
    // and judged identically — WCAG 2.2 SC 2.5.7, and the plain fact that drag
    // fails often at this age.
    if (attempt is ChoiceAttempt) {
      return attempt.optionId == step.correctItemId
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }
    if (attempt is! PlacementAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    final bool rightTile = attempt.tokenId == step.correctItemId;
    if (rightTile && attempt.targetId == step.slotId) {
      return const ActivityJudgement.correct();
    }
    // The right tile in the wrong hole is a different mistake from the wrong
    // tile, and deserves a different answer: one is aim, the other is the rule.
    if (rightTile) {
      return const ActivityJudgement.wrongSlotButRightItem();
    }
    final double? distance = attempt.droppedAtDistance;
    if (distance != null && distance < 0.25) {
      return const ActivityJudgement.wrongSlotButRightItem();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(PatternStep step, ScaffoldLevel level) {
    final List<String> allIds =
        step.tray.map((PackItem item) => item.id).toList(growable: false);
    final List<String> live = services.coach.liveOptionsFor(
      level: level,
      allOptionIds: allIds,
      correctOptionId: step.correctItemId,
      random: services.random,
    );
    return ActivityStepView(
      // The round's own wording carries the story; the generic prompt is the
      // fallback for a round that did not bother to say why it exists.
      prompt: step.round.label,
      // Only the hole that finishes the round earns the reveal. The first hole
      // of a two-hole round has not made anything happen yet, and saying it has
      // would be the app telling the child something they can see is not true.
      revealLine: step.isLastGapOfRound ? step.round.revealLine : null,
      liveOptionIds: live,
      dimmedOptionIds:
          allIds.where((String id) => !live.contains(id)).toList(growable: false),
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.correctItemId : null,
    );
  }
}
