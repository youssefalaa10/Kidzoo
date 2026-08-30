import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/dots_and_boxes_models.dart';
import '../models/game_state_model.dart';

class DotsAndBoxesCubit extends Cubit<DotsAndBoxesState> {
  DotsAndBoxesCubit({
    GameDifficulty difficulty = GameDifficulty.easy,
    GameMode gameMode = GameMode.vsPlayer,
    AIDifficulty aiDifficulty = AIDifficulty.medium,
  }) : super(DotsAndBoxesState.initial(
          difficulty: difficulty,
          gameMode: gameMode,
          aiDifficulty: aiDifficulty,
        ));

  final Random _random = Random();

  /// Start a new game
  void newGame({
    GameDifficulty? difficulty,
    GameMode? gameMode,
    AIDifficulty? aiDifficulty,
  }) {
    emit(DotsAndBoxesState.initial(
      difficulty: difficulty ?? state.difficulty,
      gameMode: gameMode ?? state.gameMode,
      aiDifficulty: aiDifficulty ?? state.aiDifficulty,
    ));
  }

  /// Draw a line between two dots
  void drawLine(DotPosition start, DotPosition end) {
    if (state.status != GameStatus.playing) return;

    // Validate the line
    if (!_isValidLine(start, end)) return;

    final line = Line(start, end, ownedBy: state.currentPlayer);

    // Check if line is already drawn
    if (state.isLineDrawn(line)) return;

    // Add the line
    final newLines = Map<String, Line>.from(state.lines);
    newLines[line.id] = line;

    // Check if any boxes were completed
    final completedBoxes = _checkCompletedBoxes(line, newLines);

    // Update boxes
    final newBoxes = List<Box>.from(state.boxes);
    for (final box in completedBoxes) {
      final index = newBoxes.indexWhere(
        (b) =>
            b.topLeft.row == box.topLeft.row &&
            b.topLeft.col == box.topLeft.col,
      );
      if (index != -1) {
        newBoxes[index].ownedBy = state.currentPlayer;
      }
    }

    // Update scores
    int newPlayer1Score = state.player1Score;
    int newPlayer2Score = state.player2Score;

    if (state.currentPlayer == Player.player1) {
      newPlayer1Score += completedBoxes.length;
    } else {
      newPlayer2Score += completedBoxes.length;
    }

    // Determine if game is over
    final totalClaimed = newPlayer1Score + newPlayer2Score;
    final isGameOver = totalClaimed == state.totalBoxes;

    // Determine winner
    Player? winner;
    if (isGameOver) {
      if (newPlayer1Score > newPlayer2Score) {
        winner = Player.player1;
      } else if (newPlayer2Score > newPlayer1Score) {
        winner = Player.player2;
      } // else it's a tie, winner remains null
    }

    // Switch player only if no box was completed
    final nextPlayer = completedBoxes.isEmpty
        ? state.currentPlayer.opponent
        : state.currentPlayer;

    // Update combo tracking
    final newCombo = completedBoxes.isNotEmpty
        ? state.currentCombo + completedBoxes.length
        : 0;
    final newMaxCombo = newCombo > state.maxCombo ? newCombo : state.maxCombo;

    // Increment move count
    final newMoveCount = state.moveCount + 1;

    emit(state.copyWith(
      lines: newLines,
      boxes: newBoxes,
      currentPlayer: nextPlayer,
      player1Score: newPlayer1Score,
      player2Score: newPlayer2Score,
      status: isGameOver ? GameStatus.finished : GameStatus.playing,
      winner: winner,
      lastCompletedBoxes: completedBoxes,
      currentCombo: newCombo,
      maxCombo: newMaxCombo,
      moveCount: newMoveCount,
      lastLineDrawn: line,
    ));

    // Trigger AI move if it's AI's turn and game is still playing
    if (state.gameMode == GameMode.vsAI &&
        state.currentPlayer == Player.player2 &&
        state.status == GameStatus.playing) {
      _makeAIMove();
    }
  }

  /// Validate if a line can be drawn between two dots
  bool _isValidLine(DotPosition start, DotPosition end) {
    // Line must be horizontal or vertical
    final isHorizontal =
        start.row == end.row && (start.col - end.col).abs() == 1;
    final isVertical = start.col == end.col && (start.row - end.row).abs() == 1;

    if (!isHorizontal && !isVertical) return false;

    // Check if dots are within bounds
    final dotsPerSide = state.dotsPerSide;
    if (start.row < 0 ||
        start.row >= dotsPerSide ||
        start.col < 0 ||
        start.col >= dotsPerSide ||
        end.row < 0 ||
        end.row >= dotsPerSide ||
        end.col < 0 ||
        end.col >= dotsPerSide) {
      return false;
    }

    return true;
  }

  /// Check which boxes were completed by drawing this line
  List<Box> _checkCompletedBoxes(Line newLine, Map<String, Line> allLines) {
    final completedBoxes = <Box>[];

    // Check all boxes that could potentially be completed by this line
    final boxesToCheck = _getAdjacentBoxes(newLine);

    for (final box in boxesToCheck) {
      if (_isBoxComplete(box, allLines)) {
        completedBoxes.add(box);
      }
    }

    return completedBoxes;
  }

  /// Get boxes adjacent to a line
  List<Box> _getAdjacentBoxes(Line line) {
    final boxes = <Box>[];

    if (line.isHorizontal) {
      // Check box above
      if (line.start.row > 0) {
        final topLeft = DotPosition(
          line.start.row - 1,
          min(line.start.col, line.end.col),
        );
        boxes.add(Box(topLeft));
      }
      // Check box below
      if (line.start.row < state.gridSize) {
        final topLeft = DotPosition(
          line.start.row,
          min(line.start.col, line.end.col),
        );
        boxes.add(Box(topLeft));
      }
    } else {
      // Vertical line
      // Check box to the left
      if (line.start.col > 0) {
        final topLeft = DotPosition(
          min(line.start.row, line.end.row),
          line.start.col - 1,
        );
        boxes.add(Box(topLeft));
      }
      // Check box to the right
      if (line.start.col < state.gridSize) {
        final topLeft = DotPosition(
          min(line.start.row, line.end.row),
          line.start.col,
        );
        boxes.add(Box(topLeft));
      }
    }

    return boxes;
  }

  /// Check if a box is complete (all four sides drawn)
  bool _isBoxComplete(Box box, Map<String, Line> allLines) {
    final requiredLines = box.getLines();

    for (final line in requiredLines) {
      if (!allLines.containsKey(line.id)) {
        return false;
      }
    }

    return true;
  }

  /// Make an AI move
  Future<void> _makeAIMove() async {
    // Add a small delay for better UX
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (state.status != GameStatus.playing) return;

    final move = _getBestAIMove();

    if (move != null) {
      drawLine(move.$1, move.$2);
    }
  }

  /// Get the best AI move based on difficulty
  (DotPosition, DotPosition)? _getBestAIMove() {
    final availableMoves = _getAllAvailableMoves();

    if (availableMoves.isEmpty) return null;

    switch (state.aiDifficulty) {
      case AIDifficulty.easy:
        return _getEasyAIMove(availableMoves);
      case AIDifficulty.medium:
        return _getMediumAIMove(availableMoves);
      case AIDifficulty.hard:
        return _getHardAIMove(availableMoves);
    }
  }

  /// Easy AI - mostly random with occasional box completion
  (DotPosition, DotPosition)? _getEasyAIMove(
      List<(DotPosition, DotPosition)> availableMoves) {
    // 40% chance to complete a box if possible
    if (_random.nextDouble() < 0.4) {
      for (final move in availableMoves) {
        final line = Line(move.$1, move.$2);
        final testLines = Map<String, Line>.from(state.lines);
        testLines[line.id] = line;

        final completedBoxes = _checkCompletedBoxes(line, testLines);
        if (completedBoxes.isNotEmpty) {
          return move;
        }
      }
    }

    // Otherwise random move
    return availableMoves[_random.nextInt(availableMoves.length)];
  }

  /// Medium AI - uses basic strategy
  (DotPosition, DotPosition)? _getMediumAIMove(
      List<(DotPosition, DotPosition)> availableMoves) {
    // Strategy 1: Complete a box if possible
    for (final move in availableMoves) {
      final line = Line(move.$1, move.$2);
      final testLines = Map<String, Line>.from(state.lines);
      testLines[line.id] = line;

      final completedBoxes = _checkCompletedBoxes(line, testLines);
      if (completedBoxes.isNotEmpty) {
        return move;
      }
    }

    // Strategy 2: Avoid giving opponent a box (don't draw the 3rd side)
    final safeMoves = <(DotPosition, DotPosition)>[];

    for (final move in availableMoves) {
      if (!_wouldGiveOpponentBox(move, availableMoves)) {
        safeMoves.add(move);
      }
    }

    // If we have safe moves, pick one randomly
    if (safeMoves.isNotEmpty) {
      return safeMoves[_random.nextInt(safeMoves.length)];
    }

    // Strategy 3: Random move (fallback - sometimes necessary)
    return availableMoves[_random.nextInt(availableMoves.length)];
  }

  /// Hard AI - plays optimally
  (DotPosition, DotPosition)? _getHardAIMove(
      List<(DotPosition, DotPosition)> availableMoves) {
    // Strategy 1: Complete ALL available boxes in a chain
    final boxCompletingMoves = <(DotPosition, DotPosition)>[];
    for (final move in availableMoves) {
      final line = Line(move.$1, move.$2);
      final testLines = Map<String, Line>.from(state.lines);
      testLines[line.id] = line;

      final completedBoxes = _checkCompletedBoxes(line, testLines);
      if (completedBoxes.isNotEmpty) {
        boxCompletingMoves.add(move);
      }
    }

    if (boxCompletingMoves.isNotEmpty) {
      // Return the move that completes the most boxes
      return boxCompletingMoves.reduce((best, current) {
        final bestLine = Line(best.$1, best.$2);
        final currentLine = Line(current.$1, current.$2);
        final bestLines = Map<String, Line>.from(state.lines)
          ..[bestLine.id] = bestLine;
        final currentLines = Map<String, Line>.from(state.lines)
          ..[currentLine.id] = currentLine;

        final bestBoxes = _checkCompletedBoxes(bestLine, bestLines);
        final currentBoxes = _checkCompletedBoxes(currentLine, currentLines);

        return currentBoxes.length > bestBoxes.length ? current : best;
      });
    }

    // Strategy 2: Find safest move (evaluate multiple levels deep)
    final scoredMoves = <MapEntry<(DotPosition, DotPosition), int>>[];

    for (final move in availableMoves) {
      int score = 0;

      // Negative score if it gives opponent boxes
      if (_wouldGiveOpponentBox(move, availableMoves)) {
        score -= 10;
      } else {
        score += 5; // Bonus for safe moves
      }

      // Prefer center moves early in the game
      if (state.lines.length < state.totalBoxes ~/ 3) {
        final midRow = state.gridSize ~/ 2;
        final midCol = state.gridSize ~/ 2;
        final distToCenter = (move.$1.row - midRow).abs() +
            (move.$1.col - midCol).abs() +
            (move.$2.row - midRow).abs() +
            (move.$2.col - midCol).abs();
        score -= distToCenter;
      }

      scoredMoves.add(MapEntry(move, score));
    }

    // Sort by score and pick the best
    scoredMoves.sort((a, b) => b.value.compareTo(a.value));
    return scoredMoves.first.key;
  }

  /// Check if a move would give the opponent a box
  bool _wouldGiveOpponentBox((DotPosition, DotPosition) move,
      List<(DotPosition, DotPosition)> allMoves) {
    final line = Line(move.$1, move.$2);
    final testLines = Map<String, Line>.from(state.lines);
    testLines[line.id] = line;

    // Check if any remaining move would complete a box
    for (final testMove in allMoves) {
      if (testMove == move) continue;

      final testLine = Line(testMove.$1, testMove.$2);
      final testLines2 = Map<String, Line>.from(testLines);
      testLines2[testLine.id] = testLine;

      final opponentBoxes = _checkCompletedBoxes(testLine, testLines2);
      if (opponentBoxes.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Get all available moves (lines that haven't been drawn yet)
  List<(DotPosition, DotPosition)> _getAllAvailableMoves() {
    final moves = <(DotPosition, DotPosition)>[];
    final dotsPerSide = state.dotsPerSide;

    // Check all horizontal lines
    for (int row = 0; row < dotsPerSide; row++) {
      for (int col = 0; col < dotsPerSide - 1; col++) {
        final start = DotPosition(row, col);
        final end = DotPosition(row, col + 1);
        final line = Line(start, end);

        if (!state.isLineDrawn(line)) {
          moves.add((start, end));
        }
      }
    }

    // Check all vertical lines
    for (int row = 0; row < dotsPerSide - 1; row++) {
      for (int col = 0; col < dotsPerSide; col++) {
        final start = DotPosition(row, col);
        final end = DotPosition(row + 1, col);
        final line = Line(start, end);

        if (!state.isLineDrawn(line)) {
          moves.add((start, end));
        }
      }
    }

    return moves;
  }

  /// Reset the game
  void resetGame() {
    newGame(
      difficulty: state.difficulty,
      gameMode: state.gameMode,
    );
  }

  /// Change difficulty
  void changeDifficulty(GameDifficulty difficulty) {
    newGame(difficulty: difficulty, gameMode: state.gameMode);
  }

  /// Change game mode
  void changeGameMode(GameMode mode) {
    newGame(difficulty: state.difficulty, gameMode: mode);
  }

  /// Change AI difficulty
  void changeAIDifficulty(AIDifficulty difficulty) {
    newGame(
      difficulty: state.difficulty,
      gameMode: state.gameMode,
      aiDifficulty: difficulty,
    );
  }
}
