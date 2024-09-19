import 'package:bloc/bloc.dart';

import '../../../models/alphabet_model.dart';
import 'alphabet_event.dart';
import 'alphabet_state.dart';


class AlphabetBloc extends Bloc<AlphabetEvent, AlphabetState> {
  AlphabetBloc() : super(AlphabetInitialState()) {
    on<SelectAlphabetEvent>((event, emit) async {
      emit(AlphabetLoadingState());

      try {
        // Convert the list of alphabet models to a map of letter -> model
        final Map<String, AlphabetModel> alphabetMap = {
          for (var model in AlphabetModel.alphabets)
            model.letter: model
        };

        if (alphabetMap.containsKey(event.alphabet)) {
          final selectedModel = alphabetMap[event.alphabet]!;
          emit(AlphabetLoadedState(selectedModel.letter, selectedModel.example));
        } else {
          emit(const AlphabetErrorState('Example not found for the selected alphabet.'));
        }
      } catch (e) {
        emit(const AlphabetErrorState('An error occurred'));
      }
    });
  }
}
