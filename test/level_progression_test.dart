import 'package:flutter_test/flutter_test.dart';
import 'package:kidzoo/features/LevelsMap/Data/Logic/Model/game_sequence_model.dart';
import 'package:kidzoo/features/LevelsMap/Data/Logic/Model/map_stage_model.dart';

void main() {
  group('Level Progression System Tests', () {
    test('Stage mapping should follow correct progression', () {
      // Test Level 1 Cycle
      expect(StageMapping.getGameTypeForStage(1), GameType.animalQuiz);
      expect(StageMapping.getLevelForStage(1), 1);

      expect(StageMapping.getGameTypeForStage(2), GameType.memoryGame);
      expect(StageMapping.getLevelForStage(2), 1);

      expect(StageMapping.getGameTypeForStage(3), GameType.puzzle);
      expect(StageMapping.getLevelForStage(3), 1);

      expect(StageMapping.getGameTypeForStage(4), GameType.mathGame);
      expect(StageMapping.getLevelForStage(4), 1);
    });

    test('Level 2 Cycle should follow correct progression', () {
      // Test Level 2 Cycle
      expect(StageMapping.getGameTypeForStage(5), GameType.animalQuiz);
      expect(StageMapping.getLevelForStage(5), 2);

      expect(StageMapping.getGameTypeForStage(6), GameType.memoryGame);
      expect(StageMapping.getLevelForStage(6), 2);

      expect(StageMapping.getGameTypeForStage(7), GameType.puzzle);
      expect(StageMapping.getLevelForStage(7), 2);

      expect(StageMapping.getGameTypeForStage(8), GameType.mathGame);
      expect(StageMapping.getLevelForStage(8), 2);
    });

    test('Level 3 Cycle should follow correct progression', () {
      // Test Level 3 Cycle
      expect(StageMapping.getGameTypeForStage(9), GameType.animalQuiz);
      expect(StageMapping.getLevelForStage(9), 3);

      expect(StageMapping.getGameTypeForStage(10), GameType.memoryGame);
      expect(StageMapping.getLevelForStage(10), 3);

      expect(StageMapping.getGameTypeForStage(11), GameType.puzzle);
      expect(StageMapping.getLevelForStage(11), 3);

      expect(StageMapping.getGameTypeForStage(12), GameType.mathGame);
      expect(StageMapping.getLevelForStage(12), 3);
    });

    test('Next stage progression should work correctly', () {
      expect(StageMapping.getNextStageNumber(1), 2);
      expect(StageMapping.getNextStageNumber(2), 3);
      expect(StageMapping.getNextStageNumber(3), 4);
      expect(StageMapping.getNextStageNumber(4), 5);
      expect(StageMapping.getNextStageNumber(5), 6);
      expect(StageMapping.getNextStageNumber(6), 7);
      expect(StageMapping.getNextStageNumber(7), 8);
      expect(StageMapping.getNextStageNumber(8), 9);
      expect(StageMapping.getNextStageNumber(9), 10);
      expect(StageMapping.getNextStageNumber(10), 11);
      expect(StageMapping.getNextStageNumber(11), 12);
      expect(StageMapping.getNextStageNumber(12), 12); // Last stage
    });

    test('Game sequence should create correct game instances', () {
      final game1 = GameSequence.createGameForLevel(1);
      expect(game1.gameType, GameType.animalQuiz);
      expect(game1.level, 1);
      expect(game1.name, 'Animal Quiz');

      final game2 = GameSequence.createGameForLevel(2);
      expect(game2.gameType, GameType.memoryGame);
      expect(game2.level, 1);
      expect(game2.name, 'Memory Game');

      final game3 = GameSequence.createGameForLevel(3);
      expect(game3.gameType, GameType.puzzle);
      expect(game3.level, 1);
      expect(game3.name, 'Puzzle');

      final game4 = GameSequence.createGameForLevel(4);
      expect(game4.gameType, GameType.mathGame);
      expect(game4.level, 1);
      expect(game4.name, 'Math Game');
    });

    test('Last stage detection should work correctly', () {
      expect(StageMapping.isLastStage(1), false);
      expect(StageMapping.isLastStage(5), false);
      expect(StageMapping.isLastStage(10), false);
      expect(StageMapping.isLastStage(12), true);
      expect(StageMapping.isLastStage(13), true); // Beyond total stages
    });

    test('Total stages should be correct', () {
      expect(StageMapping.getTotalStages(), 12);
    });

    test('Game sequence helper methods should work correctly', () {
      expect(GameSequence.getNextStageNumber(1), 2);
      expect(GameSequence.isLastStage(12), true);
      expect(GameSequence.getTotalStages(), 12);
      expect(GameSequence.getGameTypeForStage(1), GameType.animalQuiz);
      expect(GameSequence.getLevelForStage(1), 1);
    });
  });
}
