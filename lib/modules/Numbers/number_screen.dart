import 'package:flutter/material.dart';
import 'package:kidzoo/modules/Numbers/UI/widgets/number_app_bar.dart';
import 'package:kidzoo/modules/Numbers/UI/widgets/number_display.dart';
import 'package:kidzoo/modules/Numbers/UI/widgets/number_selection.dart';

class NumberScreen extends StatelessWidget {
  const NumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left side: Alphabet display area
          const Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NumberAppBar(),
                NumberDisplay(),
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
                  NumberSelection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
