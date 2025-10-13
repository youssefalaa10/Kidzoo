import 'dart:math';

import '../models/board_model.dart';
import '../models/tile_model.dart';

enum SwipeDirection { up, down, left, right }

class GameLogic {
  static const double _probability4 = 0.1; // 10% chance of generating 4

  // Initialize a new board with two random tiles
  static Board initializeBoard({int size = 4}) {
    final board = Board.empty(size: size);
    var updatedBoard = _addRandomTile(board);
    updatedBoard = _addRandomTile(updatedBoard);
    return updatedBoard;
  }

  // Add a random tile (2 or 4) to an empty position
  static Board _addRandomTile(Board board) {
    final emptyPositions = board.getEmptyPositions();
    if (emptyPositions.isEmpty) return board;

    final random = Random();
    final position = emptyPositions[random.nextInt(emptyPositions.length)];
    final value = random.nextDouble() < _probability4 ? 4 : 2;

    final newTile = Tile(
      value: value,
      row: position.row,
      col: position.col,
      isNew: true,
    );

    return board.copyWith(tiles: [...board.tiles, newTile]);
  }

  // Main move function
  static MoveResult move(Board board, SwipeDirection direction) {
    // First, clear animation flags from all existing tiles
    final cleanBoard = board.copyWith(
      tiles: board.tiles
          .map((tile) => tile.copyWith(
                isNew: false,
                merged: false,
                previousRow: null,
                previousCol: null,
              ))
          .toList(),
    );

    final rotatedBoard = _rotateBoard(cleanBoard, direction);
    final result = _moveLeft(rotatedBoard);

    if (!result.moved) {
      return MoveResult(board: cleanBoard, moved: false, scoreGained: 0);
    }

    final unrotatedBoard = _unrotateBoard(result.board, direction);
    final boardWithNewTile = _addRandomTile(unrotatedBoard);

    return MoveResult(
      board: boardWithNewTile,
      moved: true,
      scoreGained: result.scoreGained,
    );
  }

  // Rotate the board to make all movements equivalent to left movement
  static Board _rotateBoard(Board board, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return board;
      case SwipeDirection.right:
        return _flipHorizontal(board);
      case SwipeDirection.up:
        return _transpose(board);
      case SwipeDirection.down:
        return _flipHorizontal(_transpose(board));
    }
  }

  // Unrotate after movement
  static Board _unrotateBoard(Board board, SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return board;
      case SwipeDirection.right:
        return _flipHorizontal(board);
      case SwipeDirection.up:
        return _transpose(board);
      case SwipeDirection.down:
        return _transpose(_flipHorizontal(board));
    }
  }

  // Core left movement logic
  static MoveResult _moveLeft(Board board) {
    final newTiles = <Tile>[];
    var scoreGained = 0;
    var moved = false;

    for (var row = 0; row < board.size; row++) {
      final rowTiles = board.tiles.where((tile) => tile.row == row).toList()
        ..sort((a, b) => a.col.compareTo(b.col));

      final compressed = _compressAndMerge(rowTiles, row);
      newTiles.addAll(compressed.tiles);
      scoreGained += compressed.scoreGained;

      // Check if any tile moved
      for (var i = 0; i < compressed.tiles.length; i++) {
        if (compressed.tiles[i].col != rowTiles[i].col ||
            compressed.tiles[i].value != rowTiles[i].value) {
          moved = true;
        }
      }

      // Check if number of tiles changed (merge happened)
      if (compressed.tiles.length != rowTiles.length) {
        moved = true;
      }
    }

    return MoveResult(
      board: board.copyWith(
        tiles: newTiles,
        score: board.score + scoreGained,
      ),
      moved: moved,
      scoreGained: scoreGained,
    );
  }

  // Compress and merge a single row
  static CompressResult _compressAndMerge(List<Tile> tiles, int row) {
    if (tiles.isEmpty) return CompressResult(tiles: [], scoreGained: 0);

    final compressed = <Tile>[];
    var scoreGained = 0;
    var col = 0;
    var i = 0;

    while (i < tiles.length) {
      final currentTile = tiles[i];

      // Check if we can merge with next tile
      if (i + 1 < tiles.length && tiles[i].value == tiles[i + 1].value) {
        final mergedValue = currentTile.value * 2;
        compressed.add(
          Tile(
            value: mergedValue,
            row: row,
            col: col,
            merged: true,
            previousRow: currentTile.row,
            previousCol: currentTile.col,
          ),
        );
        scoreGained += mergedValue;
        i += 2; // Skip the merged tile
      } else {
        compressed.add(
          currentTile.copyWith(
            row: row,
            col: col,
            merged: false,
            previousRow: currentTile.row,
            previousCol: currentTile.col,
          ),
        );
        i++;
      }
      col++;
    }

    return CompressResult(tiles: compressed, scoreGained: scoreGained);
  }

  // Helper functions for board transformations
  static Board _flipHorizontal(Board board) {
    final flippedTiles = board.tiles.map((tile) {
      return tile.copyWith(
        col: board.size - 1 - tile.col,
        previousCol: tile.previousCol != null
            ? board.size - 1 - tile.previousCol!
            : null,
      );
    }).toList();
    return board.copyWith(tiles: flippedTiles);
  }

  static Board _transpose(Board board) {
    final transposedTiles = board.tiles.map((tile) {
      return tile.copyWith(
        row: tile.col,
        col: tile.row,
        previousRow: tile.previousCol,
        previousCol: tile.previousRow,
      );
    }).toList();
    return board.copyWith(tiles: transposedTiles);
  }

  // Check if there are any valid moves left
  static bool hasValidMoves(Board board) {
    // Check for empty cells
    if (board.getEmptyPositions().isNotEmpty) return true;

    // Check for possible merges horizontally and vertically
    for (var row = 0; row < board.size; row++) {
      for (var col = 0; col < board.size; col++) {
        final tile = board.getTileAt(row, col);
        if (tile == null) continue;

        // Check right neighbor
        if (col < board.size - 1) {
          final rightTile = board.getTileAt(row, col + 1);
          if (rightTile != null && rightTile.value == tile.value) return true;
        }

        // Check bottom neighbor
        if (row < board.size - 1) {
          final bottomTile = board.getTileAt(row + 1, col);
          if (bottomTile != null && bottomTile.value == tile.value) return true;
        }
      }
    }

    return false;
  }

  // Check if the player has won (reached target tile)
  static bool hasWon(Board board, {int targetTile = 2048}) {
    return board.tiles.any((tile) => tile.value >= targetTile);
  }

  // Get the maximum tile value on the board
  static int getMaxTileValue(Board board) {
    if (board.tiles.isEmpty) return 0;
    return board.tiles.map((tile) => tile.value).reduce(max);
  }
}

class MoveResult {
  MoveResult({
    required this.board,
    required this.moved,
    required this.scoreGained,
  });

  final Board board;
  final bool moved;
  final int scoreGained;
}

class CompressResult {
  CompressResult({
    required this.tiles,
    required this.scoreGained,
  });

  final List<Tile> tiles;
  final int scoreGained;
}
