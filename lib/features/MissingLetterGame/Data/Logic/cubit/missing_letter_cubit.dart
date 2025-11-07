import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../Data/game_storage.dart';
import '../../../Data/word_list.dart';
import 'missing_letter_state.dart';

class MissingLetterCubit extends Cubit<MissingLetterState> {
  MissingLetterCubit({
    int initialIndex = 0,
    int initialScore = 0,
    String languageCode = 'en',
  })  : _storage = MissingLetterStorage(),
        _tts = FlutterTts(),
        super(MissingLetterState(
          currentWord: WordList.getWordAtIndex(initialIndex),
          isCorrect: false,
          isIncorrect: false,
          score: initialScore,
          currentWordIndex: initialIndex,
          totalWords: WordList.getTotalWords(),
          completedWords: initialIndex,
          languageCode: languageCode,
        ));

  final MissingLetterStorage _storage;
  final FlutterTts _tts;

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
    } catch (e) {
      // Handle TTS errors silently
      print('TTS Error: $e');
    }
  }

  void selectOption(String option) async {
    final word = state.currentWord;
    final filledLetters = Map<int, String>.from(state.filledLetters);

    // Find the first unfilled missing index
    int? targetIndex;
    String? targetLetter;
    for (int i = 0; i < word.missingIndices.length; i++) {
      final index = word.missingIndices[i];
      if (!filledLetters.containsKey(index)) {
        targetIndex = index;
        targetLetter = word.correctLetters[i];
        break;
      }
    }

    if (targetIndex == null || targetLetter == null) {
      return; // All letters already filled
    }

    if (option == targetLetter) {
      // Correct answer: fill this letter
      filledLetters[targetIndex] = option;

      // Check if all letters are filled
      final allFilled = filledLetters.length == word.missingIndices.length;

      emit(state.copyWith(
        isCorrect: allFilled,
        isIncorrect: false,
        filledLetters: filledLetters,
        score: state.score + 10, // Add 10 points for each correct answer
      ));

      // Speak the word after all letters are filled
      if (allFilled) {
        await _speakWord(word.word);
      }
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
        filledLetters: {},
        languageCode: state.languageCode,
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
      filledLetters: {},
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
      filledLetters: {},
      languageCode: state.languageCode,
    ));
  }

  Future<int> getBestScore() async {
    return await _storage.getBestScore();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
