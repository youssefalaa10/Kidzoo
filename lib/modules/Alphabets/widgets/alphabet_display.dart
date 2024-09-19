import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/alphabet_model.dart'; 
import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_state.dart';

class AlphabetDisplay extends StatelessWidget {
  const AlphabetDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlphabetBloc, AlphabetState>(
      builder: (context, state) {
        if (state is AlphabetInitialState) {
          return const Center(child: Text('Select a letter',style: TextStyle(fontSize: 20,color: Colors.grey),));
        } else if (state is AlphabetLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AlphabetLoadedState) {
          final alphabetModel = AlphabetModel.alphabets.firstWhere(
            (model) => model.letter == state.alphabet,
            orElse: () => AlphabetModel(letter: '', imagePath: '', example: ''),
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
       
              if (alphabetModel.imagePath.isNotEmpty)
                Image.asset(
                  alphabetModel.imagePath,
                  width: 200, 
                  height: 200, 
                ),
              const SizedBox(height: 20),
              Text(
                '${state.alphabet} = ${state.example}',
                style: const TextStyle(fontSize: 24),
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
