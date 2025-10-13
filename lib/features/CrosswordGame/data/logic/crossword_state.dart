import 'package:equatable/equatable.dart';

import '../models/crossword_models.dart';

class CrosswordGameState extends Equatable {
  const CrosswordGameState({
    required this.puzzle,
    required this.grid,
    this.selectedRow,
    this.selectedCol,
    this.isAcrossMode = true,
    this.currentClue,
    this.score = 0,
    this.hintsUsed = 0,
    this.isCompleted = false,
    this.timeSpent = 0,
    this.message,
    this.highlightedCells = const [],
  });

  final CrosswordPuzzle puzzle;
  final List<List<CrosswordCell>> grid;
  final int? selectedRow;
  final int? selectedCol;
  final bool isAcrossMode;
  final CrosswordClue? currentClue;
  final int score;
  final int hintsUsed;
  final bool isCompleted;
  final int timeSpent;
  final String? message;
  final List<List<int>> highlightedCells; // List of [row, col] positions

  CrosswordGameState copyWith({
    List<List<CrosswordCell>>? grid,
    Object? selectedRow = _undefined,
    Object? selectedCol = _undefined,
    bool? isAcrossMode,
    Object? currentClue = _undefined,
    int? score,
    int? hintsUsed,
    bool? isCompleted,
    int? timeSpent,
    Object? message = _undefined,
    List<List<int>>? highlightedCells,
  }) {
    return CrosswordGameState(
      puzzle: puzzle,
      grid: grid ?? this.grid,
      selectedRow:
          selectedRow == _undefined ? this.selectedRow : selectedRow as int?,
      selectedCol:
          selectedCol == _undefined ? this.selectedCol : selectedCol as int?,
      isAcrossMode: isAcrossMode ?? this.isAcrossMode,
      currentClue: currentClue == _undefined
          ? this.currentClue
          : currentClue as CrosswordClue?,
      score: score ?? this.score,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isCompleted: isCompleted ?? this.isCompleted,
      timeSpent: timeSpent ?? this.timeSpent,
      message: message == _undefined ? this.message : message as String?,
      highlightedCells: highlightedCells ?? this.highlightedCells,
    );
  }

  static const _undefined = Object();

  @override
  List<Object?> get props => [
        puzzle,
        grid,
        selectedRow,
        selectedCol,
        isAcrossMode,
        currentClue,
        score,
        hintsUsed,
        isCompleted,
        timeSpent,
        message,
        highlightedCells,
      ];
}
