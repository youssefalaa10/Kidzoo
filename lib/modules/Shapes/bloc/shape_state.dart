import 'package:equatable/equatable.dart';

abstract class ShapeState extends Equatable {
  const ShapeState();
}

class ShapeInitialState extends ShapeState {
  @override
  List<Object> get props => [];
}

class ShapeLoadingState extends ShapeState {
  @override
  List<Object> get props => [];
}

class ShapeLoadedState extends ShapeState {
  final String shape;
  final String example;
  const ShapeLoadedState(this.shape, this.example);

  @override
  List<Object> get props => [shape, example];
}

class ShapeErrorState extends ShapeState {
  final String errorMessage;
  const ShapeErrorState(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
