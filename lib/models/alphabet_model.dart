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
    AlphabetModel(letter: 'A', imagePath: 'assets/images/a.png', example: 'Axe'),
    AlphabetModel(letter: 'B', imagePath: 'assets/images/b.png', example: 'Ball'),
    AlphabetModel(letter: 'C', imagePath: 'assets/images/c.png', example: 'Cold'),
    AlphabetModel(letter: 'D', imagePath: 'assets/images/d.png', example: 'Dice'),
    AlphabetModel(letter: 'E', imagePath: 'assets/images/e.png', example: 'Egg'),
    AlphabetModel(letter: 'F', imagePath: 'assets/images/f.png', example: 'Fish'),
    AlphabetModel(letter: 'G', imagePath: 'assets/images/g.png', example: 'Glasses'),
    AlphabetModel(letter: 'H', imagePath: 'assets/images/h.png', example: 'Hat'),
    AlphabetModel(letter: 'I', imagePath: 'assets/images/i.png', example: 'Ice cream'),
    AlphabetModel(letter: 'J', imagePath: 'assets/images/j.png', example: 'Juice'),
    AlphabetModel(letter: 'K', imagePath: 'assets/images/k.png', example: 'Knife'),
    AlphabetModel(letter: 'L', imagePath: 'assets/images/l.png', example: 'Light'),
    AlphabetModel(letter: 'M', imagePath: 'assets/images/m.png', example: 'Music'),
    AlphabetModel(letter: 'N', imagePath: 'assets/images/n.png', example: 'Nut'),
    AlphabetModel(letter: 'O', imagePath: 'assets/images/o.png', example: 'Owl'),
    AlphabetModel(letter: 'P', imagePath: 'assets/images/p.png', example: 'Pencil'),
    AlphabetModel(letter: 'Q', imagePath: 'assets/images/q.png', example: 'Queen'),
    AlphabetModel(letter: 'R', imagePath: 'assets/images/r.png', example: 'Ruler'),
    AlphabetModel(letter: 'S', imagePath: 'assets/images/s.png', example: 'Star'),
    AlphabetModel(letter: 'T', imagePath: 'assets/images/t.png', example: 'Tree'),
    AlphabetModel(letter: 'U', imagePath: 'assets/images/u.png', example: 'Umbrella'),
    AlphabetModel(letter: 'V', imagePath: 'assets/images/v.png', example: 'Van'),
    AlphabetModel(letter: 'W', imagePath: 'assets/images/w.png', example: 'Watch'),
    AlphabetModel(letter: 'X', imagePath: 'assets/images/x.png', example: 'X-ray'),
    AlphabetModel(letter: 'Y', imagePath: 'assets/images/y.png', example: 'Yellow'),
    AlphabetModel(letter: 'Z', imagePath: 'assets/images/z.png', example: 'Zoom'),
  ];
}
