import 'package:flutter/material.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/utils/assets.dart';
class AlphabetModel {
  AlphabetModel({
    required this.letter,
    required this.imagePath,
    required this.example,
    required this.exampleKey,
  });
  final String letter;
  final String imagePath;
  final String example;
  final String exampleKey;

  String getLocalizedExample(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (exampleKey) {
      case 'axe': return l10n.axe;
      case 'ball': return l10n.ball;
      case 'cold': return l10n.cold;
      case 'dice': return l10n.dice;
      case 'egg': return l10n.egg;
      case 'fish': return l10n.fish;
      case 'glasses': return l10n.glasses;
      case 'hat': return l10n.hat;
      case 'iceCream': return l10n.iceCream;
      case 'juice': return l10n.juice;
      case 'knife': return l10n.knife;
      case 'light': return l10n.lightExample;
      case 'music': return l10n.musicExample;
      case 'nut': return l10n.nut;
      case 'owl': return l10n.owl;
      case 'pencil': return l10n.pencil;
      case 'queen': return l10n.queen;
      case 'ruler': return l10n.ruler;
      case 'star': return l10n.star;
      case 'tree': return l10n.tree;
      case 'umbrella': return l10n.umbrella;
      case 'van': return l10n.van;
      case 'watch': return l10n.watch;
      case 'xRay': return l10n.xRay;
      case 'yellow': return l10n.yellow;
      case 'zoom': return l10n.zoom;
      default: return example;
    }
  }

  static final List<AlphabetModel> alphabets = [
    AlphabetModel(
        letter: 'A', imagePath: Assets.genImagesAlphabetA, example: 'Axe', exampleKey: 'axe'),
    AlphabetModel(
        letter: 'B',
        imagePath: Assets.genImagesAlphabetB,
        example: 'Ball',
        exampleKey: 'ball'),
    AlphabetModel(
        letter: 'C',
        imagePath: Assets.genImagesAlphabetC,
        example: 'Cold',
        exampleKey: 'cold'),
    AlphabetModel(
        letter: 'D',
        imagePath: Assets.genImagesAlphabetD,
        example: 'Dice',
        exampleKey: 'dice'),
    AlphabetModel(
        letter: 'E', imagePath: Assets.genImagesAlphabetE, example: 'Egg', exampleKey: 'egg'),
    AlphabetModel(
        letter: 'F',
        imagePath: Assets.genImagesAlphabetF,
        example: 'Fish',
        exampleKey: 'fish'),
    AlphabetModel(
        letter: 'G',
        imagePath: Assets.genImagesAlphabetG,
        example: 'Glasses',
        exampleKey: 'glasses'),
    AlphabetModel(
        letter: 'H', imagePath: Assets.genImagesAlphabetH, example: 'Hat', exampleKey: 'hat'),
    AlphabetModel(
        letter: 'I',
        imagePath: Assets.genImagesAlphabetI,
        example: 'Ice cream',
        exampleKey: 'iceCream'),
    AlphabetModel(
        letter: 'J',
        imagePath: Assets.genImagesAlphabetJ,
        example: 'Juice',
        exampleKey: 'juice'),
    AlphabetModel(
        letter: 'K',
        imagePath: Assets.genImagesAlphabetK,
        example: 'Knife',
        exampleKey: 'knife'),
    AlphabetModel(
        letter: 'L',
        imagePath: Assets.genImagesAlphabetL,
        example: 'Light',
        exampleKey: 'light'),
    AlphabetModel(
        letter: 'M',
        imagePath: Assets.genImagesAlphabetM,
        example: 'Music',
        exampleKey: 'music'),
    AlphabetModel(
        letter: 'N', imagePath: Assets.genImagesAlphabetN, example: 'Nut', exampleKey: 'nut'),
    AlphabetModel(
        letter: 'O', imagePath: Assets.genImagesAlphabetO, example: 'Owl', exampleKey: 'owl'),
    AlphabetModel(
        letter: 'P',
        imagePath: Assets.genImagesAlphabetP,
        example: 'Pencil',
        exampleKey: 'pencil'),
    AlphabetModel(
        letter: 'Q',
        imagePath: Assets.genImagesAlphabetQ,
        example: 'Queen',
        exampleKey: 'queen'),
    AlphabetModel(
        letter: 'R',
        imagePath: Assets.genImagesAlphabetR,
        example: 'Ruler',
        exampleKey: 'ruler'),
    AlphabetModel(
        letter: 'S',
        imagePath: Assets.genImagesAlphabetS,
        example: 'Star',
        exampleKey: 'star'),
    AlphabetModel(
        letter: 'T',
        imagePath: Assets.genImagesAlphabetT,
        example: 'Tree',
        exampleKey: 'tree'),
    AlphabetModel(
        letter: 'U',
        imagePath: Assets.genImagesAlphabetU,
        example: 'Umbrella',
        exampleKey: 'umbrella'),
    AlphabetModel(
        letter: 'V', imagePath: Assets.genImagesAlphabetV, example: 'Van', exampleKey: 'van'),
    AlphabetModel(
        letter: 'W',
        imagePath: Assets.genImagesAlphabetW,
        example: 'Watch',
        exampleKey: 'watch'),
    AlphabetModel(
        letter: 'X',
        imagePath: Assets.genImagesAlphabetX,
        example: 'X-ray',
        exampleKey: 'xRay'),
    AlphabetModel(
        letter: 'Y',
        imagePath: Assets.genImagesAlphabetY,
        example: 'Yellow',
        exampleKey: 'yellow'),
    AlphabetModel(
        letter: 'Z',
        imagePath: Assets.genImagesAlphabetZ,
        example: 'Zoom',
        exampleKey: 'zoom'),
  ];
}