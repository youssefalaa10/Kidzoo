import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Data/game_storage.dart';
import '../../../Data/word_list.dart';
import 'missing_letter_state.dart';

class MissingLetterCubit extends Cubit<MissingLetterState> {
  MissingLetterCubit({
    int initialIndex = 0,
    int initialScore = 0,
  })  : _storage = MissingLetterStorage(),
        super(MissingLetterState(
          currentWord: WordList.getWordAtIndex(initialIndex),
          isCorrect: false,
          isIncorrect: false,
          score: initialScore,
          currentWordIndex: initialIndex,
          totalWords: WordList.getTotalWords(),
          completedWords: initialIndex,
        ));

  final MissingLetterStorage _storage;

  void selectOption(String option) async {
    if (option == state.currentWord.correctLetter) {
      // Correct answer: increment score and mark as correct
      emit(state.copyWith(
        isCorrect: true,
        isIncorrect: false,
        score: state.score + 10, // Add 10 points for a correct answer
      ));
    } else {
      // Incorrect answer: trigger feedback and deduct points
      emit(state.copyWith(
        isCorrect: false,
        isIncorrect: true,
        score: state.score > 0 ? state.score - 5 : 0,
      ));
      // Reset the incorrect state after a delay
      await Future<void>.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(isIncorrect: false));
    }
  }

  void nextWord() async {
    final nextIndex = state.currentWordIndex + 1;
    final completedCount = state.completedWords + 1;

    if (nextIndex >= WordList.getTotalWords()) {
      // Game completed
      await _storage.completeGame(state.score);
      emit(state.copyWith(
        completedWords: completedCount,
      ));
    } else {
      // Load next word
      final nextWord = WordList.getWordAtIndex(nextIndex);
      await _storage.saveProgress(
        currentIndex: nextIndex,
        totalScore: state.score,
      );
      await _storage.saveCompletedCount(completedCount);

      emit(state.copyWith(
        currentWord: nextWord,
        isCorrect: false,
        isIncorrect: false,
        currentWordIndex: nextIndex,
        completedWords: completedCount,
      ));
    }
  }

  Future<void> loadProgress() async {
    final currentIndex = await _storage.getCurrentIndex();
    final totalScore = await _storage.getTotalScore();
    final completedCount = await _storage.getCompletedCount();

    final word = WordList.getWordAtIndex(currentIndex);
    emit(MissingLetterState(
      currentWord: word,
      isCorrect: false,
      isIncorrect: false,
      score: totalScore,
      currentWordIndex: currentIndex,
      totalWords: WordList.getTotalWords(),
      completedWords: completedCount,
    ));
  }

  Future<void> resetGame() async {
    await _storage.resetProgress();
    emit(MissingLetterState(
      currentWord: WordList.getWordAtIndex(0),
      isCorrect: false,
      isIncorrect: false,
      score: 0,
      totalWords: WordList.getTotalWords(),
    ));
  }

  Future<int> getBestScore() async {
    return await _storage.getBestScore();
  }
}