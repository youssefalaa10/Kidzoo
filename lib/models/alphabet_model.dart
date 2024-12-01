class AlphabetModel {
  final String letter;
  final String imagePath;
  final String example;

  AlphabetModel({
    required this.letter,
    required this.imagePath,
    required this.example,
  });

  static final List<AlphabetModel> alphabets = [
    AlphabetModel(letter: 'A', imagePath: 'assets/images/alphabet/a.png', example: 'Axe'),
    AlphabetModel(letter: 'B', imagePath: 'assets/images/alphabet/b.png', example: 'Ball'),
    AlphabetModel(letter: 'C', imagePath: 'assets/images/alphabet/c.png', example: 'Cold'),
    AlphabetModel(letter: 'D', imagePath: 'assets/images/alphabet/d.png', example: 'Dice'),
    AlphabetModel(letter: 'E', imagePath: 'assets/images/alphabet/e.png', example: 'Egg'),
    AlphabetModel(letter: 'F', imagePath: 'assets/images/alphabet/f.png', example: 'Fish'),
    AlphabetModel(letter: 'G', imagePath: 'assets/images/alphabet/g.png', example: 'Glasses'),
    AlphabetModel(letter: 'H', imagePath: 'assets/images/alphabet/h.png', example: 'Hat'),
    AlphabetModel(letter: 'I', imagePath: 'assets/images/alphabet/i.png', example: 'Ice cream'),
    AlphabetModel(letter: 'J', imagePath: 'assets/images/alphabet/j.png', example: 'Juice'),
    AlphabetModel(letter: 'K', imagePath: 'assets/images/alphabet/k.png', example: 'Knife'),
    AlphabetModel(letter: 'L', imagePath: 'assets/images/alphabet/l.png', example: 'Light'),
    AlphabetModel(letter: 'M', imagePath: 'assets/images/alphabet/m.png', example: 'Music'),
    AlphabetModel(letter: 'N', imagePath: 'assets/images/alphabet/n.png', example: 'Nut'),
    AlphabetModel(letter: 'O', imagePath: 'assets/images/alphabet/o.png', example: 'Owl'),
    AlphabetModel(letter: 'P', imagePath: 'assets/images/alphabet/p.png', example: 'Pencil'),
    AlphabetModel(letter: 'Q', imagePath: 'assets/images/alphabet/q.png', example: 'Queen'),
    AlphabetModel(letter: 'R', imagePath: 'assets/images/alphabet/r.png', example: 'Ruler'),
    AlphabetModel(letter: 'S', imagePath: 'assets/images/alphabet/s.png', example: 'Star'),
    AlphabetModel(letter: 'T', imagePath: 'assets/images/alphabet/t.png', example: 'Tree'),
    AlphabetModel(letter: 'U', imagePath: 'assets/images/alphabet/u.png', example: 'Umbrella'),
    AlphabetModel(letter: 'V', imagePath: 'assets/images/alphabet/v.png', example: 'Van'),
    AlphabetModel(letter: 'W', imagePath: 'assets/images/alphabet/w.png', example: 'Watch'),
    AlphabetModel(letter: 'X', imagePath: 'assets/images/alphabet/x.png', example: 'X-ray'),
    AlphabetModel(letter: 'Y', imagePath: 'assets/images/alphabet/y.png', example: 'Yellow'),
    AlphabetModel(letter: 'Z', imagePath: 'assets/images/alphabet/z.png', example: 'Zoom'),
  ];
}
