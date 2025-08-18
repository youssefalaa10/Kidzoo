import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:kidzoo/features/MathGame/Data/Logic/cubit/math_game_state.dart';

class MathGameCubit extends Cubit<MathGameState> {
  MathGameCubit({this.operation = 'ayu', this.level = 1})
      : super(MathGameState(
            questions: [],
            currentQuestionIndex: 0,
            starsEarned: 0,
            isCompleted: false)) {
    _generateQuestions();
  }
  final String operation;
  final int level;

  void _generateQuestions() {
    final List<Map<String, dynamic>> newQuestions = [];
    final random = Random();

    // Adjust difficulty based on level
    final int maxNumber = level == 1 ? 10 : (level == 2 ? 20 : 30);
    final int minNumber = level == 1 ? 1 : (level == 2 ? 5 : 10);

    for (int i = 0; i < 5; i++) {
      int correctAnswer;
      String questionText;
      if (operation == 'addition') {
        final int a = random.nextInt(maxNumber) + minNumber;
        final int b = random.nextInt(maxNumber) + minNumber;
        correctAnswer = a + b;
        questionText = '$a + $b = ?';
      } else if (operation == 'subtraction') {
        final int a = random.nextInt(maxNumber) + minNumber + 5;
        final int b = random.nextInt(a - minNumber) + minNumber;
        correctAnswer = a - b;
        questionText = '$a - $b = ?';
      } else {
        final int a = random.nextInt(level * 3) + 1;
        final int b = random.nextInt(level * 3) + 1;
        correctAnswer = a * b;
        questionText = '$a × $b = ?';
      }

      final List<int> options = [correctAnswer];
      while (options.length < 4) {
        final int wrongAnswer = correctAnswer + random.nextInt(10) - 5;
        if (wrongAnswer != correctAnswer &&
            !options.contains(wrongAnswer) &&
            wrongAnswer >= 0) {
          options.add(wrongAnswer);
        }
      }
      options.shuffle();

      newQuestions.add({
        'question': questionText,
        'correctAnswer': correctAnswer,
        'options': options,
      });
    }

    emit(state.copyWith(questions: newQuestions));
  }

  void checkAnswer(int selectedAnswer) {
    final correctAnswer =
        state.questions[state.currentQuestionIndex]['correctAnswer'];
    if (selectedAnswer == correctAnswer) {
      emit(state.copyWith(starsEarned: state.starsEarned + 1));
      _proceedToNextQuestion();
    }
  }

  void _proceedToNextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      emit(
          state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1));
    } else {
      emit(state.copyWith(isCompleted: true));
    }
  }
}
