import 'dart:math';

import 'Model/word_model.dart';

class WordList {
  static final List<Word> allWords = [
    Word(word: 'Apple', missingIndices: [0], options: ['A', 'E', 'I', 'O'], correctLetters: ['A'], imagePath: 'assets/gen/images/fruits/apple.png'),
    Word(word: 'Banana', missingIndices: [0], options: ['B', 'P', 'D', 'V'], correctLetters: ['B'], imagePath: 'assets/gen/images/fruits/banana.png'),
    Word(word: 'Grapes', missingIndices: [0], options: ['G', 'J', 'C', 'K'], correctLetters: ['G'], imagePath: 'assets/gen/images/fruits/grapes.png'),
    Word(word: 'Mango', missingIndices: [0], options: ['M', 'N', 'W', 'V'], correctLetters: ['M'], imagePath: 'assets/gen/images/fruits/mango.png'),
    Word(word: 'Orange', missingIndices: [0], options: ['O', 'A', 'U', 'E'], correctLetters: ['O'], imagePath: 'assets/gen/images/fruits/orange.png'),
    Word(word: 'Carrot', missingIndices: [0], options: ['C', 'K', 'S', 'T'], correctLetters: ['C'], imagePath: 'assets/gen/images/vegetables/carrot.png'),
    Word(word: 'Tomato', missingIndices: [0], options: ['T', 'D', 'P', 'F'], correctLetters: ['T'], imagePath: 'assets/gen/images/vegetables/tomato.png'),
    Word(word: 'Potato', missingIndices: [0], options: ['P', 'B', 'D', 'Q'], correctLetters: ['P'], imagePath: 'assets/gen/images/vegetables/potato.png'),
    Word(word: 'Lemon', missingIndices: [0], options: ['L', 'R', 'M', 'N'], correctLetters: ['L'], imagePath: 'assets/gen/images/vegetables/lemon.png'),
    Word(word: 'Onion', missingIndices: [0], options: ['O', 'U', 'A', 'E'], correctLetters: ['O'], imagePath: 'assets/gen/images/vegetables/onion.png'),
    Word(word: 'Car', missingIndices: [0], options: ['C', 'K', 'G', 'S'], correctLetters: ['C'], imagePath: 'assets/gen/images/vehicles/car.png'),
    Word(word: 'Bus', missingIndices: [0], options: ['B', 'P', 'D', 'V'], correctLetters: ['B'], imagePath: 'assets/gen/images/vehicles/bus.png'),
    Word(word: 'Train', missingIndices: [0], options: ['T', 'D', 'F', 'P'], correctLetters: ['T'], imagePath: 'assets/gen/images/vehicles/train.png'),
    Word(word: 'Airplane', missingIndices: [0], options: ['A', 'E', 'I', 'U'], correctLetters: ['A'], imagePath: 'assets/gen/images/vehicles/airplane.png'),
    Word(word: 'Bicycle', missingIndices: [0], options: ['B', 'P', 'D', 'V'], correctLetters: ['B'], imagePath: 'assets/gen/images/vehicles/bicycle.png'),
    Word(word: 'Cat', missingIndices: [0], options: ['C', 'K', 'S', 'T'], correctLetters: ['C'], imagePath: 'assets/gen/images/animal/cat.png'),
    Word(word: 'Dog', missingIndices: [0], options: ['D', 'B', 'G', 'P'], correctLetters: ['D'], imagePath: 'assets/gen/images/animal/dog.png'),
    Word(word: 'Cow', missingIndices: [0], options: ['C', 'K', 'G', 'Q'], correctLetters: ['C'], imagePath: 'assets/gen/images/animal/cow.png'),
    Word(word: 'Bird', missingIndices: [0], options: ['B', 'P', 'D', 'V'], correctLetters: ['B'], imagePath: 'assets/gen/images/animal/bird.png'),
    Word(word: 'Lion', missingIndices: [0], options: ['L', 'I', 'T', 'Y'], correctLetters: ['L'], imagePath: 'assets/gen/images/animal/lion.png'),
    Word(word: 'Elephant', missingIndices: [0], options: ['E', 'I', 'A', 'U'], correctLetters: ['E'], imagePath: 'assets/gen/images/animal/elephant.png'),
    Word(word: 'Panda', missingIndices: [0], options: ['P', 'B', 'D', 'Q'], correctLetters: ['P'], imagePath: 'assets/gen/images/animal/panda.png'),
    Word(word: 'Horse', missingIndices: [0], options: ['H', 'Y', 'F', 'M'], correctLetters: ['H'], imagePath: 'assets/gen/images/animal/horse.png'),
    Word(word: 'Sheep', missingIndices: [0], options: ['S', 'Z', 'C', 'X'], correctLetters: ['S'], imagePath: 'assets/gen/images/animal/sheep.png'),
    Word(word: 'Giraffe', missingIndices: [0], options: ['G', 'J', 'C', 'K'], correctLetters: ['G'], imagePath: 'assets/gen/images/animal/giraffe.png'),
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
        imagePath: originalWord.imagePath,
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
        imagePath: originalWord.imagePath,
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
        imagePath: originalWord.imagePath,
      );
    } else {
      // Fallback to single missing letter
      return Word.withSingleMissingLetter(
        word: originalWord.word,
        missingIndex: originalWord.missingIndex,
        correctLetter: originalWord.correctLetter,
        imagePath: originalWord.imagePath,
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
