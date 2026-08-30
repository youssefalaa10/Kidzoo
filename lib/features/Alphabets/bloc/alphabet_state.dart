import 'package:equatable/equatable.dart';

abstract class AlphabetState extends Equatable {
  const AlphabetState();
}

class AlphabetInitialState extends AlphabetState {
  @override
  List<Object> get props => [];
}

class AlphabetLoadingState extends AlphabetState {
  @override
  List<Object> get props => [];
}

class AlphabetLoadedState extends AlphabetState {
  const AlphabetLoadedState(this.alphabet, this.example, this.exampleKey);
  final String alphabet;
  final String example;
  final String exampleKey;

  @override
  List<Object> get props => [alphabet, example, exampleKey];
}

class AlphabetErrorState extends AlphabetState {
  const AlphabetErrorState(this.errorMessage);
  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}
