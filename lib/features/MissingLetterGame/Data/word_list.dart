import 'dart:math';

import 'Model/word_model.dart';

class WordList {
  static final List<Word> allWords = [
    // 1
    Word(
      word: 'Apple',
      missingIndices: [0],
      options: ['A', 'E', 'I', 'O'],
      correctLetters: ['A'],
    ),
    // 2
    Word(
      word: 'Ball',
      missingIndices: [0],
      options: ['B', 'C', 'D', 'F'],
      correctLetters: ['B'],
    ),
    // 3
    Word(
      word: 'Cat',
      missingIndices: [0],
      options: ['C', 'K', 'S', 'T'],
      correctLetters: ['C'],
    ),
    // 4
    Word(
      word: 'Dog',
      missingIndices: [0],
      options: ['D', 'B', 'G', 'P'],
      correctLetters: ['D'],
    ),
    // 5
    Word(
      word: 'Elephant',
      missingIndices: [0],
      options: ['E', 'I', 'A', 'U'],
      correctLetters: ['E'],
    ),
    // 6
    Word(
      word: 'Fish',
      missingIndices: [0],
      options: ['F', 'P', 'V', 'T'],
      correctLetters: ['F'],
    ),
    // 7
    Word(
      word: 'Goat',
      missingIndices: [0],
      options: ['G', 'C', 'J', 'K'],
      correctLetters: ['G'],
    ),
    // 8
    Word(
      word: 'House',
      missingIndices: [0],
      options: ['H', 'Y', 'F', 'M'],
      correctLetters: ['H'],
    ),
    // 9
    Word(
      word: 'Ice',
      missingIndices: [0],
      options: ['I', 'E', 'Y', 'A'],
      correctLetters: ['I'],
    ),
    // 10
    Word(
      word: 'Jelly',
      missingIndices: [0],
      options: ['J', 'G', 'Y', 'I'],
      correctLetters: ['J'],
    ),
    // 11
    Word(
      word: 'Kite',
      missingIndices: [0],
      options: ['K', 'C', 'Q', 'X'],
      correctLetters: ['K'],
    ),
    // 12
    Word(
      word: 'Lion',
      missingIndices: [0],
      options: ['L', 'I', 'T', 'Y'],
      correctLetters: ['L'],
    ),
    // 13
    Word(
      word: 'Moon',
      missingIndices: [0],
      options: ['M', 'N', 'W', 'V'],
      correctLetters: ['M'],
    ),
    // 14
    Word(
      word: 'Nest',
      missingIndices: [0],
      options: ['N', 'M', 'H', 'R'],
      correctLetters: ['N'],
    ),
    // 15
    Word(
      word: 'Orange',
      missingIndices: [0],
      options: ['O', 'A', 'U', 'I'],
      correctLetters: ['O'],
    ),
    // 16
    Word(
      word: 'Pen',
      missingIndices: [0],
      options: ['P', 'B', 'D', 'Q'],
      correctLetters: ['P'],
    ),
    // 17
    Word(
      word: 'Queen',
      missingIndices: [0],
      options: ['Q', 'K', 'C', 'G'],
      correctLetters: ['Q'],
    ),
    // 18
    Word(
      word: 'Rabbit',
      missingIndices: [0],
      options: ['R', 'P', 'L', 'W'],
      correctLetters: ['R'],
    ),
    // 19
    Word(
      word: 'Sun',
      missingIndices: [0],
      options: ['S', 'Z', 'C', 'X'],
      correctLetters: ['S'],
    ),
    // 20
    Word(
      word: 'Tree',
      missingIndices: [0],
      options: ['T', 'D', 'F', 'P'],
      correctLetters: ['T'],
    ),
    // 21
    Word(
      word: 'Umbrella',
      missingIndices: [0],
      options: ['U', 'A', 'O', 'E'],
      correctLetters: ['U'],
    ),
    // 22
    Word(
      word: 'Van',
      missingIndices: [0],
      options: ['V', 'W', 'F', 'B'],
      correctLetters: ['V'],
    ),
    // 23
    Word(
      word: 'Water',
      missingIndices: [0],
      options: ['W', 'V', 'U', 'M'],
      correctLetters: ['W'],
    ),
    // 24
    Word(
      word: 'Xylophone',
      missingIndices: [0],
      options: ['X', 'Z', 'S', 'K'],
      correctLetters: ['X'],
    ),
    // 25
    Word(
      word: 'Zebra',
      missingIndices: [0],
      options: ['Z', 'S', 'X', 'C'],
      correctLetters: ['Z'],
    ),
  ];

  static Word getWordAtIndex(int index) {
    if (index < 0 || index >= allWords.length) {
      return allWords[0];
    }
    final originalWord = allWords[index];

    // Randomly decide if this word should have 1, 2, or 3 missing letters
    final random = Random();
    final missingCount = random.nextInt(3) + 1; // 1, 2, or 3

    if (missingCount == 1) {
      // Single missing letter (original behavior)
      return Word.withSingleMissingLetter(
        word: originalWord.word,
        missingIndex: originalWord.missingIndex,
        correctLetter: originalWord.correctLetter,
      );
    } else if (missingCount == 2 && originalWord.word.length >= 3) {
      // Two missing letters
      final firstIndex = originalWord.missingIndex;
      int secondIndex;
      do {
        secondIndex = random.nextInt(originalWord.word.length);
      } while (secondIndex == firstIndex);

      final firstLetter = originalWord.word[firstIndex];
      final secondLetter = originalWord.word[secondIndex];

      return Word.withRandomizedOptions(
        word: originalWord.word,
        missingIndices: [firstIndex, secondIndex],
        correctLetters: [firstLetter, secondLetter],
      );
    } else if (missingCount == 3 && originalWord.word.length >= 4) {
      // Three missing letters
      final indices = <int>{originalWord.missingIndex};
      while (indices.length < 3 && indices.length < originalWord.word.length) {
        indices.add(random.nextInt(originalWord.word.length));
      }
      final sortedIndices = indices.toList()..sort();
      final letters = sortedIndices.map((i) => originalWord.word[i]).toList();

      return Word.withRandomizedOptions(
        word: originalWord.word,
        missingIndices: sortedIndices,
        correctLetters: letters,
      );
    } else {
      // Fallback to single missing letter
      return Word.withSingleMissingLetter(
        word: originalWord.word,
        missingIndex: originalWord.missingIndex,
        correctLetter: originalWord.correctLetter,
      );
    }
  }

  static int getTotalWords() => allWords.length;

  static Word getRandomWord({int? excludeIndex}) {
    final random = Random();
    int index;
    do {
      index = random.nextInt(allWords.length);
    } while (excludeIndex != null && index == excludeIndex);
    return getWordAtIndex(index);
  }
}
