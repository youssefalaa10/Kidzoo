class ShapeStates{}

final class ShapeInitialState extends ShapeStates{}
class ShapeLoadingState extends ShapeStates {
  @override
  List<Object> get props => [];
}
class ShapeMatched extends ShapeStates{}

class ShapeGameOver extends ShapeStates{}

class ShapeLoadedState extends ShapeStates {
  final String shape;
  final String temp;
   ShapeLoadedState(this.shape, this.temp);

  @override
  List<Object> get props => [shape];
}

class ShapeErrorState extends ShapeStates {
  final String errorMessage;
   ShapeErrorState(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}

