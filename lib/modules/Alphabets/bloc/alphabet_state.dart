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
  final String alphabet;
  final String example;
  const AlphabetLoadedState(this.alphabet, this.example);

  @override
  List<Object> get props => [alphabet, example];
}

class AlphabetErrorState extends AlphabetState {
  final String errorMessage;
  const AlphabetErrorState(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
