import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Model/word_model.dart';
import 'missing_letter_state.dart';

class MissingLetterCubit extends Cubit<MissingLetterState> {
  MissingLetterCubit(Word initialWord)
      : super(MissingLetterState(
          currentWord: initialWord,
          isCorrect: false,
          isIncorrect: false,
          score: 0,
        ));

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
        score: state.score > 0 ? state.score - 5 : 0, // Deduct 5 points for a wrong answer
      ));
      // Reset the incorrect state after a delay to stop the shake animation
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(isIncorrect: false));
    }
  }

  // Remove nextLevel method since there's only one word
}