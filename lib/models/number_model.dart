class NumberModel {
  final String num;
  final String imagePath;
  final String example;

  NumberModel({
    required this.num,
    required this.imagePath,
    required this.example,
  });

  static final List<NumberModel> numbers = [
    NumberModel(num: '1', imagePath: 'assets/images/numbers/1.png', example: 'One'),
    NumberModel(num: '2', imagePath: 'assets/images/numbers/2.png', example: 'Two'),
    NumberModel(num: '3', imagePath: 'assets/images/numbers/3.png', example: 'Three'),
    NumberModel(num: '4', imagePath: 'assets/images/numbers/4.png', example: 'Four'),
    NumberModel(num: '5', imagePath: 'assets/images/numbers/5.png', example: 'Five'),
    NumberModel(num: '6', imagePath: 'assets/images/numbers/6.png', example: 'Six'),
    NumberModel(num: '7', imagePath: 'assets/images/numbers/7.png', example: 'Seven'),
    NumberModel(num: '8', imagePath: 'assets/images/numbers/8.png', example: 'Eight'),
    NumberModel(num: '9', imagePath: 'assets/images/numbers/9.png', example: 'Nine'),
    NumberModel(num: '10', imagePath: 'assets/images/numbers/10.png', example: 'Ten'),
  ];
}
