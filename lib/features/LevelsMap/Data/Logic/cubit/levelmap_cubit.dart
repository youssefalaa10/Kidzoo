import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/game_sequence_model.dart';
import '../Model/level_model.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final highestUnlockedLevelId = prefs.getInt(_prefKeyHighestLevel) ?? 1;
    final currentLevelId = prefs.getInt(_prefKeyCurrentLevel) ?? 1;

    emit(LevelMapState(
      levels: _buildLevels(highestUnlockedLevelId),
      currentLevelId: currentLevelId,
      highestUnlockedLevelId: highestUnlockedLevelId,
    ));
  }

  List<Level> _buildLevels(int highestUnlockedLevelId) {
    return [
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
          positionX: 150,
          positionY: 1330),
      Level(
          id: 13,
          phase: 3,
          isLocked: highestUnlockedLevelId < 13,
          positionX: 180,
          positionY: 1470),
      Level(
          id: 14,
          phase: 3,
          isLocked: highestUnlockedLevelId < 14,
          positionX: 130,
          positionY: 1600),
      Level(
          id: 15,
          phase: 3,
          isLocked: highestUnlockedLevelId < 15,
          positionX: 160,
          positionY: 1720),
      Level(
          id: 16,
          phase: 3,
          isLocked: highestUnlockedLevelId < 16,
          positionX: 120,
          positionY: 1840),
      Level(
          id: 17,
          phase: 3,
          isLocked: highestUnlockedLevelId < 17,
          positionX: 150,
          positionY: 1960),
      Level(
          id: 18,
          phase: 3,
          isLocked: highestUnlockedLevelId < 18,
          positionX: 180,
          positionY: 2080),
    ];
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

    // Unlock the next level if it exists
    if (nextLevelId <= GameSequence.getTotalStages()) {
      await unlockLevel(nextLevelId);

      // Set the current level to the next level
      await setCurrentLevel(nextLevelId);
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

  // Unlock progress up to [levelId]; never regress saved progress.
  Future<void> unlockLevel(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedHighest = prefs.getInt(_prefKeyHighestLevel) ?? 1;
    final highestUnlockedLevelId = math.max(
      math.max(state.highestUnlockedLevelId, savedHighest),
      levelId,
    );

    if (highestUnlockedLevelId > savedHighest) {
      await prefs.setInt(_prefKeyHighestLevel, highestUnlockedLevelId);
    }

    final updatedLevels = state.levels.isEmpty
        ? _buildLevels(highestUnlockedLevelId)
        : state.levels
            .map(
              (level) => level.copyWith(
                isLocked: level.id > highestUnlockedLevelId,
              ),
            )
            .toList();

    emit(state.copyWith(
      levels: updatedLevels,
      highestUnlockedLevelId: highestUnlockedLevelId,
    ));
  }
}
