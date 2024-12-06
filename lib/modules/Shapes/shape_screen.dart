import 'package:flutter/material.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_app_bar.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_display.dart';
import 'package:kidzoo/modules/Shapes/widgets/shape_selection.dart';

class ShapeScreen extends StatelessWidget {
  const ShapeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      body: Row(
        children: [
          // Left side: Shape display area
          const Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShapeAppBar(),
                ShapeDisplay(),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShapeSelection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
