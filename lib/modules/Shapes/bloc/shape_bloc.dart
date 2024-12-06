import 'package:bloc/bloc.dart';
import 'package:kidzoo/models/shape_model.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_event.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_state.dart';



class ShapeBloc extends Bloc<ShapeEvent, ShapeState> {
  ShapeBloc() : super(ShapeInitialState()) {
    on<SelectShapeEvent>((event, emit) async {
      emit(ShapeLoadingState());

      try {
        // Convert the list of shape models to a map of shape -> model
        final Map<String, ShapeModel> shapeMap = {
          for (var model in ShapeModel.shapes)
            model.shape: model
        };

        if (shapeMap.containsKey(event.shape)) {
          final selectedModel = shapeMap[event.shape]!;
          emit(ShapeLoadedState(selectedModel.shape, selectedModel.example));
        } else {
          emit(const ShapeErrorState('Example not found for the selected shape.'));
        }
      } catch (e) {
        emit(const ShapeErrorState('An error occurred'));
      }
    });
  }
}
