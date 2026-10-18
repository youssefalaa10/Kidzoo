class MathGameState {
  MathGameState({
    required this.questions,
    required this.currentQuestionIndex,
    required this.starsEarned,
    required this.isCompleted,
    this.wrongAttempts = 0,
  });
  final List<Map<String, dynamic>> questions;
  final int currentQuestionIndex;
  final int starsEarned;
  final bool isCompleted;

  /// Wrong taps across the whole round.
  ///
  /// The cubit used to ignore wrong answers entirely, so every finished game
  /// scored a full five and the win dialog's five stars meant nothing. This
  /// is what makes the rating real.
  final int wrongAttempts;

  MathGameState copyWith({
    List<Map<String, dynamic>>? questions,
    int? currentQuestionIndex,
    int? starsEarned,
    bool? isCompleted,
    int? wrongAttempts,
  }) {
    return MathGameState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      starsEarned: starsEarned ?? this.starsEarned,
      isCompleted: isCompleted ?? this.isCompleted,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}
