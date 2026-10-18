import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/color_memory_constants.dart';
import '../data/models/game_state_model.dart';
import 'color_memory_event.dart';

class ColorMemoryBloc extends Bloc<ColorMemoryEvent, ColorMemoryGameState> {
  ColorMemoryBloc() : super(const ColorMemoryGameState()) {
    on<StartGameEvent>(_onStartGame);
    on<ShowSequenceEvent>(_onShowSequence);
    on<HighlightNextColorEvent>(_onHighlightNextColor);
    on<SequenceDisplayCompleteEvent>(_onSequenceDisplayComplete);
    on<PlayerTapColorEvent>(_onPlayerTapColor);
    on<CheckPlayerSequenceEvent>(_onCheckPlayerSequence);
    on<RoundSuccessEvent>(_onRoundSuccess);
    on<PlayerMistakeEvent>(_onPlayerMistake);
    on<NextRoundEvent>(_onNextRound);
    on<RestartGameEvent>(_onRestartGame);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<TimerTickEvent>(_onTimerTick);
    on<TimeExpiredEvent>(_onTimeExpired);
    on<ResetHighlightEvent>(_onResetHighlight);
    on<UpdateBestScoreEvent>(_onUpdateBestScore);

    _loadBestScore();
  }

  final Random _random = Random();
  Timer? _sequenceTimer;
  Timer? _gameTimer;

  /// Everything the bloc schedules, so it can all be called off at once.
  ///
  /// The sequence display used to be driven by bare `Future.delayed` calls,
  /// which cannot be cancelled. When a round ended those callbacks kept
  /// firing: colours went on lighting up behind the results dialog, and the
  /// extra state emissions re-triggered the dialog listener.
  final List<Timer> _scheduled = [];

  /// Bumped whenever pending work becomes stale, so a callback that survives
  /// cancellation still knows to do nothing.
  int _epoch = 0;

  void _schedule(Duration delay, void Function() action) {
    final epoch = _epoch;
    late Timer timer;
    timer = Timer(delay, () {
      _scheduled.remove(timer);
      if (isClosed || epoch != _epoch) return;
      action();
    });
    _scheduled.add(timer);
  }

  /// Stops the sequence, the countdown and every pending callback.
  void _cancelScheduled() {
    _epoch++;
    for (final timer in _scheduled) {
      timer.cancel();
    }
    _scheduled.clear();
    _gameTimer?.cancel();
    _sequenceTimer?.cancel();
  }

  Future<void> _loadBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bestScore = prefs.getInt('color_memory_best_score') ?? 0;
      add(UpdateBestScoreEvent(bestScore));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveBestScore(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('color_memory_best_score', score);
    } catch (e) {
      // Handle error silently
    }
  }

  void _onStartGame(StartGameEvent event, Emitter<ColorMemoryGameState> emit) {
    _cancelScheduled();
    final config = LevelConfig.forLevel(event.level);
    final initialSequence = _generateSequence(
      config.colorCount,
      config.initialSequenceLength,
    );

    emit(ColorMemoryGameState(
      mode: event.mode,
      level: event.level,
      sequence: initialSequence,
      score: GameScore(
        currentLevel: event.level,
        sequenceLength: config.initialSequenceLength,
      ),
      settings: state.settings,
      bestScore: state.bestScore,
    ));

    // Auto-start showing sequence after a brief pause
    _schedule(const Duration(milliseconds: 500), () {
      add(const ShowSequenceEvent());
    });
  }

  void _onShowSequence(
    ShowSequenceEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    emit(state.copyWith(
      phase: GamePhase.showingSequence,
      currentSequenceIndex: 0,
      playerSequence: [],
      highlightedColorIndex: -1,
    ));

    // Start showing the sequence
    _sequenceTimer?.cancel();
    _showNextColorInSequence();
  }

  void _showNextColorInSequence() {
    if (!isClosed) {
      if (state.currentSequenceIndex < state.sequence.length) {
        add(const HighlightNextColorEvent());
      } else {
        add(const SequenceDisplayCompleteEvent());
      }
    }
  }

  void _onHighlightNextColor(
    HighlightNextColorEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    final colorIndex = state.sequence[state.currentSequenceIndex];

    emit(state.copyWith(
      highlightedColorIndex: colorIndex,
    ));

    // Turn the highlight off, then move on to the next colour.
    _schedule(
      Duration(
        milliseconds:
            (ColorMemoryConstants.colorHighlightDuration * 1000).toInt(),
      ),
      () => add(const ResetHighlightEvent()),
    );

    _schedule(
      Duration(
        milliseconds:
            (ColorMemoryConstants.sequenceDisplayInterval * 1000).toInt(),
      ),
      () {
        if (state.phase != GamePhase.showingSequence) return;
        // The reset event has already advanced currentSequenceIndex.
        if (state.currentSequenceIndex < state.sequence.length) {
          add(const HighlightNextColorEvent());
        } else {
          add(const SequenceDisplayCompleteEvent());
        }
      },
    );
  }

  void _onResetHighlight(
    ResetHighlightEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    if (state.phase == GamePhase.showingSequence) {
      emit(state.copyWith(
        highlightedColorIndex: -1,
        currentSequenceIndex: state.currentSequenceIndex + 1,
      ));
    } else {
      emit(state.copyWith(highlightedColorIndex: -1));
    }
  }

  void _onSequenceDisplayComplete(
    SequenceDisplayCompleteEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    emit(state.copyWith(
      phase: GamePhase.playerTurn,
      currentSequenceIndex: 0,
      highlightedColorIndex: -1,
    ));

    // Start timer for timed mode
    if (state.mode == ColorMemoryGameMode.timed) {
      final config = LevelConfig.forLevel(state.level);
      _startTimer(config.timePerStep * state.sequence.length);
    }
  }

  void _startTimer(double totalTime) {
    _gameTimer?.cancel();
    double remainingTime = totalTime;

    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      remainingTime -= 0.1;
      add(TimerTickEvent(remainingTime));

      if (remainingTime <= 0) {
        timer.cancel();
        add(const TimeExpiredEvent());
      }
    });
  }

  void _onTimerTick(TimerTickEvent event, Emitter<ColorMemoryGameState> emit) {
    emit(state.copyWith(remainingTime: event.remainingTime));
  }

  void _onTimeExpired(
    TimeExpiredEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    _gameTimer?.cancel();
    final expectedColor = state.sequence[state.playerSequence.length];
    add(PlayerMistakeEvent(expectedColor, -1));
  }

  void _onPlayerTapColor(
    PlayerTapColorEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    if (state.phase != GamePhase.playerTurn) return;

    final newPlayerSequence = List<int>.from(state.playerSequence)
      ..add(event.colorIndex);

    // Highlight the tapped color briefly
    emit(state.copyWith(
      playerSequence: newPlayerSequence,
      highlightedColorIndex: event.colorIndex,
    ));

    // Reset highlight after short duration
    _schedule(ColorMemoryConstants.tapAnimationDuration, () {
      add(const ResetHighlightEvent());
    });

    // Check if this tap is correct
    final currentIndex = newPlayerSequence.length - 1;
    final expectedColor = state.sequence[currentIndex];

    if (event.colorIndex != expectedColor) {
      // Wrong color
      _gameTimer?.cancel();
      _schedule(const Duration(milliseconds: 300), () {
        add(PlayerMistakeEvent(expectedColor, event.colorIndex));
      });
    } else if (newPlayerSequence.length == state.sequence.length) {
      // Sequence complete and correct
      _gameTimer?.cancel();
      _schedule(const Duration(milliseconds: 500), () {
        add(const RoundSuccessEvent());
      });
    }
    // Otherwise continue playing
  }

  void _onCheckPlayerSequence(
    CheckPlayerSequenceEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    emit(state.copyWith(phase: GamePhase.checking));

    // This event is now handled inline in _onPlayerTapColor
  }

  void _onRoundSuccess(
    RoundSuccessEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    final newRound = state.score.currentRound + 1;
    final sequenceLength = state.sequence.length;
    final config = LevelConfig.forLevel(state.level);

    // Player is perfect if they got it right on first try (playerSequence == sequence exactly)
    final isPerfect = state.playerSequence.length == sequenceLength;

    final pointsEarned =
        sequenceLength * ColorMemoryConstants.pointsPerCorrectStep +
            (isPerfect ? ColorMemoryConstants.bonusForPerfectRound : 0);

    final newScore = state.score.copyWith(
      currentRound: newRound,
      currentScore: state.score.currentScore + pointsEarned,
      perfectRounds:
          isPerfect ? state.score.perfectRounds + 1 : state.score.perfectRounds,
      totalMoves: state.score.totalMoves + state.playerSequence.length,
      longestSequence: max(state.score.longestSequence, sequenceLength),
    );

    // Nothing may keep running underneath the results dialog.
    _cancelScheduled();

    final isLevelComplete = newRound > config.maxRounds;
    final isNewBest = newScore.currentScore > state.bestScore;
    if (isNewBest) _saveBestScore(newScore.currentScore);

    // One emit, not two. Emitting the phase and then the best score separately
    // pushed the dialog listener twice and stacked two dialogs, so dismissing
    // the top one left the game running behind the one underneath.
    emit(state.copyWith(
      phase: isLevelComplete ? GamePhase.levelComplete : GamePhase.success,
      score: newScore,
      highlightedColorIndex: -1,
      bestScore: isNewBest ? newScore.currentScore : state.bestScore,
    ));

    // Do not auto-advance; the UI advances on user action.
  }

  void _onPlayerMistake(
    PlayerMistakeEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    _cancelScheduled();

    final isNewBest = state.score.currentScore > state.bestScore;
    if (isNewBest) _saveBestScore(state.score.currentScore);

    // Single emit, for the same reason as _onRoundSuccess.
    emit(state.copyWith(
      phase: GamePhase.failure,
      errorMessage: 'Wrong color! Try again.',
      highlightedColorIndex: -1,
      bestScore: isNewBest ? state.score.currentScore : state.bestScore,
    ));
  }

  void _onNextRound(NextRoundEvent event, Emitter<ColorMemoryGameState> emit) {
    _cancelScheduled();
    final config = LevelConfig.forLevel(state.level);

    // Increase sequence length
    int newLength = state.sequence.length + 1;

    // Cap at max length
    if (newLength > ColorMemoryConstants.maxSequenceLength) {
      newLength = ColorMemoryConstants.maxSequenceLength;
    }

    // Generate new sequence
    final newSequence = _generateSequence(config.colorCount, newLength);

    // Use copyWith to preserve all state including currentRound
    emit(state.copyWith(
      sequence: newSequence,
      score: state.score.copyWith(sequenceLength: newLength),
      phase: GamePhase.waiting,
      playerSequence: [],
      highlightedColorIndex: -1,
      currentSequenceIndex: 0,
    ));

    // Auto-start the next round. This runs only because the player dismissed
    // the round dialog, so nothing plays while a dialog is up.
    _schedule(
      Duration(
        milliseconds: (ColorMemoryConstants.pauseBetweenRounds * 1000).toInt(),
      ),
      () => add(const ShowSequenceEvent()),
    );
  }

  void _onRestartGame(
    RestartGameEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    _cancelScheduled();

    add(StartGameEvent(
      mode: state.mode,
      level: state.level,
    ));
  }

  void _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    final newSettings = state.settings.copyWith(
      soundEnabled: event.soundEnabled,
      hapticsEnabled: event.hapticsEnabled,
      colorBlindMode: event.colorBlindMode,
      selectedPaletteIndex: event.selectedPaletteIndex,
    );

    emit(state.copyWith(settings: newSettings));
  }

  void _onUpdateBestScore(
    UpdateBestScoreEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    emit(state.copyWith(bestScore: event.score));
  }

  List<int> _generateSequence(int colorCount, int length) {
    return List.generate(
      length,
      (index) => _random.nextInt(colorCount),
    );
  }

  @override
  Future<void> close() {
    _cancelScheduled();
    return super.close();
  }
}
