import 'package:flutter/material.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';
import 'package:kidzoo/features/AppCategory/education_screen.dart';
import 'package:kidzoo/features/Shapes/widgets/custom_button.dart';

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({required this.onPressedGameOVer, super.key});
  final Function() onPressedGameOVer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Image.asset(
            ImageManager.shapesBackground,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.fitHeight,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  ImageManager.checked,
                  height: 200,
                ),
                const SizedBox(height: 30),
                CustomButton(
                  title: 'Play Again',
                  onPressed: onPressedGameOVer,
                  color: Colors.teal,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  title: 'Exit',
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EducationScreen()),
                      (route) => false,
                    );
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
