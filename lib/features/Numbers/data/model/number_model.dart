import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/utils/assets.dart';

class NumberModel {
  NumberModel({
    required this.num,
    required this.imagePath,
    required this.example,
    required this.exampleKey,
  });
  final String num;
  final String imagePath;
  final String example;
  final String exampleKey;

  String getLocalizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (exampleKey) {
      case 'one':
        return l10n.one;
      case 'two':
        return l10n.two;
      case 'three':
        return l10n.three;
      case 'four':
        return l10n.four;
      case 'five':
        return l10n.five;
      case 'six':
        return l10n.six;
      case 'seven':
        return l10n.seven;
      case 'eight':
        return l10n.eight;
      case 'nine':
        return l10n.nine;
      case 'ten':
        return l10n.ten;
      default:
        return example;
    }
  }

  static final List<NumberModel> numbers = [
    NumberModel(
        num: '1',
        imagePath: Assets.genImagesNumbers1,
        example: 'One',
        exampleKey: 'one'),
    NumberModel(
        num: '2',
        imagePath: Assets.genImagesNumbers2,
        example: 'Two',
        exampleKey: 'two'),
    NumberModel(
        num: '3',
        imagePath: Assets.genImagesNumbers3,
        example: 'Three',
        exampleKey: 'three'),
    NumberModel(
        num: '4',
        imagePath: Assets.genImagesNumbers4,
        example: 'Four',
        exampleKey: 'four'),
    NumberModel(
        num: '5',
        imagePath: Assets.genImagesNumbers5,
        example: 'Five',
        exampleKey: 'five'),
    NumberModel(
        num: '6',
        imagePath: Assets.genImagesNumbers6,
        example: 'Six',
        exampleKey: 'six'),
    NumberModel(
        num: '7',
        imagePath: Assets.genImagesNumbers7,
        example: 'Seven',
        exampleKey: 'seven'),
    NumberModel(
        num: '8',
        imagePath: Assets.genImagesNumbers8,
        example: 'Eight',
        exampleKey: 'eight'),
    NumberModel(
        num: '9',
        imagePath: Assets.genImagesNumbers9,
        example: 'Nine',
        exampleKey: 'nine'),
    NumberModel(
        num: '10',
        imagePath: Assets.genImagesNumbers10,
        example: 'Ten',
        exampleKey: 'ten'),
  ];
}
