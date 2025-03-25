class MathGameState {
  final List<Map<String, dynamic>> questions;
  final int currentQuestionIndex;
  final int starsEarned;
  final bool isCompleted;

  MathGameState({
    required this.questions,
    required this.currentQuestionIndex,
    required this.starsEarned,
    required this.isCompleted,
  });

  MathGameState copyWith({
    List<Map<String, dynamic>>? questions,
    int? currentQuestionIndex,
    int? starsEarned,
    bool? isCompleted,
  }) {
    return MathGameState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      starsEarned: starsEarned ?? this.starsEarned,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
