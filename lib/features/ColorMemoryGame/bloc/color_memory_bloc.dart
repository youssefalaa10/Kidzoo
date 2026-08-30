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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isClosed) {
        add(const ShowSequenceEvent());
      }
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

    // Schedule reset and next color display using events
    Future.delayed(
      Duration(
        milliseconds:
            (ColorMemoryConstants.colorHighlightDuration * 1000).toInt(),
      ),
      () {
        if (!isClosed) {
          add(const ResetHighlightEvent());
        }
      },
    );

    // Schedule next color display
    Future.delayed(
      Duration(
        milliseconds:
            (ColorMemoryConstants.sequenceDisplayInterval * 1000).toInt(),
      ),
      () {
        if (!isClosed && state.phase == GamePhase.showingSequence) {
          // After the reset event has incremented currentSequenceIndex,
          // check the current index against the sequence length.
          if (state.currentSequenceIndex < state.sequence.length) {
            add(const HighlightNextColorEvent());
          } else {
            add(const SequenceDisplayCompleteEvent());
          }
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
    Future.delayed(ColorMemoryConstants.tapAnimationDuration, () {
      add(const ResetHighlightEvent());
    });

    // Check if this tap is correct
    final currentIndex = newPlayerSequence.length - 1;
    final expectedColor = state.sequence[currentIndex];

    if (event.colorIndex != expectedColor) {
      // Wrong color
      _gameTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 300), () {
        add(PlayerMistakeEvent(expectedColor, event.colorIndex));
      });
    } else if (newPlayerSequence.length == state.sequence.length) {
      // Sequence complete and correct
      _gameTimer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
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

    // Ensure no timers/highlights run under dialogs
    _gameTimer?.cancel();
    _sequenceTimer?.cancel();

    // Check if level is complete
    final isLevelComplete = newRound > config.maxRounds;

    emit(state.copyWith(
      phase: isLevelComplete ? GamePhase.levelComplete : GamePhase.success,
      score: newScore,
      highlightedColorIndex: -1,
    ));

    // Update best score if needed
    if (newScore.currentScore > state.bestScore) {
      _saveBestScore(newScore.currentScore);
      emit(state.copyWith(bestScore: newScore.currentScore));
    }

    // Do not auto-advance; UI will advance on user action
  }

  void _onPlayerMistake(
    PlayerMistakeEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    // Stop any timers/highlights and clear highlight
    _gameTimer?.cancel();
    _sequenceTimer?.cancel();

    emit(state.copyWith(
      phase: GamePhase.failure,
      errorMessage: 'Wrong color! Try again.',
      highlightedColorIndex: -1,
    ));

    // Check if this is a high score
    if (state.score.currentScore > state.bestScore) {
      _saveBestScore(state.score.currentScore);
      emit(state.copyWith(bestScore: state.score.currentScore));
    }
  }

  void _onNextRound(NextRoundEvent event, Emitter<ColorMemoryGameState> emit) {
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

    // Auto-start next round
    Future.delayed(
      Duration(
        milliseconds: (ColorMemoryConstants.pauseBetweenRounds * 1000).toInt(),
      ),
      () {
        if (!isClosed) {
          add(const ShowSequenceEvent());
        }
      },
    );
  }

  void _onRestartGame(
    RestartGameEvent event,
    Emitter<ColorMemoryGameState> emit,
  ) {
    _gameTimer?.cancel();
    _sequenceTimer?.cancel();

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
    _gameTimer?.cancel();
    _sequenceTimer?.cancel();
    return super.close();
  }
}
