import 'package:flutter/material.dart';

/// Position in the maze grid
class MazePosition {
  const MazePosition(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MazePosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Pos($row, $col)';

  // Get adjacent positions
  List<MazePosition> getNeighbors() {
    return [
      MazePosition(row - 1, col), // Top
      MazePosition(row + 1, col), // Bottom
      MazePosition(row, col - 1), // Left
      MazePosition(row, col + 1), // Right
    ];
  }
}

/// Represents a single cell in the maze
class MazeCell {
  MazeCell({
    required this.position,
    this.topWall = true,
    this.rightWall = true,
    this.bottomWall = true,
    this.leftWall = true,
    this.isVisited = false,
    this.isPath = false,
    this.hasStar = false,
  });

  final MazePosition position;
  bool topWall;
  bool rightWall;
  bool bottomWall;
  bool leftWall;
  bool isVisited; // For generation algorithm
  bool isPath; // User's drawn path
  bool hasStar; // Star to collect

  bool get hasAllWalls => topWall && rightWall && bottomWall && leftWall;
  bool get hasNoWalls => !topWall && !rightWall && !bottomWall && !leftWall;

  MazeCell copyWith({
    MazePosition? position,
    bool? topWall,
    bool? rightWall,
    bool? bottomWall,
    bool? leftWall,
    bool? isVisited,
    bool? isPath,
    bool? hasStar,
  }) {
    return MazeCell(
      position: position ?? this.position,
      topWall: topWall ?? this.topWall,
      rightWall: rightWall ?? this.rightWall,
      bottomWall: bottomWall ?? this.bottomWall,
      leftWall: leftWall ?? this.leftWall,
      isVisited: isVisited ?? this.isVisited,
      isPath: isPath ?? this.isPath,
      hasStar: hasStar ?? this.hasStar,
    );
  }
}

/// Game difficulty levels
enum MazeDifficulty {
  easy, // 5x5
  medium, // 10x10
  hard; // 20x20

  int get gridSize {
    switch (this) {
      case MazeDifficulty.easy:
        return 5;
      case MazeDifficulty.medium:
        return 10;
      case MazeDifficulty.hard:
        return 20;
    }
  }

  int get requiredStars {
    switch (this) {
      case MazeDifficulty.easy:
        return 0; // No stars required
      case MazeDifficulty.medium:
        return 3; // Collect 3 stars
      case MazeDifficulty.hard:
        return 5; // Collect 5 stars
    }
  }

  int? get timeLimit {
    switch (this) {
      case MazeDifficulty.easy:
        return null; // No time limit
      case MazeDifficulty.medium:
        return null; // No time limit
      case MazeDifficulty.hard:
        return 120; // 2 minutes
    }
  }

  String get displayName {
    switch (this) {
      case MazeDifficulty.easy:
        return 'سهل - Easy';
      case MazeDifficulty.medium:
        return 'متوسط - Medium';
      case MazeDifficulty.hard:
        return 'صعب - Hard';
    }
  }

  String get description {
    switch (this) {
      case MazeDifficulty.easy:
        return 'متاهة صغيرة 5×5 - طريق واضح وقصير';
      case MazeDifficulty.medium:
        return 'متاهة 10×10 - اجمع 3 نجوم';
      case MazeDifficulty.hard:
        return 'متاهة معقدة 20×20 - اجمع 5 نجوم في دقيقتين';
    }
  }

  Color get color {
    switch (this) {
      case MazeDifficulty.easy:
        return Colors.green;
      case MazeDifficulty.medium:
        return Colors.orange;
      case MazeDifficulty.hard:
        return Colors.red;
    }
  }
}

/// Game status
enum MazeGameStatus {
  playing,
  won,
  lost,
  paused;
}
