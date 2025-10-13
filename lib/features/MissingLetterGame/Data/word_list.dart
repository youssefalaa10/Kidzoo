import 'dart:math';
import 'Model/word_model.dart';

class WordList {
  static final List<Word> allWords = [
    // 1
    Word(
      word: 'Apple',
      missingIndex: 0,
      options: ['A', 'E', 'I', 'O'],
      correctLetter: 'A',
    ),
    // 2
    Word(
      word: 'Ball',
      missingIndex: 0,
      options: ['B', 'C', 'D', 'F'],
      correctLetter: 'B',
    ),
    // 3
    Word(
      word: 'Cat',
      missingIndex: 0,
      options: ['C', 'K', 'S', 'T'],
      correctLetter: 'C',
    ),
    // 4
    Word(
      word: 'Dog',
      missingIndex: 0,
      options: ['D', 'B', 'G', 'P'],
      correctLetter: 'D',
    ),
    // 5
    Word(
      word: 'Elephant',
      missingIndex: 0,
      options: ['E', 'I', 'A', 'U'],
      correctLetter: 'E',
    ),
    // 6
    Word(
      word: 'Fish',
      missingIndex: 0,
      options: ['F', 'P', 'V', 'T'],
      correctLetter: 'F',
    ),
    // 7
    Word(
      word: 'Goat',
      missingIndex: 0,
      options: ['G', 'C', 'J', 'K'],
      correctLetter: 'G',
    ),
    // 8
    Word(
      word: 'House',
      missingIndex: 0,
      options: ['H', 'Y', 'F', 'M'],
      correctLetter: 'H',
    ),
    // 9
    Word(
      word: 'Ice',
      missingIndex: 0,
      options: ['I', 'E', 'Y', 'A'],
      correctLetter: 'I',
    ),
    // 10
    Word(
      word: 'Jelly',
      missingIndex: 0,
      options: ['J', 'G', 'Y', 'I'],
      correctLetter: 'J',
    ),
    // 11
    Word(
      word: 'Kite',
      missingIndex: 0,
      options: ['K', 'C', 'Q', 'X'],
      correctLetter: 'K',
    ),
    // 12
    Word(
      word: 'Lion',
      missingIndex: 0,
      options: ['L', 'I', 'T', 'Y'],
      correctLetter: 'L',
    ),
    // 13
    Word(
      word: 'Moon',
      missingIndex: 0,
      options: ['M', 'N', 'W', 'V'],
      correctLetter: 'M',
    ),
    // 14
    Word(
      word: 'Nest',
      missingIndex: 0,
      options: ['N', 'M', 'H', 'R'],
      correctLetter: 'N',
    ),
    // 15
    Word(
      word: 'Orange',
      missingIndex: 0,
      options: ['O', 'A', 'U', 'I'],
      correctLetter: 'O',
    ),
    // 16
    Word(
      word: 'Pen',
      missingIndex: 0,
      options: ['P', 'B', 'D', 'Q'],
      correctLetter: 'P',
    ),
    // 17
    Word(
      word: 'Queen',
      missingIndex: 0,
      options: ['Q', 'K', 'C', 'G'],
      correctLetter: 'Q',
    ),
    // 18
    Word(
      word: 'Rabbit',
      missingIndex: 0,
      options: ['R', 'P', 'L', 'W'],
      correctLetter: 'R',
    ),
    // 19
    Word(
      word: 'Sun',
      missingIndex: 0,
      options: ['S', 'Z', 'C', 'X'],
      correctLetter: 'S',
    ),
    // 20
    Word(
      word: 'Tree',
      missingIndex: 0,
      options: ['T', 'D', 'F', 'P'],
      correctLetter: 'T',
    ),
    // 21
    Word(
      word: 'Umbrella',
      missingIndex: 0,
      options: ['U', 'A', 'O', 'E'],
      correctLetter: 'U',
    ),
    // 22
    Word(
      word: 'Van',
      missingIndex: 0,
      options: ['V', 'W', 'F', 'B'],
      correctLetter: 'V',
    ),
    // 23
    Word(
      word: 'Water',
      missingIndex: 0,
      options: ['W', 'V', 'U', 'M'],
      correctLetter: 'W',
    ),
    // 24
    Word(
      word: 'Xylophone',
      missingIndex: 0,
      options: ['X', 'Z', 'S', 'K'],
      correctLetter: 'X',
    ),
    // 25
    Word(
      word: 'Zebra',
      missingIndex: 0,
      options: ['Z', 'S', 'X', 'C'],
      correctLetter: 'Z',
    ),
  ];

  static Word getWordAtIndex(int index) {
    if (index < 0 || index >= allWords.length) {
      return allWords[0];
    }
    return allWords[index];
  }

  static int getTotalWords() => allWords.length;

  static Word getRandomWord({int? excludeIndex}) {
    final random = Random();
    int index;
    do {
      index = random.nextInt(allWords.length);
    } while (excludeIndex != null && index == excludeIndex);
    return allWords[index];
  }
}

