import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/maze_models.dart';
import '../models/maze_state.dart';
import 'maze_generator.dart';

class MazeCubit extends Cubit<MazeState> {
  MazeCubit({
    MazeDifficulty difficulty = MazeDifficulty.easy,
  }) : super(_generateInitialState(difficulty)) {
    _startTimer();
  }

  Timer? _timer;

  static MazeState _generateInitialState(MazeDifficulty difficulty) {
    final generator = MazeGenerator();
    final maze = generator.generate(difficulty);
    final size = maze.length;

    return MazeState(
      maze: maze,
      startPosition: const MazePosition(0, 0),
      endPosition: MazePosition(size - 1, size - 1),
      currentPosition: null,
      difficulty: difficulty,
      status: MazeGameStatus.playing,
      path: [],
    );
  }

  void _startTimer() {
    _timer?.cancel();
    if (state.difficulty.timeLimit != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.status == MazeGameStatus.playing) {
          emit(state.copyWith(timeElapsed: state.timeElapsed + 1));

          // Check if time is up
          if (state.isTimeUp) {
            gameOver(false);
          }
        }
      });
    }
  }

  void startDrawing(MazePosition position) {
    if (state.status != MazeGameStatus.playing) return;

    // Must start at the start position
    if (position == state.startPosition) {
      emit(state.copyWith(
        currentPosition: position,
        path: [position],
        touchedWall: false,
      ));
    }
  }

  void continueDrawing(MazePosition position) {
    if (state.status != MazeGameStatus.playing) return;
    if (state.currentPosition == null) return;

    final current = state.currentPosition!;

    // Check if position is adjacent to current
    if (!_isAdjacent(current, position)) return;

    // Check if there's a wall between current and next position
    if (_hasWallBetween(current, position)) {
      // Prevent moving through the wall, but don't end the game immediately for better gameplay
      return;
    }

    // Valid move
    final newPath = List<MazePosition>.from(state.path);

    // Check if backtracking
    if (newPath.length > 1 && newPath[newPath.length - 2] == position) {
      newPath.removeLast(); // Remove current position, move back
    } else {
      newPath.add(position);
    }
    final newCollected = List<MazePosition>.from(state.collectedStars);

    // Check if collecting a star
    final cell = state.getCell(position);
    if (cell.hasStar && !newCollected.contains(position)) {
      newCollected.add(position);
    }

    emit(state.copyWith(
      currentPosition: position,
      path: newPath,
      collectedStars: newCollected,
    ));

    // Check win condition immediately when reaching end with all stars
    _checkWinCondition();
  }

  void endDrawing() {
    // Check win condition one more time when drawing ends
    _checkWinCondition();
    // Keep the current position so path stays visible
    emit(state.copyWith());
  }

  void _checkWinCondition() {
    if (state.status != MazeGameStatus.playing) return;

    if (state.currentPosition == state.endPosition &&
        state.hasCollectedAllStars) {
      // Small delay to show the completion visually
      Future.delayed(const Duration(milliseconds: 300), () {
        if (state.status == MazeGameStatus.playing) {
          gameOver(true);
        }
      });
    }
  }

  void gameOver(bool won) {
    _timer?.cancel();
    final newStatus = won ? MazeGameStatus.won : MazeGameStatus.lost;
    emit(state.copyWith(
      status: newStatus,
    ));
  }

  void pauseGame() {
    _timer?.cancel();
    emit(state.copyWith(status: MazeGameStatus.paused));
  }

  void resumeGame() {
    if (state.status == MazeGameStatus.paused) {
      emit(state.copyWith(status: MazeGameStatus.playing));
      _startTimer();
    }
  }

  void resetGame() {
    _timer?.cancel();
    final newState = _generateInitialState(state.difficulty);
    emit(newState);
    _startTimer();
  }

  void newGame(MazeDifficulty difficulty) {
    _timer?.cancel();
    final newState = _generateInitialState(difficulty);
    emit(newState);
    _startTimer();
  }

  bool _isAdjacent(MazePosition pos1, MazePosition pos2) {
    final rowDiff = (pos1.row - pos2.row).abs();
    final colDiff = (pos1.col - pos2.col).abs();
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  bool _hasWallBetween(MazePosition current, MazePosition next) {
    final cell = state.getCell(current);
    final rowDiff = next.row - current.row;
    final colDiff = next.col - current.col;

    if (rowDiff == -1) return cell.topWall;
    if (rowDiff == 1) return cell.bottomWall;
    if (colDiff == -1) return cell.leftWall;
    if (colDiff == 1) return cell.rightWall;

    return true; // Shouldn't happen
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
