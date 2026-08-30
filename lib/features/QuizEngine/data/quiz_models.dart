class QuizOption {

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.imagePath,
  });
  final String id;
  final String text;
  final String? imagePath;
  final bool isCorrect;
}

class QuizQuestion {

  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.imageOrScenePath,
    required this.options,
  });
  final String id;
  final String prompt;
  final String imageOrScenePath;
  final List<QuizOption> options;
}
