import 'package:equatable/equatable.dart';
import 'tile_model.dart';

class Board extends Equatable {
  const Board({
    required this.size,
    required this.tiles,
    required this.score,
  });

  factory Board.empty({int size = 4}) {
    return Board(
      size: size,
      tiles: const [],
      score: 0,
    );
  }

  final int size;
  final List<Tile> tiles;
  final int score;

  Board copyWith({
    int? size,
    List<Tile>? tiles,
    int? score,
  }) {
    return Board(
      size: size ?? this.size,
      tiles: tiles ?? this.tiles,
      score: score ?? this.score,
    );
  }

  bool isCellEmpty(int row, int col) {
    return !tiles.any((tile) => tile.row == row && tile.col == col);
  }

  List<Position> getEmptyPositions() {
    final List<Position> empty = [];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (isCellEmpty(row, col)) {
          empty.add(Position(row: row, col: col));
        }
      }
    }
    return empty;
  }

  Tile? getTileAt(int row, int col) {
    try {
      return tiles.firstWhere((tile) => tile.row == row && tile.col == col);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [size, tiles, score];
}

class Position {
  Position({required this.row, required this.col});
  final int row;
  final int col;
}

