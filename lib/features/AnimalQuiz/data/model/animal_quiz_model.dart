class AnimalQuizModel {
  AnimalQuizModel({
    required this.animalName,
    required this.animalImage,
    required this.value,
    this.accepting = false,
  });
  final String animalName;
  final String animalImage;
  final String value;
  bool accepting;
}
