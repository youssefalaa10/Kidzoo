import 'dots_and_boxes_models.dart';

/// Represents the complete state of the Dots and Boxes game
class DotsAndBoxesState {
  DotsAndBoxesState({
    required this.gridSize,
    required this.lines,
    required this.boxes,
    required this.currentPlayer,
    required this.player1Score,
    required this.player2Score,
    required this.status,
    required this.gameMode,
    required this.difficulty,
    this.winner,
    this.lastCompletedBoxes = const [],
    this.currentCombo = 0,
    this.maxCombo = 0,
    this.moveCount = 0,
    this.aiDifficulty = AIDifficulty.medium,
    this.lastLineDrawn,
  });

  /// Factory constructor for initial state
  factory DotsAndBoxesState.initial({
    GameDifficulty difficulty = GameDifficulty.easy,
    GameMode gameMode = GameMode.vsPlayer,
    AIDifficulty aiDifficulty = AIDifficulty.medium,
  }) {
    final gridSize = difficulty.gridSize;
    final boxes = <Box>[];

    // Initialize all boxes
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        boxes.add(Box(DotPosition(row, col)));
      }
    }

    return DotsAndBoxesState(
      gridSize: gridSize,
      lines: {},
      boxes: boxes,
      currentPlayer: Player.player1,
      player1Score: 0,
      player2Score: 0,
      status: GameStatus.playing,
      gameMode: gameMode,
      difficulty: difficulty,
      aiDifficulty: aiDifficulty,
    );
  }

  final int gridSize;
  final Map<String, Line> lines; // Map of line IDs to Line objects
  final List<Box> boxes;
  final Player currentPlayer;
  final int player1Score;
  final int player2Score;
  final GameStatus status;
  final GameMode gameMode;
  final GameDifficulty difficulty;
  final Player? winner;
  final List<Box> lastCompletedBoxes; // Boxes completed in last move
  final int currentCombo; // Current streak of box completions
  final int maxCombo; // Maximum combo achieved in game
  final int moveCount; // Total moves made
  final AIDifficulty aiDifficulty; // AI difficulty level
  final Line? lastLineDrawn; // Last line that was drawn

  int get totalBoxes => gridSize * gridSize;
  int get dotsPerSide => gridSize + 1;
  bool get isComboActive => currentCombo > 1;

  /// Check if a line is already drawn
  bool isLineDrawn(Line line) => lines.containsKey(line.id);

  /// Get a line by its ID
  Line? getLine(String lineId) => lines[lineId];

  /// Copy with updated fields
  DotsAndBoxesState copyWith({
    int? gridSize,
    Map<String, Line>? lines,
    List<Box>? boxes,
    Player? currentPlayer,
    int? player1Score,
    int? player2Score,
    GameStatus? status,
    GameMode? gameMode,
    GameDifficulty? difficulty,
    Player? winner,
    List<Box>? lastCompletedBoxes,
    int? currentCombo,
    int? maxCombo,
    int? moveCount,
    AIDifficulty? aiDifficulty,
    Line? lastLineDrawn,
  }) {
    return DotsAndBoxesState(
      gridSize: gridSize ?? this.gridSize,
      lines: lines ?? this.lines,
      boxes: boxes ?? this.boxes,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      status: status ?? this.status,
      gameMode: gameMode ?? this.gameMode,
      difficulty: difficulty ?? this.difficulty,
      winner: winner,
      lastCompletedBoxes: lastCompletedBoxes ?? this.lastCompletedBoxes,
      currentCombo: currentCombo ?? this.currentCombo,
      maxCombo: maxCombo ?? this.maxCombo,
      moveCount: moveCount ?? this.moveCount,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      lastLineDrawn: lastLineDrawn ?? this.lastLineDrawn,
    );
  }
}
