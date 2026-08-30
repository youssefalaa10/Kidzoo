class ShapeStates {}

final class ShapeInitialState extends ShapeStates {}

class ShapeLoadingState extends ShapeStates {
  List<Object> get props => [];
}

class ShapeMatched extends ShapeStates {}

class ShapeGameOver extends ShapeStates {}

class ShapeLoadedState extends ShapeStates {
  ShapeLoadedState(this.shape, this.temp);
  final String shape;
  final String temp;

  List<Object> get props => [shape];
}

class ShapeErrorState extends ShapeStates {
  ShapeErrorState(this.errorMessage);
  final String errorMessage;

  List<Object> get props => [errorMessage];
}
