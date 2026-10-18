import 'maze_models.dart';

/// Complete state of the maze game
class MazeState {
  const MazeState({
    required this.maze,
    required this.startPosition,
    required this.endPosition,
    required this.currentPosition,
    required this.difficulty,
    required this.status,
    required this.path,
    this.collectedStars = const [],
    this.timeElapsed = 0,
    this.touchedWall = false,
  });

  final List<List<MazeCell>> maze;
  final MazePosition startPosition;
  final MazePosition endPosition;
  final MazePosition? currentPosition;
  final MazeDifficulty difficulty;
  final MazeGameStatus status;
  final List<MazePosition> path; // User's drawn path
  final List<MazePosition> collectedStars;
  final int timeElapsed; // in seconds
  final bool touchedWall;

  int get gridSize => maze.length;
  int get requiredStars => difficulty.requiredStars;
  int get starsCollected => collectedStars.length;
  bool get hasCollectedAllStars => starsCollected >= requiredStars;

  int? get timeRemaining {
    final limit = difficulty.timeLimit;
    if (limit == null) return null;
    return limit - timeElapsed;
  }

  bool get isTimeUp {
    final remaining = timeRemaining;
    return remaining != null && remaining <= 0;
  }

  MazeCell getCell(MazePosition pos) {
    return maze[pos.row][pos.col];
  }

  bool isValidPosition(MazePosition pos) {
    return pos.row >= 0 &&
        pos.row < gridSize &&
        pos.col >= 0 &&
        pos.col < gridSize;
  }

  MazeState copyWith({
    List<List<MazeCell>>? maze,
    MazePosition? startPosition,
    MazePosition? endPosition,
    MazePosition? currentPosition,
    MazeDifficulty? difficulty,
    MazeGameStatus? status,
    List<MazePosition>? path,
    List<MazePosition>? collectedStars,
    int? timeElapsed,
    bool? touchedWall,
  }) {
    return MazeState(
      maze: maze ?? this.maze,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      path: path ?? this.path,
      collectedStars: collectedStars ?? this.collectedStars,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      touchedWall: touchedWall ?? this.touchedWall,
    );
  }
}
