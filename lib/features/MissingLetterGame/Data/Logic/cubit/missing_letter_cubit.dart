import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../Model/word_model.dart';
import '../../game_storage.dart';
import '../../word_list.dart';
import 'missing_letter_state.dart';

class MissingLetterCubit extends Cubit<MissingLetterState> {
  MissingLetterCubit({
    int initialIndex = 0,
    int initialScore = 0,
    int initialLevel = 1,
    String languageCode = 'en',
  })  : _storage = MissingLetterStorage(),
        _tts = FlutterTts(),
        super(MissingLetterState(
          currentWord: _buildWord(
            WordList.getBaseWordAtIndex(initialIndex),
            level: initialLevel,
            correctStreak: 0,
            wrongAttempts: 0,
          ),
          isCorrect: false,
          isIncorrect: false,
          score: initialScore,
          currentWordIndex: initialIndex,
          totalWords: WordList.getTotalWords(),
          completedWords: initialIndex,
          currentLevel: initialLevel,
          languageCode: languageCode,
        ));

  final MissingLetterStorage _storage;
  final FlutterTts _tts;
  Timer? _transitionTimer;
  Timer? _wrongFeedbackTimer;

  static const int minLevel = 1;
  static const int maxLevel = 4;
  static const int _streakToLevelUp = 3;
  static const int _wrongAttemptsToLevelDown = 2;
  static const int _wrongAttemptsForHint = 2;

  /// Decides how many letters should be missing for [word], based on the
  /// current [level] and recent performance. Never removes more than half
  /// the word (rounded up) and always keeps at least one visible letter.
  static int calculateMissingLetterCount(
    String word, {
    required int level,
    required int correctStreak,
    required int wrongAttempts,
  }) {
    final letters = word.replaceAll(RegExp('[^A-Za-z]'), '');
    final length = letters.length;
    if (length <= 1) return 1;

    var count = level.clamp(minLevel, maxLevel);
    if (correctStreak >= _streakToLevelUp) count += 1;
    if (wrongAttempts >= _wrongAttemptsToLevelDown) count -= 1;

    final maxAllowed = max(1, min(length - 1, (length / 2).ceil()));
    return count.clamp(1, maxAllowed);
  }

  /// Picks [count] letter positions to hide from [word], spreading them
  /// across the word instead of always taking them from the end.
  static List<int> generateMissingIndexes(String word, int count) {
    final length = word.length;
    final safeCount = count.clamp(1, max(1, length - 1));
    final random = Random();
    final indices = <int>{};
    final bucketSize = length / safeCount;

    for (var i = 0; i < safeCount; i++) {
      final start = (i * bucketSize).floor();
      final end = min(length, ((i + 1) * bucketSize).ceil()).clamp(start + 1, length);
      var guard = 0;
      int idx;
      do {
        idx = start + random.nextInt(end - start);
        guard++;
      } while (indices.contains(idx) && guard < 12);
      indices.add(idx);
    }
    while (indices.length < safeCount) {
      indices.add(random.nextInt(length));
    }
    return indices.toList()..sort();
  }

  static Word _buildWord(
    WordEntry entry, {
    required int level,
    required int correctStreak,
    required int wrongAttempts,
  }) {
    final word = entry.word.toUpperCase();
    final missingCount = calculateMissingLetterCount(
      word,
      level: level,
      correctStreak: correctStreak,
      wrongAttempts: wrongAttempts,
    );
    final missingIndices = generateMissingIndexes(word, missingCount);
    final correctLetters = missingIndices.map((i) => word[i]).toList();

    return Word.withRandomizedOptions(
      word: word,
      missingIndices: missingIndices,
      correctLetters: correctLetters,
      imagePath: entry.imagePath,
    );
  }

  Future<void> _initializeTts() async {
    final language = state.languageCode == 'ar' ? 'ar-SA' : 'en-US';
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void updateLanguage(String languageCode) {
    emit(state.copyWith(languageCode: languageCode));
  }

  Future<void> _speakWord(String word) async {
    try {
      await _initializeTts();
      await _tts.speak(word);
    } catch (_) {
      // Speech is a nice-to-have; ignore TTS failures.
    }
  }

  void increaseDifficulty() {
    final next = (state.currentLevel + 1).clamp(minLevel, maxLevel);
    emit(state.copyWith(currentLevel: next, correctStreak: 0));
  }

  void decreaseDifficulty() {
    final next = (state.currentLevel - 1).clamp(minLevel, maxLevel);
    emit(state.copyWith(currentLevel: next, wrongAttempts: 0));
  }

  void selectLetter(String letter) {
    if (state.isTransitioning || state.isCorrect || isClosed) return;

    final word = state.currentWord;
    final filledLetters = Map<int, String>.from(state.filledLetters);

    int? targetIndex;
    String? targetLetter;
    for (final index in word.missingIndices) {
      if (!filledLetters.containsKey(index)) {
        targetIndex = index;
        targetLetter = word.word[index];
        break;
      }
    }
    if (targetIndex == null || targetLetter == null) return;

    if (letter.toUpperCase() == targetLetter.toUpperCase()) {
      filledLetters[targetIndex] = letter.toUpperCase();
      final allFilled = filledLetters.length == word.missingIndices.length;

      if (allFilled) {
        _handleCorrectAnswer(filledLetters);
      } else {
        emit(state.copyWith(isIncorrect: false, filledLetters: filledLetters));
      }
    } else {
      _handleWrongAnswer();
    }
  }

  /// Backward-compatible name for [selectLetter].
  void selectOption(String option) => selectLetter(option);

  void removeLetterAt(int index) {
    if (state.isTransitioning) return;
    final filledLetters = Map<int, String>.from(state.filledLetters)..remove(index);
    emit(state.copyWith(filledLetters: filledLetters, isIncorrect: false));
  }

  void resetCurrentAnswer() {
    emit(state.copyWith(filledLetters: const {}, isIncorrect: false, hintRevealed: false));
  }

  void revealHint() {
    final word = state.currentWord;
    final filledLetters = Map<int, String>.from(state.filledLetters);
    for (final index in word.missingIndices) {
      if (!filledLetters.containsKey(index)) {
        filledLetters[index] = word.word[index];
        emit(state.copyWith(filledLetters: filledLetters, hintRevealed: true));
        return;
      }
    }
  }

  Future<void> _handleCorrectAnswer(Map<int, String> filledLetters) async {
    final newStreak = state.correctStreak + 1;
    emit(state.copyWith(
      isCorrect: true,
      isIncorrect: false,
      filledLetters: filledLetters,
      score: state.score + 10,
      correctStreak: newStreak,
      wrongAttempts: 0,
      positiveFeedbackIndex: Random().nextInt(4),
    ));

    if (newStreak >= _streakToLevelUp) {
      increaseDifficulty();
    }

    // Speak the completed word; not awaited so the transition timer below
    // isn't delayed by TTS latency.
    unawaited(_speakWord(state.currentWord.word));

    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 1500), () {
      if (isClosed) return;
      nextWord();
    });
  }

  void _handleWrongAnswer() {
    final wrongAttempts = state.wrongAttempts + 1;
    emit(state.copyWith(
      isIncorrect: true,
      isCorrect: false,
      correctStreak: 0,
      wrongAttempts: wrongAttempts,
      negativeFeedbackIndex: Random().nextInt(3),
    ));

    if (wrongAttempts >= _wrongAttemptsForHint && !state.hintRevealed) {
      revealHint();
    }
    if (wrongAttempts >= _wrongAttemptsToLevelDown) {
      decreaseDifficulty();
    }

    _wrongFeedbackTimer?.cancel();
    _wrongFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (isClosed) return;
      emit(state.copyWith(isIncorrect: false));
    });
  }

  void nextWord() {
    _transitionTimer?.cancel();
    final nextIndex = state.currentWordIndex + 1;
    final completedCount = state.completedWords + 1;

    if (nextIndex >= WordList.getTotalWords()) {
      unawaited(_storage.completeGame(state.score));
      emit(state.copyWith(completedWords: completedCount, isTransitioning: false));
      return;
    }

    final nextEntry = WordList.getBaseWordAtIndex(nextIndex);
    final nextWordModel = _buildWord(
      nextEntry,
      level: state.currentLevel,
      correctStreak: state.correctStreak,
      wrongAttempts: state.wrongAttempts,
    );

    unawaited(_storage.saveProgress(currentIndex: nextIndex, totalScore: state.score));
    unawaited(_storage.saveCompletedCount(completedCount));
    unawaited(_storage.saveLevel(state.currentLevel));

    emit(state.copyWith(
      currentWord: nextWordModel,
      isCorrect: false,
      isIncorrect: false,
      currentWordIndex: nextIndex,
      completedWords: completedCount,
      filledLetters: const {},
      isTransitioning: false,
      hintRevealed: false,
    ));
  }

  Future<void> loadProgress() async {
    final currentIndex = await _storage.getCurrentIndex();
    final totalScore = await _storage.getTotalScore();
    final completedCount = await _storage.getCompletedCount();
    final level = await _storage.getLevel();

    final entry = WordList.getBaseWordAtIndex(currentIndex);
    final word = _buildWord(entry, level: level, correctStreak: 0, wrongAttempts: 0);

    emit(MissingLetterState(
      currentWord: word,
      isCorrect: false,
      isIncorrect: false,
      score: totalScore,
      currentWordIndex: currentIndex,
      totalWords: WordList.getTotalWords(),
      completedWords: completedCount,
      currentLevel: level,
      languageCode: state.languageCode,
    ));
  }

  Future<void> resetGame() async {
    _transitionTimer?.cancel();
    _wrongFeedbackTimer?.cancel();
    await _storage.resetProgress();
    emit(MissingLetterState(
      currentWord: _buildWord(
        WordList.getBaseWordAtIndex(0),
        level: minLevel,
        correctStreak: 0,
        wrongAttempts: 0,
      ),
      isCorrect: false,
      isIncorrect: false,
      score: 0,
      totalWords: WordList.getTotalWords(),
      languageCode: state.languageCode,
    ));
  }

  Future<int> getBestScore() => _storage.getBestScore();

  @override
  Future<void> close() {
    _transitionTimer?.cancel();
    _wrongFeedbackTimer?.cancel();
    unawaited(_tts.stop());
    return super.close();
  }
}
