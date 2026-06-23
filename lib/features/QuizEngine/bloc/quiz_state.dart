import 'package:equatable/equatable.dart';
import '../data/quiz_models.dart';

abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => [];
}

class QuizLoading extends QuizState {}

class QuizActive extends QuizState {
  final QuizQuestion question;
  final int score;
  final int questionIndex;

  const QuizActive(this.question, this.score, this.questionIndex);

  @override
  List<Object?> get props => [question, score, questionIndex];
}

class QuizFeedback extends QuizState {
  final QuizQuestion question;
  final bool isCorrect;
  final int score;
  final int questionIndex;

  const QuizFeedback(
      this.question, this.isCorrect, this.score, this.questionIndex);

  @override
  List<Object?> get props => [question, isCorrect, score, questionIndex];
}

class QuizCompleted extends QuizState {
  final int finalScore;
  const QuizCompleted(this.finalScore);

  @override
  List<Object?> get props => [finalScore];
}
