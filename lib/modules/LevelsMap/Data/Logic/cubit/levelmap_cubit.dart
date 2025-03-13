import 'package:flutter_bloc/flutter_bloc.dart';
import '../Model/level_model.dart';

class LevelCubit extends Cubit<List<Level>> {
  LevelCubit() : super([]) {
    // Initialize levels with the predefined data
    _initializeLevels();
  }

  void _initializeLevels() {
    final initialLevels = [
      // Phase 1: Snowy Arctic (Levels 1-6, 0px to 660px)
      Level(id: 1, phase: 1, isLocked: false, positionX: 180, positionY: 70),
      Level(id: 2, phase: 1, isLocked: true, positionX: 160, positionY: 170),
      Level(id: 3, phase: 1, isLocked: true, positionX: 100, positionY: 300),
      Level(id: 4, phase: 1, isLocked: true, positionX: 110, positionY: 400),
      Level(id: 5, phase: 1, isLocked: true, positionX: 160, positionY: 530),
      Level(id: 6, phase: 1, isLocked: true, positionX: 150, positionY: 650),

      // Phase 2: Icy Water (Levels 7-12, 660px to 1320px)
      Level(id: 7, phase: 2, isLocked: true, positionX: 130, positionY: 800),
      Level(id: 8, phase: 2, isLocked: true, positionX: 160, positionY: 900),
      Level(id: 9, phase: 2, isLocked: true, positionX: 160, positionY: 1000),
      Level(id: 10, phase: 2, isLocked: true, positionX: 160, positionY: 1100),
      Level(id: 11, phase: 2, isLocked: true, positionX: 110, positionY: 1200),
      Level(id: 12, phase: 2, isLocked: true, positionX: 180, positionY: 1300),

      // Phase 3: Tropical (Levels 13-18, 1320px to 2000px)
      Level(id: 13, phase: 3, isLocked: true, positionX: 150, positionY: 1420),
      Level(id: 14, phase: 3, isLocked: true, positionX: 140, positionY: 1560),
      Level(id: 15, phase: 3, isLocked: true, positionX: 80, positionY: 1650),
      Level(id: 16, phase: 3, isLocked: true, positionX: 250, positionY: 1720),
      Level(id: 17, phase: 3, isLocked: true, positionX: 20, positionY: 1800),
      Level(id: 18, phase: 3, isLocked: true, positionX: 170, positionY: 1900),
    ];
    emit(initialLevels);
  }

  void unlockLevel(int levelId) {
    final updatedLevels = state.map((level) {
      if (level.id == levelId) {
        return Level(
          id: level.id,
          phase: level.phase,
          isLocked: false,
          positionX: level.positionX,
          positionY: level.positionY,
        );
      }
      return level;
    }).toList();
    emit(updatedLevels);
  }
}
