import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:kidzoo/modules/MathGame/Data/Logic/cubit/math_game_state.dart';

class MathGameCubit extends Cubit<MathGameState> {
  final String operation;

  MathGameCubit({this.operation = 'ayu'})
      : super(MathGameState(
            questions: [],
            currentQuestionIndex: 0,
            starsEarned: 0,
            isCompleted: false)) {
    _generateQuestions();
  }

  void _generateQuestions() {
    List<Map<String, dynamic>> newQuestions = [];
    final random = Random();

    for (int i = 0; i < 5; i++) {
      int correctAnswer;
      String questionText;
      if (operation == 'addition') {
        int a = random.nextInt(10) + 1;
        int b = random.nextInt(10) + 1;
        correctAnswer = a + b;
        questionText = '$a + $b = ?';
      } else if (operation == 'subtraction') {
        int a = random.nextInt(10) + 5;
        int b = random.nextInt(a) + 1;
        correctAnswer = a - b;
        questionText = '$a - $b = ?';
      } else {
        int a = random.nextInt(5) + 1;
        int b = random.nextInt(5) + 1;
        correctAnswer = a * b;
        questionText = '$a × $b = ?';
      }

      List<int> options = [correctAnswer];
      while (options.length < 4) {
        int wrongAnswer = correctAnswer + random.nextInt(10) - 5;
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
