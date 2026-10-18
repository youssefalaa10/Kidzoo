import 'package:equatable/equatable.dart';

import 'color_memory_constants.dart';

/// Represents the current state of the game
enum GamePhase {
  waiting, // Waiting to start
  showingSequence, // Displaying the sequence to memorize
  playerTurn, // Player's turn to repeat sequence
  checking, // Checking player's input
  success, // Round completed successfully
  failure, // Player made a mistake
  gameOver, // Game ended
  levelComplete, // All rounds completed - level finished
}

/// Model for game settings
class GameSettings extends Equatable {
  const GameSettings({
    this.soundEnabled = ColorMemoryConstants.defaultSoundEnabled,
    this.hapticsEnabled = ColorMemoryConstants.defaultHapticsEnabled,
    this.colorBlindMode = ColorMemoryConstants.defaultColorBlindMode,
    this.selectedPaletteIndex = 0,
  });

  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool colorBlindMode;
  final int selectedPaletteIndex;

  GameSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? colorBlindMode,
    int? selectedPaletteIndex,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      selectedPaletteIndex: selectedPaletteIndex ?? this.selectedPaletteIndex,
    );
  }

  @override
  List<Object?> get props => [
        soundEnabled,
        hapticsEnabled,
        colorBlindMode,
        selectedPaletteIndex,
      ];
}

/// Model for game score and statistics
class GameScore extends Equatable {
  const GameScore({
    this.currentLevel = 1,
    this.currentRound = 1,
    this.currentScore = 0,
    this.sequenceLength = 0,
    this.perfectRounds = 0,
    this.totalMoves = 0,
    this.longestSequence = 0,
  });

  final int currentLevel;
  final int currentRound;
  final int currentScore;
  final int sequenceLength;
  final int perfectRounds;
  final int totalMoves;
  final int longestSequence;

  GameScore copyWith({
    int? currentLevel,
    int? currentRound,
    int? currentScore,
    int? sequenceLength,
    int? perfectRounds,
    int? totalMoves,
    int? longestSequence,
  }) {
    return GameScore(
      currentLevel: currentLevel ?? this.currentLevel,
      currentRound: currentRound ?? this.currentRound,
      currentScore: currentScore ?? this.currentScore,
      sequenceLength: sequenceLength ?? this.sequenceLength,
      perfectRounds: perfectRounds ?? this.perfectRounds,
      totalMoves: totalMoves ?? this.totalMoves,
      longestSequence: longestSequence ?? this.longestSequence,
    );
  }

  @override
  List<Object?> get props => [
        currentLevel,
        currentRound,
        currentScore,
        sequenceLength,
        perfectRounds,
        totalMoves,
        longestSequence,
      ];
}

/// Model for the complete game state
class ColorMemoryGameState extends Equatable {
  const ColorMemoryGameState({
    this.phase = GamePhase.waiting,
    this.mode = ColorMemoryGameMode.classic,
    this.level = 1,
    this.sequence = const [],
    this.playerSequence = const [],
    this.currentSequenceIndex = 0,
    this.highlightedColorIndex = -1,
    this.score = const GameScore(),
    this.settings = const GameSettings(),
    this.remainingTime = 0.0,
    this.bestScore = 0,
    this.errorMessage,
  });

  final GamePhase phase;
  final ColorMemoryGameMode mode;
  final int level;
  final List<int> sequence; // Indices of colors in the sequence
  final List<int> playerSequence; // Player's input sequence
  final int currentSequenceIndex; // Current position in sequence display
  final int highlightedColorIndex; // Currently highlighted color (-1 if none)
  final GameScore score;
  final GameSettings settings;
  final double remainingTime; // For timed mode
  final int bestScore;
  final String? errorMessage;

  ColorMemoryGameState copyWith({
    GamePhase? phase,
    ColorMemoryGameMode? mode,
    int? level,
    List<int>? sequence,
    List<int>? playerSequence,
    int? currentSequenceIndex,
    int? highlightedColorIndex,
    GameScore? score,
    GameSettings? settings,
    double? remainingTime,
    int? bestScore,
    String? errorMessage,
  }) {
    return ColorMemoryGameState(
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      sequence: sequence ?? this.sequence,
      playerSequence: playerSequence ?? this.playerSequence,
      currentSequenceIndex: currentSequenceIndex ?? this.currentSequenceIndex,
      highlightedColorIndex:
          highlightedColorIndex ?? this.highlightedColorIndex,
      score: score ?? this.score,
      settings: settings ?? this.settings,
      remainingTime: remainingTime ?? this.remainingTime,
      bestScore: bestScore ?? this.bestScore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        mode,
        level,
        sequence,
        playerSequence,
        currentSequenceIndex,
        highlightedColorIndex,
        score,
        settings,
        remainingTime,
        bestScore,
        errorMessage,
      ];
}
