import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/features/AnimalQuiz/UI/animal_quiz_screen.dart';
import 'package:kidzoo/features/ColorMemoryGame/UI/color_memory_screen.dart';
import 'package:kidzoo/features/CrosswordGame/UI/crossword_game_screen.dart';
import 'package:kidzoo/features/CrosswordGame/data/logic/crossword_cubit.dart';
import 'package:kidzoo/features/CrosswordGame/data/logic/crossword_loader.dart';
import 'package:kidzoo/features/CrosswordGame/data/models/crossword_models.dart';
import 'package:kidzoo/features/DotsAndBoxes/UI/dots_and_boxes_screen.dart';
import 'package:kidzoo/features/MathGame/Ui/math_game.dart';
import 'package:kidzoo/features/MemoryGame/UI/memory_game.dart';
import 'package:kidzoo/features/Puzzle/puzzle_screen.dart';

import 'map_stage_model.dart';

/// Defines the game types available in the sequence
enum GameType {
  animalQuiz,
  memoryGame,
  puzzle,
  mathGame,
  colorMemoryGame,
  crossword,
  dotsAndBoxes
}

/// Model class to represent a game in the sequence
class GameSequenceItem {
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
      case GameType.colorMemoryGame:
        return GameSequenceItem(
          gameType: type,
          name: 'Color Memory',
          gameScreen: ColorMemoryScreen(level: level),
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
      case GameType.crossword:
        return GameSequenceItem(
          gameType: type,
          name: 'Crossword',
          gameScreen: _CrosswordGameWrapper(level: level),
          level: level,
        );
      case GameType.dotsAndBoxes:
        return GameSequenceItem(
          gameType: type,
          name: 'Dots & Boxes',
          gameScreen: DotsAndBoxesScreen(level: level),
          level: level,
        );
    }
  }
  final GameType gameType;
  final String name;
  final Widget gameScreen;
  final int level;
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

  /// Get the next stage number in the progression
  static int getNextStageNumber(int currentStageNumber) {
    return StageMapping.getNextStageNumber(currentStageNumber);
  }

  /// Check if a stage is the last stage in the progression
  static bool isLastStage(int stageNumber) {
    return StageMapping.isLastStage(stageNumber);
  }

  /// Get the total number of stages
  static int getTotalStages() {
    return StageMapping.getTotalStages();
  }

  /// Get the game type for a specific stage number
  static GameType getGameTypeForStage(int stageNumber) {
    return StageMapping.getGameTypeForStage(stageNumber);
  }

  /// Get the level for a specific stage number
  static int getLevelForStage(int stageNumber) {
    return StageMapping.getLevelForStage(stageNumber);
  }
}

// Wrapper widget to load crossword puzzle based on level
class _CrosswordGameWrapper extends StatelessWidget {
  const _CrosswordGameWrapper({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CrosswordPuzzle?>(
      future: _loadPuzzle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Text('Error loading puzzle: ${snapshot.error}'),
            ),
          );
        }

        return BlocProvider(
          create: (context) => CrosswordCubit(snapshot.data!),
          child: const CrosswordGameScreen(),
        );
      },
    );
  }

  Future<CrosswordPuzzle?> _loadPuzzle() async {
    // Map level to difficulty and puzzle index
    final difficulty = level == 1
        ? Difficulty.easy
        : level == 2
            ? Difficulty.medium
            : Difficulty.hard;

    final puzzles = await CrosswordLoader.loadPuzzlesByDifficulty(difficulty);
    return puzzles.isNotEmpty ? puzzles[0] : null;
  }
}
