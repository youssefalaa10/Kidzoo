import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';

/// How an activity ended.
///
/// There is no `failed`. **Every child who reaches the last step completes**,
/// regardless of how much help they needed, because the story must never be
/// gated on performance. Mastery signals live alongside this, in
/// [ActivityResult], and feed adaptation and the parent report — they never
/// branch the narrative.
enum ActivityCompletion { inProgress, completed, abandoned }

/// The outcome the story reads.
@immutable
class ActivityResult {
  const ActivityResult({
    required this.completion,
    required this.score,
    required this.maxScore,
    required this.stepsTotal,
    required this.stepsIndependent,
    required this.hintsUsed,
    required this.durationSeconds,
  });

  const ActivityResult.empty()
      : completion = ActivityCompletion.inProgress,
        score = 0,
        maxScore = 0,
        stepsTotal = 0,
        stepsIndependent = 0,
        hintsUsed = 0,
        durationSeconds = 0;

  final ActivityCompletion completion;
  final int score;
  final int maxScore;
  final int stepsTotal;

  /// Steps answered correctly on the first attempt. The real mastery signal.
  final int stepsIndependent;

  final int hintsUsed;
  final int durationSeconds;

  /// 0..1, used only for adaptation and reporting — never to gate the story.
  double get masterySignal =>
      stepsTotal == 0 ? 0 : stepsIndependent / stepsTotal;
}

/// The state an [ActivityBoard] renders.
@immutable
class ActivityState {
  const ActivityState({
    required this.status,
    this.engineStep,
    this.languageCode = 'en',
    this.stepIndex = 0,
    this.stepCount = 0,
    this.view,
    this.scaffoldLevel = ScaffoldLevel.initial,
    this.wrongAttemptsOnStep = 0,
    this.isBoardLocked = false,
    this.isDemonstrating = false,
    this.lastOutcome,
    this.lastAttemptedOptionId,
    this.result = const ActivityResult.empty(),
    this.errorMessage,
  });

  final ActivityStatus status;

  /// The engine's own step object for the current position.
  ///
  /// Typed as [Object] because the state is shared by every engine; each board
  /// casts it back to its own step type. Carrying it here rather than reading
  /// it off the cubit keeps the board a pure function of the state, which is
  /// what makes boards testable by pumping a state rather than a whole engine.
  final Object? engineStep;

  /// The locale the child is playing in, so a board can format digits and pick
  /// a text direction without reaching for an inherited widget.
  final String languageCode;

  final int stepIndex;
  final int stepCount;

  /// What the current engine wants shown. Null before the first step is built.
  final ActivityStepView? view;

  final ScaffoldLevel scaffoldLevel;
  final int wrongAttemptsOnStep;

  /// True while narration or feedback is playing. The board must ignore input:
  /// a child tapping through a hint would otherwise burn the ladder.
  final bool isBoardLocked;

  /// True while the correct action is being demonstrated at `modelled`.
  final bool isDemonstrating;

  final AttemptOutcome? lastOutcome;
  final String? lastAttemptedOptionId;
  final ActivityResult result;
  final String? errorMessage;

  bool get isFinished => status == ActivityStatus.finished;

  double get progress => stepCount == 0 ? 0 : stepIndex / stepCount;

  ActivityState copyWith({
    ActivityStatus? status,
    Object? engineStep,
    String? languageCode,
    int? stepIndex,
    int? stepCount,
    ActivityStepView? view,
    ScaffoldLevel? scaffoldLevel,
    int? wrongAttemptsOnStep,
    bool? isBoardLocked,
    bool? isDemonstrating,
    AttemptOutcome? lastOutcome,
    bool clearLastOutcome = false,
    String? lastAttemptedOptionId,
    bool clearLastAttemptedOptionId = false,
    ActivityResult? result,
    String? errorMessage,
  }) {
    return ActivityState(
      status: status ?? this.status,
      engineStep: engineStep ?? this.engineStep,
      languageCode: languageCode ?? this.languageCode,
      stepIndex: stepIndex ?? this.stepIndex,
      stepCount: stepCount ?? this.stepCount,
      view: view ?? this.view,
      scaffoldLevel: scaffoldLevel ?? this.scaffoldLevel,
      wrongAttemptsOnStep: wrongAttemptsOnStep ?? this.wrongAttemptsOnStep,
      isBoardLocked: isBoardLocked ?? this.isBoardLocked,
      isDemonstrating: isDemonstrating ?? this.isDemonstrating,
      lastOutcome: clearLastOutcome ? null : (lastOutcome ?? this.lastOutcome),
      lastAttemptedOptionId: clearLastAttemptedOptionId
          ? null
          : (lastAttemptedOptionId ?? this.lastAttemptedOptionId),
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum ActivityStatus { loading, running, finished, contentError }
