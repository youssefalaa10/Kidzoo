import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/shared/tts_helper.dart';

import '../../../models/alphabet_model.dart';
import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_event.dart';

class AlphabetSelection extends StatelessWidget {
  const AlphabetSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final TtsHelper ttsHelper = TtsHelper();

    final List<AlphabetModel> alphabets = AlphabetModel.alphabets;

    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 3
            : 4;

    double childAspectRatio = screenWidth < 600 ? 1.2 : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: alphabets.length,
      itemBuilder: (context, index) {
        final alphabet = alphabets[index];

        return GestureDetector(
          onTap: () {
            BlocProvider.of<AlphabetBloc>(context)
                .add(SelectAlphabetEvent(alphabet.letter));
            ttsHelper.speak("${alphabet.letter}  ${alphabet.example}");
          },
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Image.asset(alphabet.imagePath),
          ),
        );
      },
    );
  }
}
