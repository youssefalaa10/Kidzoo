import 'package:equatable/equatable.dart';

enum Difficulty { easy, medium, hard }

enum CellStatus { empty, filled, correct, incorrect }

class CrosswordClue extends Equatable {
  factory CrosswordClue.fromJson(Map<String, dynamic> json, bool isAcross) {
    return CrosswordClue(
      num: json['num'] as int,
      row: json['row'] as int,
      col: json['col'] as int,
      length: json['length'] as int,
      clue: json['clue_ar'] as String,
      answer: json['answer'] as String,
      isAcross: isAcross,
    );
  }
  const CrosswordClue({
    required this.num,
    required this.row,
    required this.col,
    required this.length,
    required this.clue,
    required this.answer,
    required this.isAcross,
  });

  final int num;
  final int row;
  final int col;
  final int length;
  final String clue;
  final String answer;
  final bool isAcross;

  @override
  List<Object?> get props => [num, row, col, length, clue, answer, isAcross];
}

class CrosswordCell extends Equatable {
  const CrosswordCell({
    required this.row,
    required this.col,
    this.letter,
    this.userLetter,
    this.number,
    this.isBlocked = false,
    this.status = CellStatus.empty,
  });

  final int row;
  final int col;
  final String? letter; // Correct letter
  final String? userLetter; // User's input
  final int? number; // Clue number if cell starts a word
  final bool isBlocked; // True for black cells
  final CellStatus status;

  bool get isEmpty => letter == null && !isBlocked;
  bool get isCorrect => userLetter != null && userLetter == letter;
  bool get isFilled => userLetter != null;

  CrosswordCell copyWith({
    Object? userLetter = _undefined,
    CellStatus? status,
    int? number,
  }) {
    return CrosswordCell(
      row: row,
      col: col,
      letter: letter,
      userLetter:
          userLetter == _undefined ? this.userLetter : userLetter as String?,
      number: number ?? this.number,
      isBlocked: isBlocked,
      status: status ?? this.status,
    );
  }

  static const _undefined = Object();

  @override
  List<Object?> get props =>
      [row, col, letter, userLetter, number, isBlocked, status];
}

class CrosswordPuzzle extends Equatable {
  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    final solutionGrid = json['solution']['grid'] as List;

    // Parse clues
    final acrossClues = (json['across'] as List)
        .map((clue) =>
            CrosswordClue.fromJson(clue as Map<String, dynamic>, true))
        .toList();

    final downClues = (json['down'] as List)
        .map((clue) =>
            CrosswordClue.fromJson(clue as Map<String, dynamic>, false))
        .toList();

    // Build grid with cell numbers
    final grid = <List<CrosswordCell>>[];
    final clueNumbers = <String, int>{};

    // Collect clue numbers
    for (final clue in [...acrossClues, ...downClues]) {
      clueNumbers['${clue.row},${clue.col}'] = clue.num;
    }

    for (var r = 0; r < rows; r++) {
      final row = <CrosswordCell>[];
      for (var c = 0; c < cols; c++) {
        final cellData = solutionGrid[r][c] as String;
        final isBlocked = cellData.isEmpty || cellData == 'ـ';
        final number = clueNumbers['$r,$c'];

        row.add(CrosswordCell(
          row: r,
          col: c,
          letter: isBlocked ? null : cellData,
          isBlocked: isBlocked,
          number: number,
        ));
      }
      grid.add(row);
    }

    final difficultyStr = json['difficulty'] as String;
    final difficulty = difficultyStr == 'easy'
        ? Difficulty.easy
        : difficultyStr == 'medium'
            ? Difficulty.medium
            : Difficulty.hard;

    return CrosswordPuzzle(
      id: json['id'] as String,
      title: json['title'] as String,
      rows: rows,
      cols: cols,
      acrossClues: acrossClues,
      downClues: downClues,
      grid: grid,
      difficulty: difficulty,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }
  const CrosswordPuzzle({
    required this.id,
    required this.title,
    required this.rows,
    required this.cols,
    required this.acrossClues,
    required this.downClues,
    required this.grid,
    required this.difficulty,
    this.tags = const [],
  });

  final String id;
  final String title;
  final int rows;
  final int cols;
  final List<CrosswordClue> acrossClues;
  final List<CrosswordClue> downClues;
  final List<List<CrosswordCell>> grid;
  final Difficulty difficulty;
  final List<String> tags;

  List<CrosswordClue> get allClues => [...acrossClues, ...downClues];

  @override
  List<Object?> get props =>
      [id, title, rows, cols, acrossClues, downClues, grid, difficulty, tags];
}

class CrosswordProgress extends Equatable {
  const CrosswordProgress({
    required this.puzzleId,
    required this.grid,
    this.score = 0,
    this.hintsUsed = 0,
    this.isCompleted = false,
    this.timeSpent = 0,
  });

  final String puzzleId;
  final List<List<CrosswordCell>> grid;
  final int score;
  final int hintsUsed;
  final bool isCompleted;
  final int timeSpent; // in seconds

  CrosswordProgress copyWith({
    List<List<CrosswordCell>>? grid,
    int? score,
    int? hintsUsed,
    bool? isCompleted,
    int? timeSpent,
  }) {
    return CrosswordProgress(
      puzzleId: puzzleId,
      grid: grid ?? this.grid,
      score: score ?? this.score,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isCompleted: isCompleted ?? this.isCompleted,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puzzleId': puzzleId,
      'grid': grid
          .map((row) => row
              .map((cell) => {
                    'userLetter': cell.userLetter,
                    'row': cell.row,
                    'col': cell.col,
                  })
              .toList())
          .toList(),
      'score': score,
      'hintsUsed': hintsUsed,
      'isCompleted': isCompleted,
      'timeSpent': timeSpent,
    };
  }

  @override
  List<Object?> get props =>
      [puzzleId, grid, score, hintsUsed, isCompleted, timeSpent];
}
