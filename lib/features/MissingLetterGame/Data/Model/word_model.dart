import 'dart:math';

class Word {
  // Factory constructor to create a word with randomized options
  factory Word.withRandomizedOptions({
    required String word,
    required List<int> missingIndices,
    required List<String> correctLetters,
    required String imagePath,
  }) {
    final random = Random();
    final allLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

    // Remove correct letters from the pool
    for (final correctLetter in correctLetters) {
      allLetters.remove(correctLetter);
    }

    // Shuffle the remaining letters
    allLetters.shuffle(random);

    // Calculate how many wrong options we need
    final wrongOptionsNeeded = 4 - correctLetters.length;
    final wrongOptions = allLetters.take(wrongOptionsNeeded).toList();
    final options = [...wrongOptions, ...correctLetters];

    // Shuffle the options to randomize their positions
    options.shuffle(random);

    return Word(
      word: word,
      missingIndices: missingIndices,
      options: options,
      correctLetters: correctLetters,
      imagePath: imagePath,
    );
  }

  // Legacy factory for single missing letter (named differently to avoid conflict)
  factory Word.withSingleMissingLetter({
    required String word,
    required int missingIndex,
    required String correctLetter,
    required String imagePath,
  }) {
    return Word.withRandomizedOptions(
      word: word,
      missingIndices: [missingIndex],
      correctLetters: [correctLetter],
      imagePath: imagePath,
    );
  }
  
  Word({
    required this.word,
    required this.missingIndices,
    required this.options,
    required this.correctLetters,
    required this.imagePath,
  });
  
  final String word; // e.g., "Can"
  final List<int> missingIndices; // e.g., [1] or [0, 2] for multiple missing letters
  final List<String> options; // e.g., ["C", "A", "G", "Y"]
  final List<String> correctLetters; // e.g., ["A"] or ["C", "N"]
  final String imagePath;

  // Legacy support - single missing letter
  int get missingIndex => missingIndices.isNotEmpty ? missingIndices[0] : -1;
  String get correctLetter =>
      correctLetters.isNotEmpty ? correctLetters[0] : '';
}
