import 'package:flutter/material.dart';

class QuizImageCard extends StatelessWidget {
  const QuizImageCard({required this.imagePath, super.key});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(imagePath, height: 150);
  }
}
