import 'game_sequence_model.dart';

class Level {
  final int id;
  final int phase;
  final bool isLocked;
  final double positionX;
  final double positionY;
  final GameType gameType;
  final int difficultyLevel;

  Level({
    required this.id,
    required this.phase,
    required this.isLocked,
    required this.positionX,
    required this.positionY,
  })  :
        // Automatically determine game type and difficulty level based on level ID
        gameType = GameSequence.getGameTypeForLevel(id),
        difficultyLevel = GameSequence.getDifficultyLevel(id);

  // Create a copy of this level with modified properties
  Level copyWith({
    int? id,
    int? phase,
    bool? isLocked,
    double? positionX,
    double? positionY,
  }) {
    return Level(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      isLocked: isLocked ?? this.isLocked,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
    );
  }
}
