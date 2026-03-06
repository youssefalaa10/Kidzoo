import 'package:kidzoo/core/utils/assets.dart';
class AlphabetModel {
  AlphabetModel({
    required this.letter,
    required this.imagePath,
    required this.example,
  });
  final String letter;
  final String imagePath;
  final String example;

  static final List<AlphabetModel> alphabets = [
    AlphabetModel(
        letter: 'A', imagePath: Assets.genImagesAlphabetA, example: 'Axe'),
    AlphabetModel(
        letter: 'B',
        imagePath: Assets.genImagesAlphabetB,
        example: 'Ball'),
    AlphabetModel(
        letter: 'C',
        imagePath: Assets.genImagesAlphabetC,
        example: 'Cold'),
    AlphabetModel(
        letter: 'D',
        imagePath: Assets.genImagesAlphabetD,
        example: 'Dice'),
    AlphabetModel(
        letter: 'E', imagePath: Assets.genImagesAlphabetE, example: 'Egg'),
    AlphabetModel(
        letter: 'F',
        imagePath: Assets.genImagesAlphabetF,
        example: 'Fish'),
    AlphabetModel(
        letter: 'G',
        imagePath: Assets.genImagesAlphabetG,
        example: 'Glasses'),
    AlphabetModel(
        letter: 'H', imagePath: Assets.genImagesAlphabetH, example: 'Hat'),
    AlphabetModel(
        letter: 'I',
        imagePath: Assets.genImagesAlphabetI,
        example: 'Ice cream'),
    AlphabetModel(
        letter: 'J',
        imagePath: Assets.genImagesAlphabetJ,
        example: 'Juice'),
    AlphabetModel(
        letter: 'K',
        imagePath: Assets.genImagesAlphabetK,
        example: 'Knife'),
    AlphabetModel(
        letter: 'L',
        imagePath: Assets.genImagesAlphabetL,
        example: 'Light'),
    AlphabetModel(
        letter: 'M',
        imagePath: Assets.genImagesAlphabetM,
        example: 'Music'),
    AlphabetModel(
        letter: 'N', imagePath: Assets.genImagesAlphabetN, example: 'Nut'),
    AlphabetModel(
        letter: 'O', imagePath: Assets.genImagesAlphabetO, example: 'Owl'),
    AlphabetModel(
        letter: 'P',
        imagePath: Assets.genImagesAlphabetP,
        example: 'Pencil'),
    AlphabetModel(
        letter: 'Q',
        imagePath: Assets.genImagesAlphabetQ,
        example: 'Queen'),
    AlphabetModel(
        letter: 'R',
        imagePath: Assets.genImagesAlphabetR,
        example: 'Ruler'),
    AlphabetModel(
        letter: 'S',
        imagePath: Assets.genImagesAlphabetS,
        example: 'Star'),
    AlphabetModel(
        letter: 'T',
        imagePath: Assets.genImagesAlphabetT,
        example: 'Tree'),
    AlphabetModel(
        letter: 'U',
        imagePath: Assets.genImagesAlphabetU,
        example: 'Umbrella'),
    AlphabetModel(
        letter: 'V', imagePath: Assets.genImagesAlphabetV, example: 'Van'),
    AlphabetModel(
        letter: 'W',
        imagePath: Assets.genImagesAlphabetW,
        example: 'Watch'),
    AlphabetModel(
        letter: 'X',
        imagePath: Assets.genImagesAlphabetX,
        example: 'X-ray'),
    AlphabetModel(
        letter: 'Y',
        imagePath: Assets.genImagesAlphabetY,
        example: 'Yellow'),
    AlphabetModel(
        letter: 'Z',
        imagePath: Assets.genImagesAlphabetZ,
        example: 'Zoom'),
  ];
}