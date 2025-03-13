import 'package:flutter/material.dart';
import 'package:kidzoo/modules/Shapes/widgets/custom_button.dart';
import 'package:kidzoo/modules/home/UI/home_screen.dart';
import 'package:kidzoo/shared/style/image_manager.dart';

class CompleteScreen extends StatelessWidget {
  final Function() onPressedGameOVer;

  const CompleteScreen({super.key, required this.onPressedGameOVer});

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
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return const HomeScreen();
                    }));
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
