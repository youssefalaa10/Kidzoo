import 'package:shared_preferences/shared_preferences.dart';

class MissingLetterStorage {
  static const String _keyCurrentIndex = 'missing_letter_current_index';
  static const String _keyTotalScore = 'missing_letter_total_score';
  static const String _keyCompletedWords = 'missing_letter_completed_words';
  static const String _keyBestScore = 'missing_letter_best_score';

  // Save current progress
  Future<void> saveProgress({
    required int currentIndex,
    required int totalScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentIndex, currentIndex);
    await prefs.setInt(_keyTotalScore, totalScore);
  }

  // Load current index
  Future<int> getCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentIndex) ?? 0;
  }

  // Load total score
  Future<int> getTotalScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalScore) ?? 0;
  }

  // Save completed word count
  Future<void> saveCompletedCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCompletedWords, count);
  }

  // Get completed word count
  Future<int> getCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompletedWords) ?? 0;
  }

  // Save best score
  Future<void> saveBestScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBest = prefs.getInt(_keyBestScore) ?? 0;
    if (score > currentBest) {
      await prefs.setInt(_keyBestScore, score);
    }
  }

  // Get best score
  Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBestScore) ?? 0;
  }

  // Check if there's a game in progress
  Future<bool> hasProgress() async {
    final currentIndex = await getCurrentIndex();
    return currentIndex > 0;
  }

  // Reset progress
  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentIndex, 0);
    await prefs.setInt(_keyTotalScore, 0);
    await prefs.setInt(_keyCompletedWords, 0);
  }

  // Complete the game
  Future<void> completeGame(int finalScore) async {
    await saveBestScore(finalScore);
    await resetProgress();
  }
}

