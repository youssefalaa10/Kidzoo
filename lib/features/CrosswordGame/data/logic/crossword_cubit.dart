import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/crossword_models.dart';
import 'crossword_state.dart';
import 'crossword_storage.dart';

class CrosswordCubit extends Cubit<CrosswordGameState> {
  CrosswordCubit(CrosswordPuzzle puzzle)
      : _storage = CrosswordStorage(),
        super(CrosswordGameState(
          puzzle: puzzle,
          grid: _initializeGrid(puzzle),
        )) {
    _startTimer();
  }

  final CrosswordStorage _storage;
  Timer? _timer;

  static List<List<CrosswordCell>> _initializeGrid(CrosswordPuzzle puzzle) {
    return puzzle.grid.map((row) => row.map((cell) => cell).toList()).toList();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isCompleted) {
        emit(state.copyWith(timeSpent: state.timeSpent + 1));
      }
    });
  }

  void selectCell(int row, int col) {
    final cell = state.grid[row][col];
    if (cell.isBlocked) return;

    // Toggle direction if same cell tapped
    final isAcross = (state.selectedRow == row && state.selectedCol == col)
        ? !state.isAcrossMode
        : state.isAcrossMode;

    // Find current clue
    final clue = _findClueForCell(row, col, isAcross);

    // Get highlighted cells for current word
    final highlighted = _getHighlightedCellsForClue(clue);

    emit(state.copyWith(
      selectedRow: row,
      selectedCol: col,
      isAcrossMode: isAcross,
      currentClue: clue,
      highlightedCells: highlighted,
    ));
  }

  List<List<int>> _getHighlightedCellsForClue(CrosswordClue? clue) {
    if (clue == null) return [];

    final cells = <List<int>>[];
    if (clue.isAcross) {
      for (var c = clue.col; c < clue.col + clue.length; c++) {
        cells.add([clue.row, c]);
      }
    } else {
      for (var r = clue.row; r < clue.row + clue.length; r++) {
        cells.add([r, clue.col]);
      }
    }
    return cells;
  }

  CrosswordClue? _findClueForCell(int row, int col, bool isAcross) {
    final clues = isAcross ? state.puzzle.acrossClues : state.puzzle.downClues;

    for (final clue in clues) {
      if (isAcross) {
        if (row == clue.row &&
            col >= clue.col &&
            col < clue.col + clue.length) {
          return clue;
        }
      } else {
        if (col == clue.col &&
            row >= clue.row &&
            row < clue.row + clue.length) {
          return clue;
        }
      }
    }
    return null;
  }

  void enterLetter(String letter) {
    if (state.selectedRow == null || state.selectedCol == null) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;

    // Update cell with letter
    final newGrid = state.grid.map((r) => r.map((c) => c).toList()).toList();
    newGrid[row][col] = newGrid[row][col].copyWith(userLetter: letter);

    emit(state.copyWith(grid: newGrid));

    // Auto-advance to next cell
    _moveToNextCell();

    // Check if puzzle is complete
    _checkCompletion();

    // Save progress
    _saveProgress();
  }

  void deleteLetter() {
    if (state.selectedRow == null || state.selectedCol == null) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;

    final newGrid = state.grid.map((r) => r.map((c) => c).toList()).toList();
    newGrid[row][col] = newGrid[row][col].copyWith(userLetter: null);

    emit(state.copyWith(grid: newGrid));
    _saveProgress();
  }

  void _moveToNextCell() {
    if (state.selectedRow == null || state.selectedCol == null) return;

    var row = state.selectedRow!;
    var col = state.selectedCol!;

    if (state.isAcrossMode) {
      col++;
      while (col < state.puzzle.cols) {
        if (!state.grid[row][col].isBlocked) {
          selectCell(row, col);
          return;
        }
        col++;
      }
    } else {
      row++;
      while (row < state.puzzle.rows) {
        if (!state.grid[row][col].isBlocked) {
          selectCell(row, col);
          return;
        }
        row++;
      }
    }
  }

  void checkWord() {
    if (state.currentClue == null) return;

    final clue = state.currentClue!;
    final userAnswer = _getWordFromClue(clue);
    final correctAnswer = clue.answer;

    if (userAnswer == correctAnswer) {
      emit(state.copyWith(
        score: state.score + (correctAnswer.length * 10),
        message: '🎉 رائع! إجابة صحيحة!',
      ));
      Future<void>.delayed(const Duration(seconds: 1), () {
        emit(state.copyWith(message: null));
      });
    } else if (userAnswer.isEmpty) {
      emit(state.copyWith(
        message: '💭 املأ الكلمة أولاً',
      ));
      Future<void>.delayed(const Duration(seconds: 1), () {
        emit(state.copyWith(message: null));
      });
    } else {
      // No penalty for kids - just encouragement!
      emit(state.copyWith(
        message: '🤔 حاول مرة أخرى، أنت قريب!',
      ));
      Future<void>.delayed(const Duration(seconds: 2), () {
        emit(state.copyWith(message: null));
      });
    }
  }

  String _getWordFromClue(CrosswordClue clue) {
    final buffer = StringBuffer();
    if (clue.isAcross) {
      for (var c = clue.col; c < clue.col + clue.length; c++) {
        final cell = state.grid[clue.row][c];
        buffer.write(cell.userLetter ?? '');
      }
    } else {
      for (var r = clue.row; r < clue.row + clue.length; r++) {
        final cell = state.grid[r][clue.col];
        buffer.write(cell.userLetter ?? '');
      }
    }
    return buffer.toString();
  }

  void giveHint() {
    if (state.currentClue == null) {
      emit(state.copyWith(message: 'اختر كلمة أولاً'));
      Future<void>.delayed(const Duration(seconds: 1), () {
        emit(state.copyWith(message: null));
      });
      return;
    }

    final clue = state.currentClue!;
    final newGrid = state.grid.map((r) => r.map((c) => c).toList()).toList();

    // Find first incorrect cell in current word
    int? hintRow;
    int? hintCol;

    if (clue.isAcross) {
      for (var c = clue.col; c < clue.col + clue.length; c++) {
        final cell = newGrid[clue.row][c];
        if (cell.userLetter != cell.letter) {
          hintRow = clue.row;
          hintCol = c;
          break;
        }
      }
    } else {
      for (var r = clue.row; r < clue.row + clue.length; r++) {
        final cell = newGrid[r][clue.col];
        if (cell.userLetter != cell.letter) {
          hintRow = r;
          hintCol = clue.col;
          break;
        }
      }
    }

    if (hintRow == null || hintCol == null) {
      emit(state.copyWith(message: 'الكلمة صحيحة بالفعل!'));
      Future<void>.delayed(const Duration(seconds: 1), () {
        emit(state.copyWith(message: null));
      });
      return;
    }

    final cell = newGrid[hintRow][hintCol];
    newGrid[hintRow][hintCol] = cell.copyWith(userLetter: cell.letter);

    final direction = clue.isAcross ? 'أفقي' : 'عمودي';
    emit(state.copyWith(
      grid: newGrid,
      hintsUsed: state.hintsUsed + 1,
      score: state.score > 5 ? state.score - 5 : 0,
      message: 'تلميح ($direction): ${cell.letter}',
    ));

    Future<void>.delayed(const Duration(seconds: 1), () {
      emit(state.copyWith(message: null));
    });

    _checkCompletion();
    _saveProgress();
  }

  void _checkCompletion() {
    for (final row in state.grid) {
      for (final cell in row) {
        if (!cell.isBlocked && !cell.isCorrect) {
          return; // Not complete yet
        }
      }
    }

    // Puzzle complete!
    _timer?.cancel();

    // Big bonus for kids to encourage them!
    final bonusScore = 100 + (state.hintsUsed < 3 ? 50 : 0);

    emit(state.copyWith(
      isCompleted: true,
      score: state.score + bonusScore,
    ));

    _storage.markCompleted(state.puzzle.id, state.score);
  }

  Future<void> _saveProgress() async {
    final progress = CrosswordProgress(
      puzzleId: state.puzzle.id,
      grid: state.grid,
      score: state.score,
      hintsUsed: state.hintsUsed,
      isCompleted: state.isCompleted,
      timeSpent: state.timeSpent,
    );
    await _storage.saveProgress(progress);
  }

  void revealSolution() {
    final newGrid = <List<CrosswordCell>>[];
    for (var r = 0; r < state.puzzle.rows; r++) {
      final row = <CrosswordCell>[];
      for (var c = 0; c < state.puzzle.cols; c++) {
        final cell = state.grid[r][c];
        row.add(cell.copyWith(userLetter: cell.letter));
      }
      newGrid.add(row);
    }

    emit(state.copyWith(
      grid: newGrid,
      score: 0,
      message: 'تم عرض الحل',
    ));
  }

  void toggleDirection() {
    if (state.selectedRow != null && state.selectedCol != null) {
      selectCell(state.selectedRow!, state.selectedCol!);
    } else {
      emit(state.copyWith(isAcrossMode: !state.isAcrossMode));
    }
  }

  void autoFillWord() {
    if (state.currentClue == null) return;

    final clue = state.currentClue!;
    final newGrid = state.grid.map((r) => r.map((c) => c).toList()).toList();

    if (clue.isAcross) {
      for (var c = clue.col; c < clue.col + clue.length; c++) {
        final cell = newGrid[clue.row][c];
        newGrid[clue.row][c] = cell.copyWith(userLetter: cell.letter);
      }
    } else {
      for (var r = clue.row; r < clue.row + clue.length; r++) {
        final cell = newGrid[r][clue.col];
        newGrid[r][clue.col] = cell.copyWith(userLetter: cell.letter);
      }
    }

    // No penalty - help kids learn!
    emit(state.copyWith(
      grid: newGrid,
      hintsUsed: state.hintsUsed + clue.length,
      message: '✨ تم تعبئة الكلمة! جيد!',
    ));

    Future<void>.delayed(const Duration(seconds: 1), () {
      emit(state.copyWith(message: null));
    });

    _checkCompletion();
    _saveProgress();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
