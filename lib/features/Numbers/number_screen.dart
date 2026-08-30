import 'package:flutter/material.dart';
import 'package:kidzo/core/mixins/background_music_mixin.dart';
import 'package:kidzo/features/Numbers/UI/widgets/number_app_bar.dart';
import 'package:kidzo/features/Numbers/UI/widgets/number_display.dart';
import 'package:kidzo/features/Numbers/UI/widgets/number_selection.dart';

class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> with TTSMusicMixin {
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
            child: Container(
              color: Colors.white,
              child: const NumberSelection(),
            ),
          ),
        ],
      ),
    );
  }
}
