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

  bool get isGameComplete => completedWords >= totalWords;
  double get progress => totalWords > 0 ? completedWords / totalWords : 0.0;
  bool get allLettersFilled =>
      filledLetters.length == currentWord.missingIndices.length &&
      filledLetters.keys.toSet().containsAll(currentWord.missingIndices);

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
    );
  }
}
