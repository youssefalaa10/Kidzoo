import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/board_model.dart';
import '../models/game_settings.dart';
import '../models/game_state_model.dart';
import 'game_logic.dart';
import 'game_storage.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(GameState.initial()) {
    _storage = GameStorage();
    _loadInitialState();
  }

  late GameStorage _storage;
  GameSettings _settings = const GameSettings();
  final List<Board> _history = [];
  Timer? _playTimer;
  int _sessionStartTime = 0;

  GameSettings get settings => _settings;

  // Load initial state from storage
  Future<void> _loadInitialState() async {
    final stats = await _storage.loadStatistics();
    final settings = await _storage.loadSettings();
    _settings = settings;

    emit(
      state.copyWith(
        bestScore: stats['bestScore'],
        gamesPlayed: stats['gamesPlayed'],
        maxTileAchieved: stats['maxTile'],
        totalPlayTimeSeconds: stats['totalPlayTime'],
        winCount: stats['winCount'],
      ),
    );
  }

  // Start new game
  void newGame({int? boardSize}) {
    _history.clear();
    final size = boardSize ?? _settings.boardSize;
    final board = GameLogic.initializeBoard(size: size);

    _sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _startPlayTimer();

    emit(
      state.copyWith(
        board: board,
        status: GameStatus.playing,
        gamesPlayed: state.gamesPlayed + 1,
        moveCount: 0,
      ),
    );

    _saveState();
  }

  // Continue saved game
  Future<void> continueGame() async {
    final savedBoard = await _storage.loadSavedBoard();
    if (savedBoard == null) {
      newGame();
      return;
    }

    _sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _startPlayTimer();

    emit(
      state.copyWith(
        board: savedBoard,
        status: GameStatus.playing,
      ),
    );
  }

  // Make a move
  void move(SwipeDirection direction) {
    if (state.status != GameStatus.playing &&
        state.status != GameStatus.wonContinued) {
      return;
    }

    // Save current board to history for undo
    if (_settings.undoEnabled) {
      _history.add(state.board);
      // Keep only last 5 moves
      if (_history.length > 5) {
        _history.removeAt(0);
      }
    }

    final result = GameLogic.move(state.board, direction);

    if (!result.moved) {
      // No valid move, remove the board we just added to history
      if (_history.isNotEmpty) {
        _history.removeLast();
      }
      return;
    }

    // Update board and score
    var newState = state.copyWith(
      board: result.board,
      moveCount: state.moveCount + 1,
    );

    // Update best score
    if (result.board.score > state.bestScore) {
      newState = newState.copyWith(bestScore: result.board.score);
    }

    // Update max tile
    final maxTile = GameLogic.getMaxTileValue(result.board);
    if (maxTile > state.maxTileAchieved) {
      newState = newState.copyWith(maxTileAchieved: maxTile);
    }

    // Check win condition
    if (state.status == GameStatus.playing &&
        GameLogic.hasWon(result.board, targetTile: _settings.targetTile)) {
      newState = newState.copyWith(
        status: GameStatus.won,
        winCount: state.winCount + 1,
      );
      _stopPlayTimer();
      _saveGameToHistory(won: true);
    }
    // Check loss condition
    else if (!GameLogic.hasValidMoves(result.board)) {
      newState = newState.copyWith(status: GameStatus.lost);
      _stopPlayTimer();
      _saveGameToHistory(won: false);
    }

    emit(newState);
    _saveState();
  }

  // Undo last move
  void undo() {
    if (!_settings.undoEnabled || _history.isEmpty) return;
    if (state.status != GameStatus.playing &&
        state.status != GameStatus.wonContinued) {
      return;
    }

    final previousBoard = _history.removeLast();
    emit(
      state.copyWith(
        board: previousBoard,
        moveCount: state.moveCount > 0 ? state.moveCount - 1 : 0,
      ),
    );
    _saveState();
  }

  // Continue playing after winning
  void continueAfterWin() {
    emit(state.copyWith(status: GameStatus.wonContinued));
    _startPlayTimer();
    _saveState();
  }

  // Restart current game
  void restart() {
    newGame(boardSize: state.board.size);
  }

  // Update settings
  Future<void> updateSettings(GameSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(settings);
  }

  // Get game history
  Future<List<Map<String, dynamic>>> getGameHistory() async {
    return await _storage.loadGameHistory();
  }

  // Check if there's a saved game
  Future<bool> hasSavedGame() async {
    return await _storage.hasSavedGame();
  }

  // Timer management
  void _startPlayTimer() {
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Timer is running, no need to update state constantly
    });
  }

  void _stopPlayTimer() {
    _playTimer?.cancel();
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sessionDuration = currentTime - _sessionStartTime;
    emit(
      state.copyWith(
        totalPlayTimeSeconds: state.totalPlayTimeSeconds + sessionDuration,
      ),
    );
  }

  // Save current state to storage
  Future<void> _saveState() async {
    await _storage.saveGameState(state);
  }

  // Save completed game to history
  Future<void> _saveGameToHistory({required bool won}) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sessionDuration = currentTime - _sessionStartTime;

    await _storage.saveGameToHistory(
      score: state.currentScore,
      maxTile: GameLogic.getMaxTileValue(state.board),
      moves: state.moveCount,
      durationSeconds: sessionDuration,
      won: won,
    );
  }

  @override
  Future<void> close() {
    _playTimer?.cancel();
    return super.close();
  }
}
