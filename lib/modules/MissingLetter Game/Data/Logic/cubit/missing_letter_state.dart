import '../../Model/word_model.dart';

class MissingLetterState {
  final Word currentWord;
  final bool isCorrect;
  final bool isIncorrect;
  final int score;

  MissingLetterState({
    required this.currentWord,
    required this.isCorrect,
    required this.isIncorrect,
    required this.score,
  });

  MissingLetterState copyWith({
    Word? currentWord,
    bool? isCorrect,
    bool? isIncorrect,
    int? score,
  }) {
    return MissingLetterState(
      currentWord: currentWord ?? this.currentWord,
      isCorrect: isCorrect ?? this.isCorrect,
      isIncorrect: isIncorrect ?? this.isIncorrect,
      score: score ?? this.score,
    );
  }
}