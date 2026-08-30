import 'dart:math';

/// A single base word entry from the word bank, before difficulty is applied.
class WordEntry {
  const WordEntry({
    required this.word,
    required this.imagePath,
    this.category = 'general',
  });

  final String word;
  final String imagePath;
  final String category;
}

/// A word instance prepared for gameplay: which letters are missing, the
/// letter choices shown to the child, and the correct answers for those gaps.
class Word {
  factory Word.withRandomizedOptions({
    required String word,
    required List<int> missingIndices,
    required List<String> correctLetters,
    required String imagePath,
    int distractorCount = 4,
  }) {
    final random = Random();
    final allLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

    for (final correctLetter in correctLetters) {
      allLetters.remove(correctLetter);
    }
    allLetters.shuffle(random);

    final wrongOptionsNeeded = max(0, distractorCount - correctLetters.length);
    final wrongOptions = allLetters.take(wrongOptionsNeeded).toList();
    final options = [...wrongOptions, ...correctLetters]..shuffle(random);

    return Word(
      word: word,
      missingIndices: missingIndices,
      options: options,
      correctLetters: correctLetters,
      imagePath: imagePath,
    );
  }

  const Word({
    required this.word,
    required this.missingIndices,
    required this.options,
    required this.correctLetters,
    required this.imagePath,
  });

  final String word; // e.g., "CAT" (already uppercased)
  final List<int> missingIndices; // e.g., [1] or [0, 2] for multiple gaps
  final List<String> options; // shuffled letter choices, e.g. ["C", "A", "G", "Y"]
  final List<String> correctLetters; // correct letters, in missingIndices order
  final String imagePath;
}
