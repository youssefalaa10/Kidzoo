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
    ShapeModel(shape: 'Square', imagePath: 'assets/images/shapes/square.png', temp: 'assets/images/shapes/square-temp.svg'),
    ShapeModel(shape: 'Triangle', imagePath: 'assets/images/shapes/triangle.png', temp: 'assets/images/shapes/triangle-temp.svg'),
    ShapeModel(shape: 'Circle', imagePath: 'assets/images/shapes/circle.png', temp: 'assets/images/shapes/circle-temp.svg'),
    ShapeModel(shape: 'Cylinder', imagePath: 'assets/images/shapes/cylinder.png', temp: 'assets/images/shapes/cylinder-temp.svg'),
    ShapeModel(shape: 'Diamond', imagePath: 'assets/images/shapes/diamond.png', temp: 'assets/images/shapes/diamond-temp.svg'),
    ShapeModel(shape: 'Pentagon', imagePath: 'assets/images/shapes/pentagon.png', temp: 'assets/images/shapes/pentagon-temp.svg'),
    ShapeModel(shape: 'Hexagon', imagePath: 'assets/images/shapes/hexagon.png', temp: 'assets/images/shapes/hexagon-temp.svg'),
    ShapeModel(shape: 'Star', imagePath: 'assets/images/shapes/star.png', temp: 'assets/images/shapes/star-temp.svg'),
  ];
}
