import 'package:kidzoo/core/utils/assets.dart';
class NumberModel {
  NumberModel({
    required this.num,
    required this.imagePath,
    required this.example,
  });
  final String num;
  final String imagePath;
  final String example;

  static final List<NumberModel> numbers = [
    NumberModel(
        num: '1', imagePath: Assets.genImagesNumbers1, example: 'One'),
    NumberModel(
        num: '2', imagePath: Assets.genImagesNumbers2, example: 'Two'),
    NumberModel(
        num: '3', imagePath: Assets.genImagesNumbers3, example: 'Three'),
    NumberModel(
        num: '4', imagePath: Assets.genImagesNumbers4, example: 'Four'),
    NumberModel(
        num: '5', imagePath: Assets.genImagesNumbers5, example: 'Five'),
    NumberModel(
        num: '6', imagePath: Assets.genImagesNumbers6, example: 'Six'),
    NumberModel(
        num: '7', imagePath: Assets.genImagesNumbers7, example: 'Seven'),
    NumberModel(
        num: '8', imagePath: Assets.genImagesNumbers8, example: 'Eight'),
    NumberModel(
        num: '9', imagePath: Assets.genImagesNumbers9, example: 'Nine'),
    NumberModel(
        num: '10', imagePath: Assets.genImagesNumbers10, example: 'Ten'),
  ];
}