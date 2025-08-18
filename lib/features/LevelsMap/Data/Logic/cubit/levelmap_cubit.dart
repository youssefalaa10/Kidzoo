import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/game_sequence_model.dart';
import '../Model/level_model.dart';
import '../Model/map_stage_model.dart';

class LevelMapState {
  LevelMapState({
    required this.levels,
    required this.currentLevelId,
    required this.highestUnlockedLevelId,
  });
  final List<Level> levels;
  final int currentLevelId;
  final int highestUnlockedLevelId;

  LevelMapState copyWith({
    List<Level>? levels,
    int? currentLevelId,
    int? highestUnlockedLevelId,
  }) {
    return LevelMapState(
      levels: levels ?? this.levels,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      highestUnlockedLevelId:
          highestUnlockedLevelId ?? this.highestUnlockedLevelId,
    );
  }
}

class LevelCubit extends Cubit<LevelMapState> {
  LevelCubit()
      : super(LevelMapState(
          levels: [],
          currentLevelId: 1,
          highestUnlockedLevelId: 1,
        )) {
    // Initialize levels with the predefined data
    _initializeLevels();
  }
  static const String _prefKeyHighestLevel = 'highest_unlocked_level';
  static const String _prefKeyCurrentLevel = 'current_level';

  Future<void> _initializeLevels() async {
    // Load saved progress from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final highestUnlockedLevelId = prefs.getInt(_prefKeyHighestLevel) ?? 1;
    final currentLevelId = prefs.getInt(_prefKeyCurrentLevel) ?? 1;

    // Get all stages with their fixed mapping
    final allStages = StageMapping.getAllStages();

    // Update stages lock status based on highest unlocked level
    for (var stage in allStages) {
      if (stage.stageNumber <= highestUnlockedLevelId) {
        stage = stage.copyWith(isLocked: false);
      }
    }

    final initialLevels = [
      // Stage 1: Animal Quiz Level 1
      Level(id: 1, phase: 1, isLocked: false, positionX: 180, positionY: 70),

      // Stage 2: Memory Game Level 1
      Level(
          id: 2,
          phase: 1,
          isLocked: highestUnlockedLevelId < 2,
          positionX: 160,
          positionY: 170),

      // Stage 3: Puzzle Level 1
      Level(
          id: 3,
          phase: 1,
          isLocked: highestUnlockedLevelId < 3,
          positionX: 100,
          positionY: 300),

      // Stage 4: Math Game Level 1
      Level(
          id: 4,
          phase: 1,
          isLocked: highestUnlockedLevelId < 4,
          positionX: 110,
          positionY: 400),

      // Stage 5: Animal Quiz Level 2
      Level(
          id: 5,
          phase: 2,
          isLocked: highestUnlockedLevelId < 5,
          positionX: 160,
          positionY: 530),

      // Stage 6: Memory Game Level 2
      Level(
          id: 6,
          phase: 2,
          isLocked: highestUnlockedLevelId < 6,
          positionX: 150,
          positionY: 650),

      // Stage 7: Puzzle Level 2
      Level(
          id: 7,
          phase: 2,
          isLocked: highestUnlockedLevelId < 7,
          positionX: 130,
          positionY: 800),

      // Stage 8: Math Game Level 2
      Level(
          id: 8,
          phase: 2,
          isLocked: highestUnlockedLevelId < 8,
          positionX: 160,
          positionY: 900),

      // Stage 9: Animal Quiz Level 3
      Level(
          id: 9,
          phase: 3,
          isLocked: highestUnlockedLevelId < 9,
          positionX: 160,
          positionY: 1000),

      // Stage 10: Memory Game Level 3
      Level(
          id: 10,
          phase: 3,
          isLocked: highestUnlockedLevelId < 10,
          positionX: 160,
          positionY: 1100),

      // Stage 11: Puzzle Level 3
      Level(
          id: 11,
          phase: 3,
          isLocked: highestUnlockedLevelId < 11,
          positionX: 110,
          positionY: 1200),

      // Stage 12: Math Game Level 3
      Level(
          id: 12,
          phase: 3,
          isLocked: highestUnlockedLevelId < 12,
          positionX: 180,
          positionY: 1300),
    ];

    emit(LevelMapState(
      levels: initialLevels,
      currentLevelId: currentLevelId,
      highestUnlockedLevelId: highestUnlockedLevelId,
    ));
  }

  // Get the current game sequence item based on the current level ID
  GameSequenceItem getCurrentGameSequenceItem() {
    return GameSequence.createGameForLevel(state.currentLevelId);
  }

  // Set the current level ID (for resuming from a specific level)
  Future<void> setCurrentLevel(int levelId) async {
    if (levelId <= state.highestUnlockedLevelId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyCurrentLevel, levelId);
      emit(state.copyWith(currentLevelId: levelId));
    }
  }

  // Complete the current level and unlock the next one
  Future<void> completeCurrentLevel() async {
    final nextLevelId = GameSequence.getNextStageNumber(state.currentLevelId);

    print(
        'DEBUG: Completing level ${state.currentLevelId}, next level is $nextLevelId');
    print(
        'DEBUG: Current highest unlocked level: ${state.highestUnlockedLevelId}');

    // Unlock the next level if it exists
    if (nextLevelId <= GameSequence.getTotalStages()) {
      print('DEBUG: Unlocking level $nextLevelId');
      await unlockLevel(nextLevelId);

      // Set the current level to the next level
      await setCurrentLevel(nextLevelId);

      print('DEBUG: Level $nextLevelId unlocked and set as current');
      print(
          'DEBUG: New highest unlocked level: ${state.highestUnlockedLevelId}');
    } else {
      print('DEBUG: No more levels to unlock');
    }
  }

  // Complete a specific level and unlock the next one
  Future<void> completeLevel(int levelId) async {
    final nextLevelId = GameSequence.getNextStageNumber(levelId);

    // Unlock the next level if it exists
    if (nextLevelId <= GameSequence.getTotalStages()) {
      await unlockLevel(nextLevelId);
    }
  }

  // Check if all levels are completed
  bool isAllLevelsCompleted() {
    return state.highestUnlockedLevelId >= GameSequence.getTotalStages();
  }

  // Get the next level ID in the progression
  int getNextLevelId(int currentLevelId) {
    return GameSequence.getNextStageNumber(currentLevelId);
  }

  // Check if a level is the last level
  bool isLastLevel(int levelId) {
    return GameSequence.isLastStage(levelId);
  }

  // Get the total number of levels
  int getTotalLevels() {
    return GameSequence.getTotalStages();
  }

  // Unlock a specific level
  Future<void> unlockLevel(int levelId) async {
    print('DEBUG: Unlocking level $levelId');
    print(
        'DEBUG: Before unlock - highest unlocked: ${state.highestUnlockedLevelId}');

    final updatedLevels = state.levels.map((level) {
      if (level.id == levelId) {
        print('DEBUG: Setting level $levelId to unlocked');
        return level.copyWith(isLocked: false);
      }
      return level;
    }).toList();

    // Update highest unlocked level if needed
    int highestUnlockedLevelId = state.highestUnlockedLevelId;
    if (levelId > highestUnlockedLevelId) {
      highestUnlockedLevelId = levelId;
      print(
          'DEBUG: Updating highest unlocked level to $highestUnlockedLevelId');
      // Save progress to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyHighestLevel, highestUnlockedLevelId);
    }

    emit(state.copyWith(
      levels: updatedLevels,
      highestUnlockedLevelId: highestUnlockedLevelId,
    ));

    print('DEBUG: State updated with unlocked level $levelId');
    print(
        'DEBUG: After unlock - highest unlocked: ${state.highestUnlockedLevelId}');

    // Verify the level is actually unlocked
    final unlockedLevel =
        updatedLevels.firstWhere((level) => level.id == levelId);
    print('DEBUG: Level $levelId isLocked: ${unlockedLevel.isLocked}');
  }
}
