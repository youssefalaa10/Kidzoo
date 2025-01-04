import 'package:kidzoo/shared/style/image_manager.dart';

class ShapeModel {
  final String shape;
  final String temp;
  final String imagePath;

  ShapeModel({
    required this.shape,
    required this.temp,
    required this.imagePath,
  });

  static final List<ShapeModel> shapes = [
    ShapeModel(shape: 'Square', imagePath: ImageManager.square, temp: ImageManager.squareTemp),
    ShapeModel(shape: 'Triangle', imagePath: ImageManager.triangle, temp: ImageManager.triangleTemp),
    ShapeModel(shape: 'Circle', imagePath: ImageManager.circle, temp: ImageManager.circleTemp),
    ShapeModel(shape: 'Cylinder', imagePath: ImageManager.cylinder, temp: ImageManager.cylinderTemp),
    ShapeModel(shape: 'Diamond', imagePath: ImageManager.diamond, temp: ImageManager.diamondTemp),
    ShapeModel(shape: 'Pentagon', imagePath: ImageManager.pentagon, temp: ImageManager.pentagonTemp),
    ShapeModel(shape: 'Hexagon', imagePath: ImageManager.hexagon, temp: ImageManager.hexagonTemp),
    ShapeModel(shape: 'Star', imagePath: ImageManager.star, temp: ImageManager.starTemp),
  ];
}
