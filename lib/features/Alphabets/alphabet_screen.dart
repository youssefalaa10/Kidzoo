import 'package:flutter/material.dart';
import 'package:kidzoo/features/Alphabets/widgets/alphabet_app_bar.dart';

import 'widgets/alphabet_display.dart';
import 'widgets/alphabet_selection.dart';

class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      body: Row(
        children: [
          // Left side: Alphabet display area
          const Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlphabetAppBar(),
                AlphabetDisplay(),
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
                  AlphabetSelection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
