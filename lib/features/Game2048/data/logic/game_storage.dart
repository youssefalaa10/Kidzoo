import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board_model.dart';
import '../models/game_settings.dart';
import '../models/game_state_model.dart';
import '../models/tile_model.dart';

class GameStorage {
  static const String _keyBestScore = '2048_best_score';
  static const String _keyGamesPlayed = '2048_games_played';
  static const String _keyMaxTile = '2048_max_tile';
  static const String _keyTotalPlayTime = '2048_total_play_time';
  static const String _keyWinCount = '2048_win_count';
  static const String _keySavedBoard = '2048_saved_board';
  static const String _keySettings = '2048_settings';
  static const String _keyGameHistory = '2048_game_history';

  // Save game state
  Future<void> saveGameState(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBestScore, state.bestScore);
    await prefs.setInt(_keyGamesPlayed, state.gamesPlayed);
    await prefs.setInt(_keyMaxTile, state.maxTileAchieved);
    await prefs.setInt(_keyTotalPlayTime, state.totalPlayTimeSeconds);
    await prefs.setInt(_keyWinCount, state.winCount);

    // Save current board if game is in progress
    if (state.status == GameStatus.playing ||
        state.status == GameStatus.wonContinued) {
      await _saveBoard(state.board);
    } else {
      await _clearSavedBoard();
    }
  }

  // Load game statistics
  Future<Map<String, int>> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'bestScore': prefs.getInt(_keyBestScore) ?? 0,
      'gamesPlayed': prefs.getInt(_keyGamesPlayed) ?? 0,
      'maxTile': prefs.getInt(_keyMaxTile) ?? 0,
      'totalPlayTime': prefs.getInt(_keyTotalPlayTime) ?? 0,
      'winCount': prefs.getInt(_keyWinCount) ?? 0,
    };
  }

  // Save board state
  Future<void> _saveBoard(Board board) async {
    final prefs = await SharedPreferences.getInstance();
    final boardData = {
      'size': board.size,
      'score': board.score,
      'tiles': board.tiles
          .map((tile) => {
                'value': tile.value,
                'row': tile.row,
                'col': tile.col,
              })
          .toList(),
    };
    await prefs.setString(_keySavedBoard, jsonEncode(boardData));
  }

  // Load saved board
  Future<Board?> loadSavedBoard() async {
    final prefs = await SharedPreferences.getInstance();
    final boardJson = prefs.getString(_keySavedBoard);
    if (boardJson == null) return null;

    try {
      final boardData = jsonDecode(boardJson) as Map<String, dynamic>;
      final tiles = (boardData['tiles'] as List)
          .map((tileData) => Tile(
                value: tileData['value'] as int,
                row: tileData['row'] as int,
                col: tileData['col'] as int,
              ))
          .toList();

      return Board(
        size: boardData['size'] as int,
        score: boardData['score'] as int,
        tiles: tiles,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if there is a saved game
  Future<bool> hasSavedGame() async {
    final board = await loadSavedBoard();
    return board != null;
  }

  // Clear saved board
  Future<void> _clearSavedBoard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedBoard);
  }

  // Save settings
  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  // Load settings
  Future<GameSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_keySettings);
    if (settingsJson == null) return const GameSettings();

    try {
      final settingsData = jsonDecode(settingsJson) as Map<String, dynamic>;
      return GameSettings.fromJson(settingsData);
    } catch (e) {
      return const GameSettings();
    }
  }

  // Save game to history
  Future<void> saveGameToHistory({
    required int score,
    required int maxTile,
    required int moves,
    required int durationSeconds,
    required bool won,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyGameHistory);
    List<Map<String, dynamic>> history = [];

    if (historyJson != null) {
      try {
        history = (jsonDecode(historyJson) as List)
            .cast<Map<String, dynamic>>()
            .toList();
      } catch (e) {
        history = [];
      }
    }

    history.insert(
      0,
      {
        'score': score,
        'maxTile': maxTile,
        'moves': moves,
        'duration': durationSeconds,
        'won': won,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Keep only last 50 games
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    await prefs.setString(_keyGameHistory, jsonEncode(history));
  }

  // Load game history
  Future<List<Map<String, dynamic>>> loadGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyGameHistory);
    if (historyJson == null) return [];

    try {
      return (jsonDecode(historyJson) as List)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBestScore);
    await prefs.remove(_keyGamesPlayed);
    await prefs.remove(_keyMaxTile);
    await prefs.remove(_keyTotalPlayTime);
    await prefs.remove(_keyWinCount);
    await prefs.remove(_keySavedBoard);
    await prefs.remove(_keyGameHistory);
  }
}

