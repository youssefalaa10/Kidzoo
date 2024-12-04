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
    NumberModel(num: '1', imagePath: 'assets/images/numbers/1.svg', example: 'One'),
    NumberModel(num: '2', imagePath: 'assets/images/numbers/2.svg', example: 'Two'),
    NumberModel(num: '3', imagePath: 'assets/images/numbers/3.svg', example: 'Three'),
    NumberModel(num: '4', imagePath: 'assets/images/numbers/4.svg', example: 'Four'),
    NumberModel(num: '5', imagePath: 'assets/images/numbers/5.svg', example: 'Five'),
    NumberModel(num: '6', imagePath: 'assets/images/numbers/6.svg', example: 'Six'),
    NumberModel(num: '7', imagePath: 'assets/images/numbers/7.svg', example: 'Seven'),
    NumberModel(num: '8', imagePath: 'assets/images/numbers/8.svg', example: 'Eight'),
    NumberModel(num: '9', imagePath: 'assets/images/numbers/9.svg', example: 'Nine'),
    NumberModel(num: '10', imagePath: 'assets/images/numbers/10.svg', example: 'Ten'),
  ];
}
