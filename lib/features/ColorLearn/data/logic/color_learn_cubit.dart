import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/color_model.dart';
import 'color_learn_state.dart';

class ColorLearnCubit extends Cubit<ColorLearnState> {
  ColorLearnCubit() : super(ColorLearnState.initial());

  void initializeGame(int level, String languageCode) {
    final colors = ColorModel.getColorsForLevel(level);
    colors.shuffle();

    emit(state.copyWith(
      level: level,
      availableColors: colors,
      remainingColors: <ColorModel>[...colors],
      matchedColors: <ColorModel>[],
      languageCode: languageCode,
      score: 0,
      isGameComplete: false,
    ));
  }

  void matchColor(ColorModel color) {
    if (state.matchedColors.contains(color)) {
      return; // Already matched
    }

    final newMatchedColors = <ColorModel>[...state.matchedColors, color];
    final newRemainingColors = <ColorModel>[...state.remainingColors]
      ..remove(color);

    final isComplete = newRemainingColors.isEmpty;

    emit(state.copyWith(
      matchedColors: newMatchedColors,
      remainingColors: newRemainingColors,
      score: state.score + 10,
      isGameComplete: isComplete,
      lastMatchedColor: color,
    ));
  }

  void resetMatchFeedback() {
    emit(state.copyWith(
      showWrongFeedback: false,
    ));
  }

  void showWrongFeedback() {
    emit(state.copyWith(showWrongFeedback: true));
    Future.delayed(const Duration(milliseconds: 500), () {
      emit(state.copyWith(showWrongFeedback: false));
    });
  }

  void resetGame() {
    emit(ColorLearnState.initial());
  }
}
