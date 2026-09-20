import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/engine/support/number_words.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

/// Everything one run of an activity needs.
class ActivitySession<TContent extends ActivityContent> {
  const ActivitySession({
    required this.spec,
    required this.content,
    required this.services,
    required this.engineId,
    required this.engineSchemaVersion,
    this.storyNodeId,
    this.seed = 0,
    this.resume,
  });

  final ActivitySpec spec;
  final TContent content;
  final ActivityServices services;

  /// The engine running this session, carried so a checkpoint can name the
  /// engine and the content schema it was written against.
  final String engineId;
  final int engineSchemaVersion;

  /// Set when the activity is running inside a story node, so telemetry can be
  /// joined back to the beat it served.
  final String? storyNodeId;

  /// The seed `services.random` was constructed from.
  ///
  /// Held here as well as inside the `Random` because a `Random` cannot be
  /// asked what seeded it, and resume depends on reproducing the exact board:
  /// a checkpoint that says "step three" is only meaningful alongside the seed
  /// that decided what step three *is*.
  final int seed;

  /// Where a previous, interrupted run of this same activity got to, or null
  /// for a fresh start. Validated by the cubit before it is honoured.
  final ActivityCheckpoint? resume;
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

  /// Seconds already spent on this activity before it was interrupted, so a
  /// resumed run reports the time the child actually spent rather than only
  /// the time since they came back.
  int _elapsedSecondsBeforeResume = 0;

  /// True when this run picked up a checkpoint rather than starting fresh.
  /// Read by tests and by the result snapshot; nothing branches on it.
  bool _didResume = false;

  bool get didResumeFromCheckpoint => _didResume;

  /// The last thing said, so the same sentence is never said twice running.
  String? _lastSpokenLine;

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
      durationSeconds:
          _elapsedSecondsBeforeResume + _stopwatch.elapsed.inSeconds,
    );
  }

  /// The cursor describing where this run is right now.
  ActivityCheckpoint _checkpoint() {
    return ActivityCheckpoint(
      activityId: spec.instanceId,
      engineId: session.engineId,
      engineSchemaVersion: session.engineSchemaVersion,
      seed: session.seed,
      stepIndex: _stepIndex,
      score: _score,
      stepsIndependent: _stepsIndependent,
      hintsUsed: _hintsUsed,
      elapsedSeconds:
          _elapsedSecondsBeforeResume + _stopwatch.elapsed.inSeconds,
      enginePayload: captureResumePayload(),
    );
  }

  /// Persists the current position.
  ///
  /// Called at every step boundary — a point where nothing is half-placed and
  /// no narration is mid-sentence — and never mid-attempt. Saving inside a
  /// step would let a child return to a board frozen part-way through a
  /// gesture they have already forgotten making.
  Future<void> _saveCheckpoint() async {
    if (state.status != ActivityStatus.running) {
      return;
    }
    await services.checkpointSink.save(_checkpoint());
  }

  /// A secondary flush, for the lifecycle callbacks that may or may not run.
  ///
  /// Everything it writes has already been written at the last step boundary.
  /// It exists so that a long step interrupted by a backgrounding keeps the
  /// score and hint counts accumulated within it, and **not** as the mechanism
  /// progress depends on: an app killed by the OS never reaches here.
  Future<void> flushCheckpoint() => _saveCheckpoint();

  /// Engine-specific board state worth restoring, or null.
  ///
  /// Overridden by nothing today, which is the intended steady state. An engine
  /// tempted to override it should first ask whether what it wants to restore
  /// is really a *step*; it usually is, and a step index is already persisted.
  /// Whatever is returned must be logical progress, never a position, an offset
  /// or a frame.
  @protected
  Map<String, dynamic>? captureResumePayload() => null;

  /// The counterpart to [captureResumePayload], called before the first emit of
  /// a resumed run.
  @protected
  void restoreResumePayload(Map<String, dynamic> payload) {}

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
    _applyResumeCheckpoint();
    _stopwatch.start();
    _emitSafely(ActivityState(
      status: ActivityStatus.running,
      engineStep: currentStep,
      languageCode: services.languageCode,
      stepIndex: _stepIndex,
      stepCount: _steps.length,
      view: describe(currentStep, ScaffoldLevel.initial),
      isBoardLocked: true,
    ));
    // Written before the first prompt, not after it. A child who opens an
    // activity and is interrupted three seconds later has still *arrived*, and
    // the story should reopen on the activity rather than on the beat before.
    await _saveCheckpoint();
    await _speakPrompt();
    _unlockBoard();
  }

  /// Restores an interrupted run, or quietly starts over.
  ///
  /// The whole no-op path is the requirement, not a fallback: a checkpoint from
  /// a different activity, a different engine, an engine whose step generation
  /// has changed, or a step index the current content no longer has, all mean
  /// the same thing. Restart **this mini-game**, keep the Adventure. The
  /// alternative — guessing — drops a four-year-old onto a step that may not
  /// exist, and the failure would look to them like the app being broken.
  void _applyResumeCheckpoint() {
    final ActivityCheckpoint? checkpoint = session.resume;
    if (checkpoint == null) {
      return;
    }
    if (!checkpoint.appliesTo(
      activityId: spec.instanceId,
      engineId: session.engineId,
      engineSchemaVersion: session.engineSchemaVersion,
      stepCount: _steps.length,
    )) {
      return;
    }
    // The seed decided what each step *is*. Resuming at step three under a
    // different seed would restore an index into a board that no longer
    // exists, which is worse than starting over because it looks like it
    // worked.
    if (checkpoint.seed != session.seed) {
      return;
    }
    _didResume = true;
    _stepIndex = checkpoint.stepIndex;
    _score = checkpoint.score;
    _stepsIndependent = checkpoint.stepsIndependent;
    _hintsUsed = checkpoint.hintsUsed;
    _elapsedSecondsBeforeResume = checkpoint.elapsedSeconds;
    final Map<String, dynamic>? payload = checkpoint.enginePayload;
    if (payload != null) {
      restoreResumePayload(payload);
    }
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

    if (attempt is TallyAttempt) {
      await _handleTally(attempt);
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
    await _settleThenAdvance(await _speakReveal());
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
    // The child still gets the clue. Withholding the story beat from the one
    // child who needed every rung of the ladder would be exactly backwards.
    await _settleThenAdvance(await _speakReveal());
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

  /// Moves to the next step, never instantaneously.
  ///
  /// When the reveal line was spoken, waiting for it is the pause. When it was
  /// skipped - an empty `revealLine`, or the same sentence as last time, which
  /// is the ordinary case for an activity whose steps share one line - `_speak`
  /// returns at once and the board would otherwise swap under the child's
  /// finger in the same frame they tapped. A beat of daylight between "you got
  /// it" and the next question is not decoration; without it the child cannot
  /// tell the two events apart.
  Future<void> _settleThenAdvance(bool didSpeak) async {
    if (!didSpeak) {
      await Future<void>.delayed(_silentStepPause);
    }
    await _advance();
  }

  /// Matches `KidUi.medium`, duplicated rather than imported: the contract
  /// layer stays free of anything that drags in a widget library.
  static const Duration _silentStepPause = Duration(milliseconds: 350);

  Future<void> _advance() async {
    if (_stepIndex >= _steps.length - 1) {
      await _finish(ActivityCompletion.completed);
      return;
    }
    _stepIndex++;
    _wrongOnStep = 0;
    _attemptsOnStep = 0;
    // The step boundary *is* the safe point, so the write happens here rather
    // than on the way out. Everything before this line is finished business:
    // the previous step was judged, scored and spoken to completion.
    await _saveCheckpoint();
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
    if (completion == ActivityCompletion.completed) {
      // The run is over, so its cursor is no longer "where the child is". Left
      // behind, it would resume a finished run the next time this node was
      // replayed. An abandoned run keeps its cursor on purpose: that is the
      // one the child is coming back to.
      await services.checkpointSink.clear();
      await services.soundboard.play(ActivitySound.celebrate);
      // Spoken once, here, and not after every step. `narration.success` is
      // the activity's closing line — "that is nine clues!" — and saying it
      // three times in a row would turn a payoff into wallpaper.
      await _speak(spec.narration.success.resolve(services.languageCode));
    }
    // Nothing celebratory when the child backed out. A fanfare for leaving
    // teaches the wrong thing and, more simply, is confusing.
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
    // A last flush before the state turns terminal, so the score and hints
    // earned inside the step in progress survive alongside the step index the
    // last boundary already stored.
    await _saveCheckpoint();
    await _finish(ActivityCompletion.abandoned);
  }

  // ------------------------------------------------------------------ helpers

  /// Says [line], unless it is word for word what was just said.
  ///
  /// Back-to-back repetition is the one narration fault a child reads as the
  /// app being broken rather than as the app being thorough. It happened on the
  /// most ordinary path there is: an activity whose steps share one prompt —
  /// sorting four animals into bins — re-spoke that prompt on entering every
  /// step, so the same sentence played four times with nothing in between.
  ///
  /// Only *consecutive* duplicates are dropped. A line that comes round again
  /// later, with other speech between, is a reminder rather than a stutter, and
  /// the help button re-speaking on demand is a different path entirely.
  /// Returns whether anything was actually spoken, which callers that gate a
  /// transition need to know: a line that was skipped provides no pause at all.
  Future<bool> _speak(String line) async {
    final String trimmed = line.trim();
    if (trimmed.isEmpty || trimmed == _lastSpokenLine) {
      return false;
    }
    _lastSpokenLine = trimmed;
    await services.narrator.speak(trimmed);
    return true;
  }

  Future<bool> _speakPrompt() async {
    final ActivityStepView? view = state.view;
    final String line = (view?.spokenPrompt ?? view?.prompt)
            ?.resolve(services.languageCode) ??
        '';
    final String fallback = spec.narration.prompt.resolve(services.languageCode);
    return _speak(line.isNotEmpty ? line : fallback);
  }

  /// Says the running count aloud as the child tags objects.
  ///
  /// Deliberately does not lock the board, record an attempt or touch the
  /// ladder. A child sweeping across five animals taps faster than any
  /// utterance finishes, and the narrator's latest-wins rule turns that into
  /// the right behaviour on its own: they hear the count land on the number
  /// they are on, not a backlog of the numbers they already passed.
  Future<void> _handleTally(TallyAttempt attempt) async {
    if (attempt.runningCount < 1) {
      return;
    }
    // Not de-duplicated: counting two of something after two of something
    // else is a real "two, two", and a child sweeping back over the same
    // object hears nothing new because the board already refused the tap.
    _lastSpokenLine = null;
    await services.narrator
        .speak(NumberWords.spoken(attempt.runningCount, services.languageCode));
  }

  Future<bool> _speakReveal() async {
    return _speak(state.view?.revealLine?.resolve(services.languageCode) ?? '');
  }

  Future<bool> _speakForLevel(ScaffoldLevel level) async {
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
    return _speak(line);
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

  /// Cleans up, **without** silencing whatever is speaking now.
  ///
  /// The distinction matters because of when this runs. A route is disposed at
  /// the end of its pop transition, roughly a third of a second after the
  /// child tapped "Next" — by which time the story beat underneath has already
  /// started its first line. An unconditional cancel here reached forward in
  /// time and cut off a sentence belonging to a screen this cubit never knew
  /// about, and it did it on the most common path through the whole Adventure.
  ///
  /// So: cancel only when this activity was still running, which is the case
  /// the cancel is actually for — a child killed mid-prompt by a system back
  /// or a route torn down under them. A finished activity has already spoken
  /// its closing line to completion and has nothing left in flight, and
  /// [abandon] cancels explicitly before it finishes.
  @override
  Future<void> close() async {
    if (state.status != ActivityStatus.finished) {
      await services.narrator.cancel();
    }
    _stopwatch.stop();
    return super.close();
  }
}
