import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_states.dart';
import '../../../models/shape_model.dart';

class ShapeCubit extends Cubit<ShapeStates> {
  List<ShapeModel> shapesList = ShapeModel.shapes;
  List<ShapeModel> shapes = List.from(ShapeModel.shapes);
  late List<String> temps;
  int score = 0;

  final Set<String> matchedShapes = {};

  ShapeCubit() : super(ShapeInitialState()) {
    init();
  }

  void init() {
    temps = shapesList.map((shape) => shape.temp).toList();
    temps.shuffle(Random());
  }

  @override
  Future<void> close() {
    print("Shape Cubit closed");
    return super.close();
  }

  void gameOver() {
    score = 0;
    matchedShapes.clear();
    shapes = List.from(shapesList);
    
    init();
    emit(ShapeGameOver());
  }

  String result() {
    if (score == 80) {
      return "Excellent";
    } else if (score >= 50) {
      return "Good";
    } else {
      return "Try Again to get a better score";
    }
  }

  void addMatch(String shapeTemp) {
    matchedShapes.add(shapeTemp);
    emit(ShapeMatched());
  }
}
