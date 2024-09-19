import 'package:flutter/material.dart';

import 'widgets/alphabet_display.dart';
import 'widgets/alphabet_selection.dart';

class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alphabets',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: const Row(
        children: [
          // Left side: Alphabet display area
          Expanded(
            flex: 6,
            child: AlphabetDisplay(),
          ),

          // Right side: Alphabet selection area
          Expanded(
            flex: 4,
            child: AlphabetSelection(),
          ),
        ],
      ),
    );
  }
}
