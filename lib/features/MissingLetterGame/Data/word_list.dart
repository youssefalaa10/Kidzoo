import 'dart:math';

import 'Model/word_model.dart';

/// Static bank of words for the Missing Letters game. Difficulty (how many
/// letters are hidden and which positions) is decided by
/// [MissingLetterCubit], not baked into this list.
class WordList {
  static const List<WordEntry> allWords = [
    WordEntry(word: 'Apple', imagePath: 'assets/gen/images/fruits/apple.png', category: 'fruits'),
    WordEntry(word: 'Banana', imagePath: 'assets/gen/images/fruits/banana.png', category: 'fruits'),
    WordEntry(word: 'Grapes', imagePath: 'assets/gen/images/fruits/grapes.png', category: 'fruits'),
    WordEntry(word: 'Mango', imagePath: 'assets/gen/images/fruits/mango.png', category: 'fruits'),
    WordEntry(word: 'Orange', imagePath: 'assets/gen/images/fruits/orange.png', category: 'fruits'),
    WordEntry(word: 'Carrot', imagePath: 'assets/gen/images/vegetables/carrot.png', category: 'vegetables'),
    WordEntry(word: 'Tomato', imagePath: 'assets/gen/images/vegetables/tomato.png', category: 'vegetables'),
    WordEntry(word: 'Potato', imagePath: 'assets/gen/images/vegetables/potato.png', category: 'vegetables'),
    WordEntry(word: 'Lemon', imagePath: 'assets/gen/images/vegetables/lemon.png', category: 'vegetables'),
    WordEntry(word: 'Onion', imagePath: 'assets/gen/images/vegetables/onion.png', category: 'vegetables'),
    WordEntry(word: 'Car', imagePath: 'assets/gen/images/vehicles/car.png', category: 'vehicles'),
    WordEntry(word: 'Bus', imagePath: 'assets/gen/images/vehicles/bus.png', category: 'vehicles'),
    WordEntry(word: 'Train', imagePath: 'assets/gen/images/vehicles/train.png', category: 'vehicles'),
    WordEntry(word: 'Airplane', imagePath: 'assets/gen/images/vehicles/airplane.png', category: 'vehicles'),
    WordEntry(word: 'Bicycle', imagePath: 'assets/gen/images/vehicles/bicycle.png', category: 'vehicles'),
    WordEntry(word: 'Cat', imagePath: 'assets/gen/images/animal/cat.png', category: 'animals'),
    WordEntry(word: 'Dog', imagePath: 'assets/gen/images/animal/dog.png', category: 'animals'),
    WordEntry(word: 'Cow', imagePath: 'assets/gen/images/animal/cow.png', category: 'animals'),
    WordEntry(word: 'Bird', imagePath: 'assets/gen/images/animal/bird.png', category: 'animals'),
    WordEntry(word: 'Lion', imagePath: 'assets/gen/images/animal/lion.png', category: 'animals'),
    WordEntry(word: 'Elephant', imagePath: 'assets/gen/images/animal/elephant.png', category: 'animals'),
    WordEntry(word: 'Panda', imagePath: 'assets/gen/images/animal/panda.png', category: 'animals'),
    WordEntry(word: 'Horse', imagePath: 'assets/gen/images/animal/horse.png', category: 'animals'),
    WordEntry(word: 'Sheep', imagePath: 'assets/gen/images/animal/sheep.png', category: 'animals'),
    WordEntry(word: 'Giraffe', imagePath: 'assets/gen/images/animal/giraffe.png', category: 'animals'),
  ];

  static WordEntry getBaseWordAtIndex(int index) {
    if (index < 0 || index >= allWords.length) return allWords[0];
    return allWords[index];
  }

  static int getTotalWords() => allWords.length;

  static WordEntry getRandomWord({int? excludeIndex}) {
    final random = Random();
    int index;
    do {
      index = random.nextInt(allWords.length);
    } while (excludeIndex != null && allWords.length > 1 && index == excludeIndex);
    return allWords[index];
  }
}
