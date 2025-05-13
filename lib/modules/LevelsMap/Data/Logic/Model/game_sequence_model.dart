import 'package:flutter/material.dart';
import 'package:kidzoo/modules/MathGame/Ui/math_game.dart';
import 'package:kidzoo/modules/MemoryGame/UI/memory_game.dart';
import 'package:kidzoo/modules/Puzzle/puzzle_screen.dart';
import 'package:kidzoo/modules/Quiz/UI/animal_quiz_screen.dart';
import 'map_stage_model.dart';

/// Defines the game types available in the sequence
enum GameType { animalQuiz, memoryGame, puzzle, mathGame }

/// Model class to represent a game in the sequence
class GameSequenceItem {
  final GameType gameType;
  final String name;
  final Widget gameScreen;
  final int level;

  GameSequenceItem({
    required this.gameType,
    required this.name,
    required this.gameScreen,
    required this.level,
  });

  /// Factory method to create a game sequence item based on game type and level
  factory GameSequenceItem.create(GameType type, int level) {
    switch (type) {
      case GameType.animalQuiz:
        return GameSequenceItem(
          gameType: type,
          name: 'Animal Quiz',
          gameScreen: AnimalQuizScreen(level: level),
          level: level,
        );
      case GameType.memoryGame:
        return GameSequenceItem(
          gameType: type,
          name: 'Memory Game',
          gameScreen: MemoryGameScreen(level: level),
          level: level,
        );
      case GameType.puzzle:
        return GameSequenceItem(
          gameType: type,
          name: 'Puzzle',
          gameScreen: PuzzleScreen(level: level),
          level: level,
        );
      case GameType.mathGame:
        return GameSequenceItem(
          gameType: type,
          name: 'Math Game',
          gameScreen: MathGame(level: level),
          level: level,
        );
    }
  }
}

/// Utility class to manage the game sequence
class GameSequence {
  /// Get the game type for a specific level ID using the fixed stage mapping
  static GameType getGameTypeForLevel(int levelId) {
    // Get the stage for this level ID
    final stage = StageMapping.getStageByNumber(levelId);
    if (stage != null) {
      return stage.gameType;
    }

    // Fallback to the old calculation if stage not found
    switch ((levelId - 1) % 4) {
      case 0:
        return GameType.animalQuiz;
      case 1:
        return GameType.memoryGame;
      case 2:
        return GameType.puzzle;
      case 3:
        return GameType.mathGame;
      default:
        return GameType.animalQuiz;
    }
  }

  /// Get the difficulty level for a specific level ID using the fixed stage mapping
  static int getDifficultyLevel(int levelId) {
    // Get the stage for this level ID
    final stage = StageMapping.getStageByNumber(levelId);
    if (stage != null) {
      return stage.level;
    }

    // Fallback to the old calculation if stage not found
    return ((levelId - 1) ~/ 4) + 1;
  }

  /// Create a game sequence item for a specific level ID
  static GameSequenceItem createGameForLevel(int levelId) {
    final gameType = getGameTypeForLevel(levelId);
    final difficultyLevel = getDifficultyLevel(levelId);

    return GameSequenceItem.create(gameType, difficultyLevel);
  }

  /// Get the stage number for a specific game type and level
  static int? getStageNumberForGameTypeAndLevel(GameType gameType, int level) {
    final stage = StageMapping.getStageByGameTypeAndLevel(gameType, level);
    return stage?.stageNumber;
  }
}
