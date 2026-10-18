import 'dart:math';
import '../models/maze_models.dart';

class MazeGenerator {
  final Random _random = Random();

  /// Generate a maze based on difficulty
  List<List<MazeCell>> generate(MazeDifficulty difficulty) {
    final size = difficulty.gridSize;
    final maze = _initializeMaze(size);

    // Generate maze using Recursive Backtracking
    _generateMazeRecursive(maze, const MazePosition(0, 0));

    // Add stars for medium and hard difficulties
    if (difficulty.requiredStars > 0) {
      _placeStars(maze, difficulty.requiredStars, size);
    }

    // Add some complexity for hard difficulty
    if (difficulty == MazeDifficulty.hard) {
      _addDeadEnds(maze, size);
    }

    return maze;
  }

  /// Initialize maze grid with all walls
  List<List<MazeCell>> _initializeMaze(int size) {
    return List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => MazeCell(position: MazePosition(row, col)),
      ),
    );
  }

  /// Recursive backtracking algorithm to generate maze
  void _generateMazeRecursive(List<List<MazeCell>> maze, MazePosition current) {
    final size = maze.length;
    maze[current.row][current.col].isVisited = true;

    // Get unvisited neighbors in random order
    final neighbors = _getUnvisitedNeighbors(maze, current, size);
    neighbors.shuffle(_random);

    for (final neighbor in neighbors) {
      if (!maze[neighbor.row][neighbor.col].isVisited) {
        // Remove wall between current and neighbor
        _removeWallBetween(maze, current, neighbor);

        // Recursively visit neighbor
        _generateMazeRecursive(maze, neighbor);
      }
    }
  }

  /// Get unvisited neighbors of a cell
  List<MazePosition> _getUnvisitedNeighbors(
    List<List<MazeCell>> maze,
    MazePosition pos,
    int size,
  ) {
    final neighbors = <MazePosition>[];

    // Top
    if (pos.row > 0 && !maze[pos.row - 1][pos.col].isVisited) {
      neighbors.add(MazePosition(pos.row - 1, pos.col));
    }
    // Bottom
    if (pos.row < size - 1 && !maze[pos.row + 1][pos.col].isVisited) {
      neighbors.add(MazePosition(pos.row + 1, pos.col));
    }
    // Left
    if (pos.col > 0 && !maze[pos.row][pos.col - 1].isVisited) {
      neighbors.add(MazePosition(pos.row, pos.col - 1));
    }
    // Right
    if (pos.col < size - 1 && !maze[pos.row][pos.col + 1].isVisited) {
      neighbors.add(MazePosition(pos.row, pos.col + 1));
    }

    return neighbors;
  }

  /// Remove wall between two adjacent cells
  void _removeWallBetween(
    List<List<MazeCell>> maze,
    MazePosition current,
    MazePosition neighbor,
  ) {
    final rowDiff = neighbor.row - current.row;
    final colDiff = neighbor.col - current.col;

    if (rowDiff == -1) {
      // Neighbor is above
      maze[current.row][current.col].topWall = false;
      maze[neighbor.row][neighbor.col].bottomWall = false;
    } else if (rowDiff == 1) {
      // Neighbor is below
      maze[current.row][current.col].bottomWall = false;
      maze[neighbor.row][neighbor.col].topWall = false;
    } else if (colDiff == -1) {
      // Neighbor is to the left
      maze[current.row][current.col].leftWall = false;
      maze[neighbor.row][neighbor.col].rightWall = false;
    } else if (colDiff == 1) {
      // Neighbor is to the right
      maze[current.row][current.col].rightWall = false;
      maze[neighbor.row][neighbor.col].leftWall = false;
    }
  }

  /// Place stars in the maze
  void _placeStars(List<List<MazeCell>> maze, int count, int size) {
    final positions = <MazePosition>[];

    // Avoid start (0,0) and end positions
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if ((row != 0 || col != 0) && (row != size - 1 || col != size - 1)) {
          positions.add(MazePosition(row, col));
        }
      }
    }

    positions.shuffle(_random);

    // Place stars ensuring they're well distributed
    for (int i = 0; i < count && i < positions.length; i++) {
      final pos = positions[i * (positions.length ~/ count)];
      maze[pos.row][pos.col].hasStar = true;
    }
  }

  /// Add some dead ends for increased difficulty
  void _addDeadEnds(List<List<MazeCell>> maze, int size) {
    final deadEndCount = size ~/ 2;

    for (int i = 0; i < deadEndCount; i++) {
      final row = _random.nextInt(size);
      final col = _random.nextInt(size);

      // Skip start and end positions
      if ((row == 0 && col == 0) || (row == size - 1 && col == size - 1)) {
        continue;
      }

      // Randomly add a wall to create a dead end
      final wallChoice = _random.nextInt(4);
      switch (wallChoice) {
        case 0:
          if (row > 0) maze[row][col].topWall = true;
          break;
        case 1:
          if (col < size - 1) maze[row][col].rightWall = true;
          break;
        case 2:
          if (row < size - 1) maze[row][col].bottomWall = true;
          break;
        case 3:
          if (col > 0) maze[row][col].leftWall = true;
          break;
      }
    }
  }
}
