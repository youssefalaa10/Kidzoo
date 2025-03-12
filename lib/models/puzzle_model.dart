class PuzzleModel {
  final String image;
  final int index;
  bool accepting;

  PuzzleModel({
    required this.image,
    required this.index,
    this.accepting = false,
  });
}