import 'package:equatable/equatable.dart';

abstract class NumberState extends Equatable {
  const NumberState();
}

class NumberInitialState extends NumberState {
  @override
  List<Object> get props => [];
}

class NumberLoadingState extends NumberState {
  @override
  List<Object> get props => [];
}

class NumberLoadedState extends NumberState {
  const NumberLoadedState(this.number, this.example);
  final String number;
  final String example;

  @override
  List<Object> get props => [number, example];
}

class NumberErrorState extends NumberState {
  const NumberErrorState(this.errorMessage);
  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}
