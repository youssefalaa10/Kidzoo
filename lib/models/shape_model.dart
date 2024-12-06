class ShapeModel {
  final String shape;
  final String imagePath;
  final String example;

  ShapeModel({
    required this.shape,
    required this.imagePath,
    required this.example,
  });

  static final List<ShapeModel> shapes = [
    ShapeModel(shape: 'Square', imagePath: 'assets/images/shapes/square.svg', example: 'Square'),
    ShapeModel(shape: 'Triangle', imagePath: 'assets/images/shapes/triangle.svg', example: 'Triangle'),
    ShapeModel(shape: 'Circle', imagePath: 'assets/images/shapes/circle.svg', example: 'Circle'),
    ShapeModel(shape: 'Cylinder', imagePath: 'assets/images/shapes/cylinder.svg', example: 'Cylinder'),
    ShapeModel(shape: 'Diamond', imagePath: 'assets/images/shapes/diamond.svg', example: 'Diamond'),
    ShapeModel(shape: 'Pentagon', imagePath: 'assets/images/shapes/pentagon.svg', example: 'Pentagon'),
    ShapeModel(shape: 'Hexagon', imagePath: 'assets/images/shapes/hexagon.svg', example: 'Hexagon'),
    ShapeModel(shape: 'Star', imagePath: 'assets/images/shapes/star.svg', example: 'Star'),
  ];
}
