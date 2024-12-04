import 'package:bloc/bloc.dart';
import 'package:kidzoo/models/number_model.dart';
import 'number_event.dart';
import 'number_state.dart';


class NumberBloc extends Bloc<NumberEvent, NumberState> {
  NumberBloc() : super(NumberInitialState()) {
    on<SelectNumberEvent>((event, emit) async {
      emit(NumberLoadingState());

      try {
        // Convert the list of alphabet models to a map of letter -> model
        final Map<String, NumberModel> numberMap = {
          for (var model in NumberModel.numbers)
            model.num: model
        };

        if (numberMap.containsKey(event.number)) {
          final selectedModel = numberMap[event.number]!;
          emit(NumberLoadedState(selectedModel.num, selectedModel.example));
        } else {
          emit(const NumberErrorState('Example not found for the selected number.'));
        }
      } catch (e) {
        emit(const NumberErrorState('An error occurred'));
      }
    });
  }
}
