import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/crossword_models.dart';

class CrosswordStorage {
  static const String _keyProgress = 'crossword_progress_';
  static const String _keyCompleted = 'crossword_completed';
  static const String _keyBestScores = 'crossword_best_scores';
  static const String _keyCurrentPuzzle = 'crossword_current_puzzle';
  static const String _keyTotalScore = 'crossword_total_score';
  static const String _keyPuzzlesPlayed = 'crossword_puzzles_played';

  // Save puzzle progress
  Future<void> saveProgress(CrosswordProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyProgress${progress.puzzleId}';
    await prefs.setString(key, jsonEncode(progress.toJson()));
  }

  // Load puzzle progress
  Future<CrosswordProgress?> loadProgress(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyProgress$puzzleId';
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CrosswordProgress(
        puzzleId: json['puzzleId'] as String,
        grid: const [], // Will be rebuilt from saved data
        score: json['score'] as int,
        hintsUsed: json['hintsUsed'] as int,
        isCompleted: json['isCompleted'] as bool,
        timeSpent: json['timeSpent'] as int,
      );
    } catch (e) {
      return null;
    }
  }

  // Mark puzzle as completed
  Future<void> markCompleted(String puzzleId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedPuzzles();
    if (!completed.contains(puzzleId)) {
      completed.add(puzzleId);
      await prefs.setStringList(_keyCompleted, completed);
    }

    // Save best score
    final bestScores = await getBestScores();
    if (!bestScores.containsKey(puzzleId) || score > bestScores[puzzleId]!) {
      bestScores[puzzleId] = score;
      await prefs.setString(_keyBestScores, jsonEncode(bestScores));
    }

    // Update total score
    final totalScore = await getTotalScore();
    await prefs.setInt(_keyTotalScore, totalScore + score);

    // Update puzzles played count
    final played = await getPuzzlesPlayed();
    await prefs.setInt(_keyPuzzlesPlayed, played + 1);
  }

  // Get completed puzzles
  Future<List<String>> getCompletedPuzzles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyCompleted) ?? [];
  }

  // Get best scores
  Future<Map<String, int>> getBestScores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyBestScores);
    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> json =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  // Save current puzzle ID
  Future<void> setCurrentPuzzle(String? puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    if (puzzleId == null) {
      await prefs.remove(_keyCurrentPuzzle);
    } else {
      await prefs.setString(_keyCurrentPuzzle, puzzleId);
    }
  }

  // Get current puzzle ID
  Future<String?> getCurrentPuzzle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentPuzzle);
  }

  // Get total score
  Future<int> getTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalScore) ?? 0;
  }

  // Get puzzles played count
  Future<int> getPuzzlesPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPuzzlesPlayed) ?? 0;
  }

  // Check if puzzle is completed
  Future<bool> isPuzzleCompleted(String puzzleId) async {
    final completed = await getCompletedPuzzles();
    return completed.contains(puzzleId);
  }

  // Clear all progress
  Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompleted);
    await prefs.remove(_keyBestScores);
    await prefs.remove(_keyCurrentPuzzle);
    await prefs.remove(_keyTotalScore);
    await prefs.remove(_keyPuzzlesPlayed);
  }
}
