import 'package:bloc/bloc.dart';

import 'alphabet_event.dart';
import 'alphabet_state.dart';

class AlphabetBloc extends Bloc<AlphabetEvent, AlphabetState> {
  AlphabetBloc() : super(AlphabetInitialState()) {
    on<SelectAlphabetEvent>((event, emit) async {
      emit(AlphabetLoadingState());

      try {
        // Example mapping of alphabets to their examples
        final Map<String, String> alphabetExamples = {
          'A': 'Axe',
          'B': 'Ball',
          'C': 'Cat',
          'D': 'Dog',
          'E': 'Egg',
          'F': 'Fish',
          'G': 'Goat',
          'H': 'Horse',
          'I': 'Ice',
          'J': 'Jump',
          'K': 'Kite',
          'L': 'Lion',
          'M': 'Monkey',
          'N': 'Nest',
          'O': 'Owl',
          
          // Add all other letters with their respective examples
        };

        if (alphabetExamples.containsKey(event.alphabet)) {
          emit(AlphabetLoadedState(event.alphabet, alphabetExamples[event.alphabet]!));
        } else {
          emit(const AlphabetErrorState('Example not found for the selected alphabet.'));
        }
      } catch (e) {
        emit(const AlphabetErrorState('An error occurred'));
      }
    });
  }
}
