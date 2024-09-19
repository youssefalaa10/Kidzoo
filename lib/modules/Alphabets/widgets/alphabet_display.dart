import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/alphabet_bloc.dart';
import '../bloc/alphabet_state.dart';


class AlphabetDisplay extends StatelessWidget {
  const AlphabetDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlphabetBloc, AlphabetState>(
      builder: (context, state) {
        if (state is AlphabetInitialState) {
          return const Center(child: Text('Select a letter'));
        } else if (state is AlphabetLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AlphabetLoadedState) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.alphabet,
                style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
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
