class QuizOption {
  final String id;
  final String text;
  final String? imagePath;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    this.imagePath,
    required this.isCorrect,
  });
}

class QuizQuestion {
  final String id;
  final String prompt;
  final String imageOrScenePath;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.imageOrScenePath,
    required this.options,
  });
}
