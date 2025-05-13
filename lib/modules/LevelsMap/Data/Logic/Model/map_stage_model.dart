import 'game_sequence_model.dart';

/// Model class to represent a map stage with fixed game type and level
class MapStage {
  final int stageNumber;
  final GameType gameType;
  final int level;
  final bool isLocked;

  MapStage({
    required this.stageNumber,
    required this.gameType,
    required this.level,
    this.isLocked = true,
  });

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
  static List<MapStage> getAllStages() {
    return [
      // Animal Quiz stages
      MapStage(
          stageNumber: 1,
          gameType: GameType.animalQuiz,
          level: 1,
          isLocked: false), // First stage is unlocked by default
      MapStage(stageNumber: 5, gameType: GameType.animalQuiz, level: 2),
      MapStage(stageNumber: 9, gameType: GameType.animalQuiz, level: 3),

      // Memory Game stages
      MapStage(stageNumber: 2, gameType: GameType.memoryGame, level: 1),
      MapStage(stageNumber: 6, gameType: GameType.memoryGame, level: 2),
      MapStage(stageNumber: 10, gameType: GameType.memoryGame, level: 3),

      // Puzzle stages
      MapStage(stageNumber: 3, gameType: GameType.puzzle, level: 1),
      MapStage(stageNumber: 7, gameType: GameType.puzzle, level: 2),
      MapStage(stageNumber: 11, gameType: GameType.puzzle, level: 3),

      // Math Game stages
      MapStage(stageNumber: 4, gameType: GameType.mathGame, level: 1),
      MapStage(stageNumber: 8, gameType: GameType.mathGame, level: 2),
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
}
