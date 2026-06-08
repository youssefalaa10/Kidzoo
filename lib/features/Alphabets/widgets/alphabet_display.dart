import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kidzo/core/localization/app_localizations.dart';

import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_state.dart';
import '../data/model/alphabet_model.dart';

class AlphabetDisplay extends StatelessWidget {
  const AlphabetDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AlphabetBloc, AlphabetState>(
      builder: (context, state) {
        if (state is AlphabetInitialState) {
          return Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              l10n.selectALetter,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
          );
        } else if (state is AlphabetLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AlphabetLoadedState) {
          final alphabetModel = AlphabetModel.alphabets.firstWhere(
            (model) => model.letter == state.alphabet,
            orElse: () => AlphabetModel(
                letter: '', imagePath: '', example: '', exampleKey: ''),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (alphabetModel.imagePath.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Image.asset(
                    alphabetModel.imagePath,
                    width: 200,
                    height: 200,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                '${state.alphabet} = ${alphabetModel.getLocalizedExample(context)}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
            ],
          );
        } else if (state is AlphabetErrorState) {
          return Center(child: Text(state.errorMessage));
        }
        return Container();
      },
    );
  }
}
