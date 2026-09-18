import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

/// Everything one run of an activity needs.
class ActivitySession<TContent extends ActivityContent> {
  const ActivitySession({
    required this.spec,
    required this.content,
    required this.services,
    this.storyNodeId,
  });

  final ActivitySpec spec;
  final TContent content;
  final ActivityServices services;

  /// Set when the activity is running inside a story node, so telemetry can be
  /// joined back to the beat it served.
  final String? storyNodeId;
}

/// The base every engine cubit extends.
///
/// An engine supplies **three** methods — [buildSteps], [judge], [describe] —
/// and inherits the entire lifecycle: the step cursor, attempt counting, the
/// no-fail ladder, narration sequencing, scoring, telemetry, close guards and
/// result assembly. That division is the correction to the `quiz_engine_screen`
/// failure: what gets shared is the machinery and the chrome, never the board.
///
/// [judge] must be **pure**. No emit, no await, no service calls. It is the one
/// place an engine's rules live, and keeping it pure is what makes those rules
/// testable as a table rather than as a widget.
abstract class ActivityCubit<TContent extends ActivityContent,
    TStep extends ActivityStep> extends Cubit<ActivityState> {
  ActivityCubit(this.session)
      : super(const ActivityState(status: ActivityStatus.loading));

  final ActivitySession<TContent> session;

  TContent get content => session.content;
  ActivityServices get services => session.services;
  ActivitySpec get spec => session.spec;

  late List<TStep> _steps;
  final Stopwatch _stopwatch = Stopwatch();

  int _stepIndex = 0;
  int _wrongOnStep = 0;
  int _attemptsOnStep = 0;
  int _score = 0;
  int _stepsIndependent = 0;
  int _hintsUsed = 0;
  bool _hasStarted = false;

  // ---------------------------------------------------------------- engine API

  /// Build every step once, up front. May use `services.random`, which is
  /// injected and seeded, so the same seed always yields the same activity.
  List<TStep> buildSteps();

  /// Decide whether [attempt] satisfies [step]. **Pure.**
  ActivityJudgement judge(TStep step, ActivityAttempt attempt);

  /// Describe [step] at [level]. Called again after every escalation.
  ActivityStepView describe(TStep step, ScaffoldLevel level);

  /// Optional: assets the host should precache before the first frame.
  Iterable<String> get assetsToPrecache => const <String>[];

  // -------------------------------------------------------------------- driver

  TStep get currentStep => _steps[_stepIndex];

  /// The result *so far*.
  ///
  /// Recomputed on every emit rather than only at the end: the top bar shows a
  /// live score, and a story node that is interrupted still has a truthful
  /// snapshot to persist.
  ActivityResult _snapshotResult({
    ActivityCompletion completion = ActivityCompletion.inProgress,
  }) {
    return ActivityResult(
      completion: completion,
      score: _score,
      maxScore: _hasStarted && _steps.isNotEmpty ? _steps.length * 10 : 0,
      stepsTotal: _hasStarted && _steps.isNotEmpty ? _steps.length : 0,
      stepsIndependent: _stepsIndependent,
      hintsUsed: _hintsUsed,
      durationSeconds: _stopwatch.elapsed.inSeconds,
    );
  }

  Future<void> start() async {
    if (_hasStarted) {
      return;
    }
    _hasStarted = true;
    try {
      _steps = buildSteps();
    } on ActivityContentException catch (error) {
      _emitSafely(ActivityState(
        status: ActivityStatus.contentError,
        errorMessage: error.toString(),
      ));
      return;
    }
    if (_steps.isEmpty) {
      _emitSafely(const ActivityState(
        status: ActivityStatus.contentError,
        errorMessage: 'the activity produced no steps',
      ));
      return;
    }
    _stopwatch.start();
    _emitSafely(ActivityState(
      status: ActivityStatus.running,
      engineStep: currentStep,
      languageCode: services.languageCode,
      stepCount: _steps.length,
      view: describe(currentStep, ScaffoldLevel.initial),
      isBoardLocked: true,
    ));
    await _speakPrompt();
    _unlockBoard();
  }

  /// The single entry point for everything the child does.
  Future<void> submit(ActivityAttempt attempt) async {
    if (isClosed || state.status != ActivityStatus.running) {
      return;
    }
    if (state.isBoardLocked) {
      return;
    }

    if (attempt is HelpRequestedAttempt) {
      await _handleHelpRequest();
      return;
    }

    _attemptsOnStep++;
    final ActivityJudgement judgement = judge(currentStep, attempt);
    await _recordAttempt(judgement.outcome);

    if (judgement.isCorrect) {
      await _handleCorrect(judgement, attempt);
      return;
    }
    await _handleWrong(judgement, attempt);
  }

  Future<void> _handleCorrect(
    ActivityJudgement judgement,
    ActivityAttempt attempt,
  ) async {
    _score += services.coach.pointsForStep(_wrongOnStep);
    if (_wrongOnStep == 0) {
      _stepsIndependent++;
    }
    _emitSafely(state.copyWith(
      isBoardLocked: true,
      lastOutcome: AttemptOutcome.correct,
      lastAttemptedOptionId: _optionIdOf(attempt),
    ));
    await services.soundboard.play(ActivitySound.success);

    if (!judgement.isStepComplete) {
      _unlockBoard();
      return;
    }
    await _advance();
  }

  Future<void> _handleWrong(
    ActivityJudgement judgement,
    ActivityAttempt attempt,
  ) async {
    // The ladder has to terminate unconditionally, not just for engines whose
    // attempt type happens to match what the board sends. Once the correct
    // action has been modelled and the child acts anyway, the step is credited
    // and the story moves on.
    //
    // This is what makes "every child who reaches the last step completes" a
    // guarantee rather than an aspiration. Without it, one mismatched attempt
    // type is enough to trap a four-year-old on a step they cannot pass, and
    // they would meet that as the app being broken.
    if (_wrongOnStep >= _wrongAttemptsBeforeCredit) {
      await _creditStepAfterModelling(attempt);
      return;
    }

    _wrongOnStep++;
    _hintsUsed++;
    final ScaffoldLevel level = services.coach.levelFor(_wrongOnStep);
    final bool demonstrating = services.coach.shouldModel(level);

    _emitSafely(state.copyWith(
      isBoardLocked: true,
      scaffoldLevel: level,
      wrongAttemptsOnStep: _wrongOnStep,
      view: describe(currentStep, level),
      isDemonstrating: demonstrating,
      lastOutcome: judgement.outcome,
      lastAttemptedOptionId: _optionIdOf(attempt),
    ));

    // Errorless: an encouraging sound, never a buzzer, and no score change.
    await services.soundboard.play(ActivitySound.gentle);
    await _speakForLevel(level);

    if (isClosed) {
      return;
    }
    // At `modelled` the correct action has just been demonstrated; the step is
    // then re-offered with only the correct option live, so the child still
    // performs it themselves rather than watching it happen.
    _emitSafely(state.copyWith(isDemonstrating: false, isBoardLocked: false));
  }

  /// Wrong attempts allowed before the step is simply credited.
  ///
  /// Three: gentle retry, narrowed, modelled. The fourth attempt lands after
  /// the correct action has been demonstrated.
  static const int _wrongAttemptsBeforeCredit = 3;

  /// Credits a step the child could not complete even after modelling.
  ///
  /// Scored at the minimum, never zero, and recorded as *not* independent so
  /// the mastery signal stays honest — the parent report and the adaptive nudge
  /// still see that this step needed everything the coach had.
  Future<void> _creditStepAfterModelling(ActivityAttempt attempt) async {
    _score += services.coach.pointsForStep(_wrongOnStep);
    _emitSafely(state.copyWith(
      isBoardLocked: true,
      isDemonstrating: false,
      lastOutcome: AttemptOutcome.correct,
      lastAttemptedOptionId: _optionIdOf(attempt),
    ));
    await services.soundboard.play(ActivitySound.success);
    await _advance();
  }

  Future<void> _handleHelpRequest() async {
    _hintsUsed++;
    final ScaffoldLevel level = services.coach.levelFor(_wrongOnStep + 1);
    _emitSafely(state.copyWith(
      isBoardLocked: true,
      scaffoldLevel: level,
      view: describe(currentStep, level),
      lastOutcome: AttemptOutcome.helpRequested,
    ));
    await _recordAttempt(AttemptOutcome.helpRequested);
    await _speakForLevel(level);
    _unlockBoard();
  }

  Future<void> _advance() async {
    if (_stepIndex >= _steps.length - 1) {
      await _finish(ActivityCompletion.completed);
      return;
    }
    _stepIndex++;
    _wrongOnStep = 0;
    _attemptsOnStep = 0;
    _emitSafely(state.copyWith(
      stepIndex: _stepIndex,
      engineStep: currentStep,
      scaffoldLevel: ScaffoldLevel.initial,
      wrongAttemptsOnStep: 0,
      view: describe(currentStep, ScaffoldLevel.initial),
      isBoardLocked: true,
      isDemonstrating: false,
      clearLastOutcome: true,
      clearLastAttemptedOptionId: true,
    ));
    await _speakPrompt();
    _unlockBoard();
  }

  Future<void> _finish(ActivityCompletion completion) async {
    _stopwatch.stop();
    await services.soundboard.play(ActivitySound.celebrate);
    _emitSafely(state.copyWith(
      status: ActivityStatus.finished,
      isBoardLocked: true,
      isDemonstrating: false,
      result: _snapshotResult(completion: completion),
    ));
  }

  /// Ends the run early — the child backed out. Still not a failure: the story
  /// simply does not advance.
  Future<void> abandon() async {
    if (isClosed || state.status == ActivityStatus.finished) {
      return;
    }
    await services.narrator.cancel();
    await _finish(ActivityCompletion.abandoned);
  }

  // ------------------------------------------------------------------ helpers

  Future<void> _speakPrompt() async {
    final ActivityStepView? view = state.view;
    final String line = (view?.spokenPrompt ?? view?.prompt)
            ?.resolve(services.languageCode) ??
        '';
    final String fallback = spec.narration.prompt.resolve(services.languageCode);
    await services.narrator.speak(line.isNotEmpty ? line : fallback);
  }

  Future<void> _speakForLevel(ScaffoldLevel level) async {
    final String line;
    switch (level) {
      case ScaffoldLevel.gentleRetry:
        line = spec.narration.hint1.resolve(services.languageCode);
        break;
      case ScaffoldLevel.narrowed:
        line = spec.narration.hint2.resolve(services.languageCode);
        break;
      case ScaffoldLevel.modelled:
        line = spec.narration.model.resolve(services.languageCode);
        break;
      case ScaffoldLevel.initial:
        line = '';
        break;
    }
    if (line.isNotEmpty) {
      await services.narrator.speak(line);
    }
  }

  Future<void> _recordAttempt(AttemptOutcome outcome) async {
    await services.attemptSink.record(ActivityAttemptRecord(
      activityId: spec.instanceId,
      stepIndex: _stepIndex,
      attemptIndex: _attemptsOnStep,
      outcome: outcome,
      scaffoldLevel: services.coach.levelFor(_wrongOnStep),
      elapsedMilliseconds: _stopwatch.elapsedMilliseconds,
      storyNodeId: session.storyNodeId,
    ));
  }

  String? _optionIdOf(ActivityAttempt attempt) {
    if (attempt is ChoiceAttempt) {
      return attempt.optionId;
    }
    if (attempt is PlacementAttempt) {
      return attempt.tokenId;
    }
    return null;
  }

  void _unlockBoard() {
    if (state.status == ActivityStatus.running) {
      _emitSafely(state.copyWith(isBoardLocked: false));
    }
  }

  /// Every emit goes through here. Narration is awaited between emits, so a
  /// child who leaves mid-sentence would otherwise emit after close.
  void _emitSafely(ActivityState next) {
    if (isClosed) {
      return;
    }
    // A caller that already set a terminal result keeps it; everything else
    // gets the running snapshot.
    final ActivityState withResult =
        next.result.completion == ActivityCompletion.inProgress
            ? next.copyWith(result: _snapshotResult())
            : next;
    emit(withResult);
  }

  @override
  Future<void> close() async {
    await services.narrator.cancel();
    _stopwatch.stop();
    return super.close();
  }
}
