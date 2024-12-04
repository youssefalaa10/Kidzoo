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
  final String number;
  final String example;
  const NumberLoadedState(this.number, this.example);

  @override
  List<Object> get props => [number, example];
}

class NumberErrorState extends NumberState {
  final String errorMessage;
  const NumberErrorState(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
