import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/level_model.dart';
import '../Model/game_sequence_model.dart';
import '../Model/map_stage_model.dart';

class LevelMapState {
  final List<Level> levels;
  final int currentLevelId;
  final int highestUnlockedLevelId;

  LevelMapState({
    required this.levels,
    required this.currentLevelId,
    required this.highestUnlockedLevelId,
  });

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
  static const String _prefKeyHighestLevel = 'highest_unlocked_level';
  static const String _prefKeyCurrentLevel = 'current_level';

  LevelCubit()
      : super(LevelMapState(
          levels: [],
          currentLevelId: 1,
          highestUnlockedLevelId: 1,
        )) {
    // Initialize levels with the predefined data
    _initializeLevels();
  }

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
      // Phase 1: Snowy Arctic (Levels 1-6, 0px to 660px)
      Level(id: 1, phase: 1, isLocked: false, positionX: 180, positionY: 70),
      Level(
          id: 2,
          phase: 1,
          isLocked: highestUnlockedLevelId < 2,
          positionX: 160,
          positionY: 170),
      Level(
          id: 3,
          phase: 1,
          isLocked: highestUnlockedLevelId < 3,
          positionX: 100,
          positionY: 300),
      Level(
          id: 4,
          phase: 1,
          isLocked: highestUnlockedLevelId < 4,
          positionX: 110,
          positionY: 400),
      Level(
          id: 5,
          phase: 1,
          isLocked: highestUnlockedLevelId < 5,
          positionX: 160,
          positionY: 530),
      Level(
          id: 6,
          phase: 1,
          isLocked: highestUnlockedLevelId < 6,
          positionX: 150,
          positionY: 650),

      // Phase 2: Icy Water (Levels 7-12, 660px to 1320px)
      Level(
          id: 7,
          phase: 2,
          isLocked: highestUnlockedLevelId < 7,
          positionX: 130,
          positionY: 800),
      Level(
          id: 8,
          phase: 2,
          isLocked: highestUnlockedLevelId < 8,
          positionX: 160,
          positionY: 900),
      Level(
          id: 9,
          phase: 2,
          isLocked: highestUnlockedLevelId < 9,
          positionX: 160,
          positionY: 1000),
      Level(
          id: 10,
          phase: 2,
          isLocked: highestUnlockedLevelId < 10,
          positionX: 160,
          positionY: 1100),
      Level(
          id: 11,
          phase: 2,
          isLocked: highestUnlockedLevelId < 11,
          positionX: 110,
          positionY: 1200),
      Level(
          id: 12,
          phase: 2,
          isLocked: highestUnlockedLevelId < 12,
          positionX: 180,
          positionY: 1300),

      // Phase 3: Tropical (Levels 13-18, 1320px to 2000px)
      Level(
          id: 13,
          phase: 3,
          isLocked: highestUnlockedLevelId < 13,
          positionX: 150,
          positionY: 1420),
      Level(
          id: 14,
          phase: 3,
          isLocked: highestUnlockedLevelId < 14,
          positionX: 140,
          positionY: 1560),
      Level(
          id: 15,
          phase: 3,
          isLocked: highestUnlockedLevelId < 15,
          positionX: 80,
          positionY: 1650),
      Level(
          id: 16,
          phase: 3,
          isLocked: highestUnlockedLevelId < 16,
          positionX: 250,
          positionY: 1720),
      Level(
          id: 17,
          phase: 3,
          isLocked: highestUnlockedLevelId < 17,
          positionX: 20,
          positionY: 1800),
      Level(
          id: 18,
          phase: 3,
          isLocked: highestUnlockedLevelId < 18,
          positionX: 170,
          positionY: 1900),
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

  // Unlock a specific level
  Future<void> unlockLevel(int levelId) async {
    final updatedLevels = state.levels.map((level) {
      if (level.id == levelId) {
        return level.copyWith(isLocked: false);
      }
      return level;
    }).toList();

    // Update highest unlocked level if needed
    int highestUnlockedLevelId = state.highestUnlockedLevelId;
    if (levelId > highestUnlockedLevelId) {
      highestUnlockedLevelId = levelId;
      // Save progress to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyHighestLevel, highestUnlockedLevelId);
    }

    emit(state.copyWith(
      levels: updatedLevels,
      highestUnlockedLevelId: highestUnlockedLevelId,
    ));
  }

  // Complete the current level and unlock the next one
  Future<void> completeCurrentLevel() async {
    final nextLevelId = state.currentLevelId + 1;

    // Unlock the next level
    await unlockLevel(nextLevelId);

    // Set the current level to the next level
    await setCurrentLevel(nextLevelId);
  }
}
