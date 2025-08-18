import 'game_sequence_model.dart';

/// Model class to represent a map stage with fixed game type and level
class MapStage {
  MapStage({
    required this.stageNumber,
    required this.gameType,
    required this.level,
    this.isLocked = true,
  });
  final int stageNumber;
  final GameType gameType;
  final int level;
  final bool isLocked;

  /// Create a copy of this stage with modified properties
  MapStage copyWith({
    int? stageNumber,
    GameType? gameType,
    int? level,
    bool? isLocked,
  }) {
    return MapStage(
      stageNumber: stageNumber ?? this.stageNumber,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Utility class to manage the fixed stage mapping
class StageMapping {
  /// Get all stages with their fixed game types and levels
  /// Level progression: Animal Quiz (1) -> Memory Game (2) -> Puzzle (3) -> Math Game (4)
  /// Then repeat with level 2: Animal Quiz (5) -> Memory Game (6) -> Puzzle (7) -> Math Game (8)
  /// Then repeat with level 3: Animal Quiz (9) -> Memory Game (10) -> Puzzle (11) -> Math Game (12)
  static List<MapStage> getAllStages() {
    return [
      // Level 1 Cycle (Stages 1-4)
      MapStage(
          stageNumber: 1,
          gameType: GameType.animalQuiz,
          level: 1,
          isLocked: false), // First stage is unlocked by default
      MapStage(stageNumber: 2, gameType: GameType.memoryGame, level: 1),
      MapStage(stageNumber: 3, gameType: GameType.puzzle, level: 1),
      MapStage(stageNumber: 4, gameType: GameType.mathGame, level: 1),

      // Level 2 Cycle (Stages 5-8)
      MapStage(stageNumber: 5, gameType: GameType.animalQuiz, level: 2),
      MapStage(stageNumber: 6, gameType: GameType.memoryGame, level: 2),
      MapStage(stageNumber: 7, gameType: GameType.puzzle, level: 2),
      MapStage(stageNumber: 8, gameType: GameType.mathGame, level: 2),

      // Level 3 Cycle (Stages 9-12)
      MapStage(stageNumber: 9, gameType: GameType.animalQuiz, level: 3),
      MapStage(stageNumber: 10, gameType: GameType.memoryGame, level: 3),
      MapStage(stageNumber: 11, gameType: GameType.puzzle, level: 3),
      MapStage(stageNumber: 12, gameType: GameType.mathGame, level: 3),
    ];
  }

  /// Get a stage by its stage number
  static MapStage? getStageByNumber(int stageNumber) {
    final stages = getAllStages();
    try {
      return stages.firstWhere((stage) => stage.stageNumber == stageNumber);
    } catch (e) {
      return null;
    }
  }

  /// Get a stage by game type and level
  static MapStage? getStageByGameTypeAndLevel(GameType gameType, int level) {
    final stages = getAllStages();
    try {
      return stages.firstWhere(
          (stage) => stage.gameType == gameType && stage.level == level);
    } catch (e) {
      return null;
    }
  }

  /// Get the next stage number in the progression
  static int getNextStageNumber(int currentStageNumber) {
    final stages = getAllStages();
    final maxStageNumber = stages.length;

    if (currentStageNumber >= maxStageNumber) {
      return maxStageNumber; // Stay at the last stage if completed all
    }

    return currentStageNumber + 1;
  }

  /// Get the game type for a specific stage number
  static GameType getGameTypeForStage(int stageNumber) {
    final stage = getStageByNumber(stageNumber);
    return stage?.gameType ?? GameType.animalQuiz;
  }

  /// Get the level for a specific stage number
  static int getLevelForStage(int stageNumber) {
    final stage = getStageByNumber(stageNumber);
    return stage?.level ?? 1;
  }

  /// Check if a stage is the last stage in the progression
  static bool isLastStage(int stageNumber) {
    final stages = getAllStages();
    return stageNumber >= stages.length;
  }

  /// Get the total number of stages
  static int getTotalStages() {
    return getAllStages().length;
  }
}
