import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/helpers/tts_helper.dart';
import 'package:kidzoo/core/services/cubit/music_cubit.dart';

import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_event.dart';
import '../data/model/alphabet_model.dart';

class AlphabetSelection extends StatefulWidget {
  const AlphabetSelection({super.key});

  @override
  State<AlphabetSelection> createState() => _AlphabetSelectionState();
}

class _AlphabetSelectionState extends State<AlphabetSelection> {
  TtsHelper? _ttsHelper;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ttsHelper == null) {
      final musicCubit = context.read<MusicCubit>();
      final languageCode = Localizations.localeOf(context).languageCode;
      _ttsHelper = TtsHelper(
        musicCubit: musicCubit,
        languageCode: languageCode,
      );
    }
  }

  @override
  void dispose() {
    _ttsHelper?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final List<AlphabetModel> alphabets = AlphabetModel.alphabets;
    final screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 3
            : 4;

    final double childAspectRatio = screenWidth < 600 ? 1.2 : 1.5;

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
            final textToSpeak = languageCode == 'ar'
                ? '${alphabet.letter} ${alphabet.getLocalizedExample(context)}'
                : '${alphabet.letter} ${alphabet.getLocalizedExample(context)}';
            _ttsHelper?.speak(textToSpeak);
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
