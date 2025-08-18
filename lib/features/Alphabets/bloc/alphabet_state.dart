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
  const AlphabetLoadedState(this.alphabet, this.example);
  final String alphabet;
  final String example;

  @override
  List<Object> get props => [alphabet, example];
}

class AlphabetErrorState extends AlphabetState {
  const AlphabetErrorState(this.errorMessage);
  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}
