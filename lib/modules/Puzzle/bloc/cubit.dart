import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/Puzzle/bloc/state.dart';

class PuzzleCubit extends Cubit<PuzzleState> {
  PuzzleCubit() : super(PuzzleInitial());

  void loadPuzzle(Widget puzzleWidget) {
    emit(PuzzleLoaded(puzzleWidget: puzzleWidget));
  }

  void showError() {
    emit(PuzzleError());
  }
}
