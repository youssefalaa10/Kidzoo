import '../../Model/word_model.dart';

class MissingLetterState {
  MissingLetterState({
    required this.currentWord,
    required this.isCorrect,
    required this.isIncorrect,
    required this.score,
    this.currentWordIndex = 0,
    this.totalWords = 25,
    this.completedWords = 0,
    this.filledLetters = const {},
    this.languageCode = 'en',
    this.currentLevel = 1,
    this.correctStreak = 0,
    this.wrongAttempts = 0,
    this.isTransitioning = false,
    this.hintRevealed = false,
    this.positiveFeedbackIndex = 0,
    this.negativeFeedbackIndex = 0,
  });

  final Word currentWord;
  final bool isCorrect;
  final bool isIncorrect;
  final int score;
  final int currentWordIndex;
  final int totalWords;
  final int completedWords;
  final Map<int, String>
      filledLetters; // Track which missing indices have been filled
  final String languageCode; // Language code for TTS

  /// Adaptive difficulty tracking.
  final int currentLevel;
  final int correctStreak;
  final int wrongAttempts;

  /// True while the "correct answer" delay is running, before the next word
  /// loads. Input is locked during this window.
  final bool isTransitioning;
  final bool hintRevealed;

  /// Indexes picked to vary the positive/gentle feedback message shown.
  final int positiveFeedbackIndex;
  final int negativeFeedbackIndex;

  bool get isGameComplete => completedWords >= totalWords;
  double get progress => totalWords > 0 ? completedWords / totalWords : 0.0;
  bool get allLettersFilled =>
      filledLetters.length == currentWord.missingIndices.length &&
      filledLetters.keys.toSet().containsAll(currentWord.missingIndices);

  /// Position (0-based, in `missingIndices` order) the child is currently
  /// filling in — the first gap without a letter yet.
  int get activeMissingPosition => filledLetters.length;

  MissingLetterState copyWith({
    Word? currentWord,
    bool? isCorrect,
    bool? isIncorrect,
    int? score,
    int? currentWordIndex,
    int? totalWords,
    int? completedWords,
    Map<int, String>? filledLetters,
    String? languageCode,
    int? currentLevel,
    int? correctStreak,
    int? wrongAttempts,
    bool? isTransitioning,
    bool? hintRevealed,
    int? positiveFeedbackIndex,
    int? negativeFeedbackIndex,
  }) {
    return MissingLetterState(
      currentWord: currentWord ?? this.currentWord,
      isCorrect: isCorrect ?? this.isCorrect,
      isIncorrect: isIncorrect ?? this.isIncorrect,
      score: score ?? this.score,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      totalWords: totalWords ?? this.totalWords,
      completedWords: completedWords ?? this.completedWords,
      filledLetters: filledLetters ?? this.filledLetters,
      languageCode: languageCode ?? this.languageCode,
      currentLevel: currentLevel ?? this.currentLevel,
      correctStreak: correctStreak ?? this.correctStreak,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      hintRevealed: hintRevealed ?? this.hintRevealed,
      positiveFeedbackIndex: positiveFeedbackIndex ?? this.positiveFeedbackIndex,
      negativeFeedbackIndex: negativeFeedbackIndex ?? this.negativeFeedbackIndex,
    );
  }
}
