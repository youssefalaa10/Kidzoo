import 'package:flutter/material.dart';

/// Represents a point/dot on the grid
class DotPosition {
  DotPosition(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DotPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Dot($row, $col)';
}

/// Represents a line between two dots
class Line {
  Line(this.start, this.end, {this.ownedBy});

  final DotPosition start;
  final DotPosition end;
  Player? ownedBy;

  bool get isHorizontal => start.row == end.row;
  bool get isVertical => start.col == end.col;

  /// Get a unique identifier for this line
  String get id {
    // Ensure consistent ordering for horizontal and vertical lines
    if (isHorizontal) {
      final minCol = start.col < end.col ? start.col : end.col;
      final maxCol = start.col > end.col ? start.col : end.col;
      return 'h_${start.row}_${minCol}_$maxCol';
    } else {
      final minRow = start.row < end.row ? start.row : end.row;
      final maxRow = start.row > end.row ? start.row : end.row;
      return 'v_${minRow}_${maxRow}_${start.col}';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Line && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Line($start -> $end, owner: $ownedBy)';
}

/// Represents a box/square in the grid
class Box {
  Box(this.topLeft, {this.ownedBy});

  final DotPosition topLeft;
  Player? ownedBy;

  /// Get the four lines that make up this box
  List<Line> getLines() {
    final top = Line(topLeft, DotPosition(topLeft.row, topLeft.col + 1));
    final right =
        Line(DotPosition(topLeft.row, topLeft.col + 1), DotPosition(topLeft.row + 1, topLeft.col + 1));
    final bottom =
        Line(DotPosition(topLeft.row + 1, topLeft.col + 1), DotPosition(topLeft.row + 1, topLeft.col));
    final left = Line(DotPosition(topLeft.row + 1, topLeft.col), topLeft);

    return [top, right, bottom, left];
  }

  @override
  String toString() => 'Box($topLeft, owner: $ownedBy)';
}

/// Represents a player in the game
enum Player {
  player1,
  player2;

  String get displayName {
    switch (this) {
      case Player.player1:
        return 'Player 1';
      case Player.player2:
        return 'Player 2';
    }
  }

  Color get color {
    switch (this) {
      case Player.player1:
        return const Color(0xFF2196F3); // Blue
      case Player.player2:
        return const Color(0xFFE91E63); // Pink
    }
  }

  Color get lightColor {
    switch (this) {
      case Player.player1:
        return const Color(0xFFBBDEFB); // Light Blue
      case Player.player2:
        return const Color(0xFFF8BBD0); // Light Pink
    }
  }

  Player get opponent {
    switch (this) {
      case Player.player1:
        return Player.player2;
      case Player.player2:
        return Player.player1;
    }
  }
}

/// Game difficulty levels
enum GameDifficulty {
  easy, // 3x3 grid (4 dots x 4 dots)
  medium, // 4x4 grid (5 dots x 5 dots)
  hard; // 5x5 grid (6 dots x 6 dots)

  int get gridSize {
    switch (this) {
      case GameDifficulty.easy:
        return 3;
      case GameDifficulty.medium:
        return 4;
      case GameDifficulty.hard:
        return 5;
    }
  }

  int get dotCount => gridSize + 1;

  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy (3×3)';
      case GameDifficulty.medium:
        return 'Medium (4×4)';
      case GameDifficulty.hard:
        return 'Hard (5×5)';
    }
  }
}

/// Game mode
enum GameMode {
  vsPlayer,
  vsAI;

  String get displayName {
    switch (this) {
      case GameMode.vsPlayer:
        return 'VS Player';
      case GameMode.vsAI:
        return 'VS AI';
    }
  }
}

/// AI Difficulty
enum AIDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case AIDifficulty.easy:
        return 'Easy';
      case AIDifficulty.medium:
        return 'Medium';
      case AIDifficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case AIDifficulty.easy:
        return 'AI makes random moves';
      case AIDifficulty.medium:
        return 'AI uses basic strategy';
      case AIDifficulty.hard:
        return 'AI plays optimally';
    }
  }
}

/// Game status
enum GameStatus {
  playing,
  finished;
}

