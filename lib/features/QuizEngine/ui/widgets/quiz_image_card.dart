import 'package:flutter/material.dart';

class QuizImageCard extends StatelessWidget {
  final String imagePath;
  const QuizImageCard({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(imagePath, height: 150);
  }
}
