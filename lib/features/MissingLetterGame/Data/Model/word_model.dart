import 'dart:math';

class Word {

  // Factory constructor to create a word with randomized options
  factory Word.withRandomizedOptions({
    required String word,
    required List<int> missingIndices,
    required List<String> correctLetters,
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
    // We need 4 total options, so if we have 1 correct letter, we need 3 wrong ones
    // If we have 2 correct letters, we need 2 wrong ones, etc.
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
    );
  }

  // Legacy factory for single missing letter (named differently to avoid conflict)
  factory Word.withSingleMissingLetter({
    required String word,
    required int missingIndex,
    required String correctLetter,
  }) {
    return Word.withRandomizedOptions(
      word: word,
      missingIndices: [missingIndex],
      correctLetters: [correctLetter],
    );
  }
  Word({
    required this.word,
    required this.missingIndices,
    required this.options,
    required this.correctLetters,
  });
  final String word; // e.g., "Can"
  final List<int> missingIndices; // e.g., [1] or [0, 2] for multiple missing letters
  final List<String> options; // e.g., ["C", "A", "G", "Y"]
  final List<String> correctLetters; // e.g., ["A"] or ["C", "N"]

  // Legacy support - single missing letter
  int get missingIndex => missingIndices.isNotEmpty ? missingIndices[0] : -1;
  String get correctLetter => correctLetters.isNotEmpty ? correctLetters[0] : '';
}
