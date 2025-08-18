class PuzzleModel {
  PuzzleModel({
    required this.image,
    required this.index,
    this.accepting = false,
  });
  final String image;
  final int index;
  bool accepting;
}
