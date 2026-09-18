import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// How much help the child is currently being given on a step.
///
/// The ladder is owned by the base cubit, never by an engine. Engines describe
/// a step *at* a level; they do not decide when to escalate.
enum ScaffoldLevel {
  /// First presentation. Errorless by design: content should offer so few
  /// plausible wrong answers that a mistake is nearly impossible.
  initial,

  /// One wrong attempt. Nothing is removed; the first hint is spoken.
  gentleRetry,

  /// Two wrong. The option set narrows to the correct answer plus one
  /// distractor. The second hint is spoken.
  narrowed,

  /// Three wrong. The correct action is demonstrated, then re-offered with only
  /// the correct option live so the child still performs it themselves.
  modelled,
}

/// One unit of work inside an activity: a question, a round, a placement.
///
/// Engines subclass this with whatever they need. The base cubit only requires
/// a stable [stepId] so attempts can be recorded against it.
@immutable
abstract class ActivityStep {
  const ActivityStep(this.stepId);
  final String stepId;
}

/// What the host should show for a step right now.
///
/// This is the whole of an engine's say over presentation: a prompt, optional
/// narration override, and the ids that are still live. Everything else — the
/// shell, the top bar, the banner, the result view — belongs to the host.
@immutable
class ActivityStepView {
  const ActivityStepView({
    required this.prompt,
    this.spokenPrompt,
    this.liveOptionIds = const <String>[],
    this.dimmedOptionIds = const <String>[],
    this.highlightOptionId,
  });

  final LocalizedText prompt;

  /// Spoken instead of [prompt] when the written and heard forms differ.
  final LocalizedText? spokenPrompt;

  /// Ids the child can still act on. Shrinks as the scaffold ladder narrows.
  final List<String> liveOptionIds;

  /// Ids shown but no longer actionable. They **keep their slot** so the tray
  /// does not reflow under a finger that is already moving.
  final List<String> dimmedOptionIds;

  /// Set at [ScaffoldLevel.modelled] so the board can demonstrate.
  final String? highlightOptionId;
}

/// The verdict on one attempt. Pure data returned by a pure function.
@immutable
class ActivityJudgement {
  const ActivityJudgement({
    required this.outcome,
    this.isStepComplete = false,
  });

  const ActivityJudgement.correct() : this(outcome: AttemptOutcome.correct, isStepComplete: true);

  const ActivityJudgement.wrongItem() : this(outcome: AttemptOutcome.wrongItem);

  const ActivityJudgement.wrongSlotButRightItem()
      : this(outcome: AttemptOutcome.wrongSlotButRightItem);

  final AttemptOutcome outcome;

  /// Whether the step is finished. Usually equal to `outcome == correct`, but a
  /// multi-placement step stays open until every token lands.
  final bool isStepComplete;

  bool get isCorrect => outcome == AttemptOutcome.correct;
}

/// Why an attempt was not correct.
///
/// The motor/knowledge split is the point. A child who keeps dropping the right
/// item next to the right bin needs bigger targets; a child who picks the wrong
/// bin needs more teaching. Reporting both as "wrong" loses the distinction
/// that would tell you which.
enum AttemptOutcome {
  correct,

  /// Chose the wrong thing. A knowledge signal.
  wrongItem,

  /// Chose the right thing but missed the target. A motor signal.
  wrongSlotButRightItem,

  /// Asked for help instead of answering.
  helpRequested,
}
