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
  });
  final Word currentWord;
  final bool isCorrect;
  final bool isIncorrect;
  final int score;
  final int currentWordIndex;
  final int totalWords;
  final int completedWords;

  bool get isGameComplete => completedWords >= totalWords;
  double get progress => totalWords > 0 ? completedWords / totalWords : 0.0;

  MissingLetterState copyWith({
    Word? currentWord,
    bool? isCorrect,
    bool? isIncorrect,
    int? score,
    int? currentWordIndex,
    int? totalWords,
    int? completedWords,
  }) {
    return MissingLetterState(
      currentWord: currentWord ?? this.currentWord,
      isCorrect: isCorrect ?? this.isCorrect,
      isIncorrect: isIncorrect ?? this.isIncorrect,
      score: score ?? this.score,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      totalWords: totalWords ?? this.totalWords,
      completedWords: completedWords ?? this.completedWords,
    );
  }
}
