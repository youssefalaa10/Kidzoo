import 'package:bloc/bloc.dart';

import '../../../models/alphabet_model.dart';
import 'alphabet_event.dart';
import 'alphabet_state.dart';

class AlphabetBloc extends Bloc<AlphabetEvent, AlphabetState> {
  AlphabetBloc() : super(AlphabetInitialState()) {
  on<SelectAlphabetEvent>((event, emit) async {
  emit(AlphabetLoadingState());

  try {
    final Map<String, AlphabetModel> alphabetModels = {
      'A': AlphabetModel(letter: 'A', imagePath: 'assets/images/Axe.png', example: 'Axe'),
      'B': AlphabetModel(letter: 'B', imagePath: 'assets/images/Ball.png', example: 'Ball'),
      'C': AlphabetModel(letter: 'C', imagePath: 'assets/images/Cat.png', example: 'Cat'),
      'D': AlphabetModel(letter: 'D', imagePath: 'assets/images/Dog.png', example: 'Dog'),
      'E': AlphabetModel(letter: 'E', imagePath: 'assets/images/Elephant.png', example: 'Elephant'),
      'F': AlphabetModel(letter: 'F', imagePath: 'assets/images/Fish.png', example: 'Fish'),
      'G': AlphabetModel(letter: 'G', imagePath: 'assets/images/Giraffe.png', example: 'Giraffe'),
      'H': AlphabetModel(letter: 'H', imagePath: 'assets/images/Horse.png', example: 'Horse'),
      'I': AlphabetModel(letter: 'I', imagePath: 'assets/images/Insect.png', example: 'Insect'),
      'J': AlphabetModel(letter: 'J', imagePath: 'assets/images/Jellyfish.png', example: 'Jellyfish'),
      'K': AlphabetModel(letter: 'K', imagePath: 'assets/images/Kangaroo.png', example: 'Kangaroo'),
      'L': AlphabetModel(letter: 'L', imagePath: 'assets/images/Lion.png', example: 'Lion'),
      'M': AlphabetModel(letter: 'M', imagePath: 'assets/images/Monkey.png', example: 'Monkey'),
      'N': AlphabetModel(letter: 'N', imagePath: 'assets/images/Nest.png', example: 'Nest'),
      'O': AlphabetModel(letter: 'O', imagePath: 'assets/images/Owl.png', example: 'Owl'),
      'P': AlphabetModel(letter: 'P', imagePath: 'assets/images/Penguin.png', example: 'Penguin'),
      'Q': AlphabetModel(letter: 'Q', imagePath: 'assets/images/Queen.png', example: 'Queen'),
      'R': AlphabetModel(letter: 'R', imagePath: 'assets/images/Rabbit.png', example: 'Rabbit'),
      'S': AlphabetModel(letter: 'S', imagePath: 'assets/images/Snake.png', example: 'Snake'),
      'T': AlphabetModel(letter: 'T', imagePath: 'assets/images/Tree.png', example: 'Tree'),
      'U': AlphabetModel(letter: 'U', imagePath: 'assets/images/Umbrella.png', example: 'Umbrella'),
      'V': AlphabetModel(letter: 'V', imagePath: 'assets/images/Violin.png', example: 'Violin'),
      'W': AlphabetModel(letter: 'W', imagePath: 'assets/images/Whale.png', example: 'Whale'),
      'X': AlphabetModel(letter: 'X', imagePath: 'assets/images/X-ray.png', example: 'X-ray'),
      'Y': AlphabetModel(letter: 'Y', imagePath: 'assets/images/Yellow.png', example: 'Yellow'),
      'Z': AlphabetModel(letter: 'Z', imagePath: 'assets/images/Zebra.png', example: 'Zebra'),
      // Add more alphabet models
    };

    if (alphabetModels.containsKey(event.alphabet)) {
      final selectedModel = alphabetModels[event.alphabet]!;
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
