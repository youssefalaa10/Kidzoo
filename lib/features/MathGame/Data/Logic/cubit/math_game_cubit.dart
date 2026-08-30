import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:kidzo/features/MathGame/Data/Logic/cubit/math_game_state.dart';

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

    // Operations list: addition, subtraction, multiplication, division
    final List<String> operations = [
      'addition',
      'subtraction',
      'multiplication',
      'division'
    ];

    for (int i = 0; i < 5; i++) {
      // Randomly select an operation
      final selectedOperation = operations[random.nextInt(operations.length)];

      int correctAnswer;
      String questionText;
      int a, b;

      switch (selectedOperation) {
        case 'addition':
          a = random.nextInt(maxNumber - minNumber + 1) + minNumber;
          b = random.nextInt(maxNumber - minNumber + 1) + minNumber;
          correctAnswer = a + b;
          questionText = '$a + $b = ?';
          break;
        case 'subtraction':
          a = random.nextInt(maxNumber - minNumber + 1) + minNumber + 5;
          b = random.nextInt(a - minNumber) + minNumber;
          correctAnswer = a - b;
          questionText = '$a - $b = ?';
          break;
        case 'multiplication':
          a = random.nextInt(level * 3) + 1;
          b = random.nextInt(level * 3) + 1;
          correctAnswer = a * b;
          questionText = '$a × $b = ?';
          break;
        case 'division':
          // For division, generate a * b first, then use a * b as dividend and a or b as divisor
          final divisor = random.nextInt(level * 3) + 1;
          final quotient = random.nextInt(level * 3) + 1;
          a = divisor * quotient;
          b = divisor;
          correctAnswer = quotient;
          questionText = '$a ÷ $b = ?';
          break;
        default:
          a = random.nextInt(maxNumber) + minNumber;
          b = random.nextInt(maxNumber) + minNumber;
          correctAnswer = a + b;
          questionText = '$a + $b = ?';
      }

      final List<int> options = [correctAnswer];
      while (options.length < 4) {
        int wrongAnswer;
        if (selectedOperation == 'division') {
          // For division, generate wrong answers close to the correct quotient
          wrongAnswer = correctAnswer + random.nextInt(5) - 2;
        } else {
          wrongAnswer = correctAnswer + random.nextInt(10) - 5;
        }
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
        'operation': selectedOperation,
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
