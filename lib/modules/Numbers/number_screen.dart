import 'package:flutter/material.dart';
import 'package:kidzoo/modules/Numbers/UI/widgets/number_app_bar.dart';
import 'package:kidzoo/modules/Numbers/UI/widgets/number_display.dart';
import 'package:kidzoo/modules/Numbers/UI/widgets/number_selection.dart';

class NumberScreen extends StatelessWidget {
  const NumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Left side: Alphabet display area
          const Expanded(
            flex: 3,
            child: Column(
              children: [
                Row(
                  children: [
                    NumberAppBar(),
                    Spacer(),
                  ],
                ),
                NumberDisplay(),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: NumberSelection(),
            ),
          ),
        ],
      ),
    );
  }
}
