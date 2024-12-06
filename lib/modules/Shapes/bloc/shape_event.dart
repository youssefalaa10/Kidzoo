import 'package:equatable/equatable.dart';


abstract class ShapeEvent extends Equatable {
  const ShapeEvent();
}

class SelectShapeEvent extends ShapeEvent {
  final String shape;
  const SelectShapeEvent(this.shape);

  @override
  List<Object> get props => [shape];
}

