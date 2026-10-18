import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_content.dart';

/// One card to set aside under one clue.
///
/// A clue that rules out three candidates is three steps, so the ladder
/// works per decision rather than per clue — a child stuck on the third card
/// gets help with that card, not with the two they already did.
@immutable
class DeductionStep extends ActivityStep {
  const DeductionStep({
    required String stepId,
    required this.content,
    required this.clueIndex,
    required this.isLastOfClue,
  }) : super(stepId);

  final DeductionContent content;
  final int clueIndex;

  /// True on the step that finishes applying this clue, which is when its
  /// reveal line is spoken.
  final bool isLastOfClue;

  DeductionClue get clue => content.clues[clueIndex];
}

class DeductionCubit extends ActivityCubit<DeductionContent, DeductionStep> {
  DeductionCubit(super.session);

  /// Set aside so far, in the order the child chose.
  final List<String> _setAside = <String>[];

  List<String> get setAsideIds => List<String>.unmodifiable(_setAside);

  @override
  List<DeductionStep> buildSteps() {
    final List<DeductionStep> steps = <DeductionStep>[];
    for (int clue = 0; clue < content.clues.length; clue++) {
      final int count = content.ruledOutBy(clue).length;
      for (int index = 0; index < count; index++) {
        steps.add(DeductionStep(
          stepId: 'clue_${content.clues[clue].id}_${index + 1}',
          content: content,
          clueIndex: clue,
          isLastOfClue: index == count - 1,
        ));
      }
    }
    return steps;
  }

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  /// Those this clue rules out that are still on the board.
  List<String> _stillToSetAside(DeductionStep step) => <String>[
        for (final PackItem item in content.ruledOutBy(step.clueIndex))
          if (!_setAside.contains(item.id)) item.id,
      ];

  List<String> get _standing => <String>[
        for (final PackItem item in content.candidates)
          if (!_setAside.contains(item.id)) item.id,
      ];

  @override
  ActivityJudgement judge(DeductionStep step, ActivityAttempt attempt) {
    if (attempt is ChoiceAttempt &&
        _stillToSetAside(step).contains(attempt.optionId)) {
      return const ActivityJudgement.correct();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  bool onStepCompleted(
    DeductionStep step,
    ActivityAttempt attempt, {
    required bool credited,
  }) {
    final List<String> pending = _stillToSetAside(step);
    final String id = !credited &&
            attempt is ChoiceAttempt &&
            pending.contains(attempt.optionId)
        ? attempt.optionId
        : pending.first;
    _setAside.add(id);
    return true;
  }

  @override
  ActivityStepView describe(DeductionStep step, ScaffoldLevel level) {
    final List<String> pending = _stillToSetAside(step);
    final List<String> standing = _standing;
    final bool clueDone = pending.isEmpty;
    return ActivityStepView(
      prompt: step.clue.label,
      revealLine: clueDone && step.isLastOfClue ? step.clue.revealLine : null,
      liveOptionIds: pending.isEmpty
          ? standing
          : services.coach.liveOptionsFor(
              level: level,
              allOptionIds: standing,
              correctOptionId: pending.first,
              random: services.random,
            ),
      dimmedOptionIds: List<String>.unmodifiable(_setAside),
      highlightOptionId:
          level == ScaffoldLevel.modelled && pending.isNotEmpty
              ? pending.first
              : null,
    );
  }

  @override
  Map<String, dynamic>? captureResumePayload() =>
      <String, dynamic>{'setAside': List<String>.of(_setAside)};

  @override
  void restoreResumePayload(Map<String, dynamic> payload) {
    final Object? raw = payload['setAside'];
    if (raw is! List) {
      return;
    }
    final Set<String> known = <String>{
      for (final PackItem item in content.candidates) item.id,
    };
    for (final Object? id in raw) {
      if (id is String && known.contains(id) && !_setAside.contains(id)) {
        _setAside.add(id);
      }
    }
  }
}
