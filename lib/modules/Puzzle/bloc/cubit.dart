import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/models/puzzle_model.dart';
import 'package:kidzoo/modules/Puzzle/bloc/state.dart';
import 'package:kidzoo/shared/style/image_manager.dart';

class PuzzleCubit extends Cubit<PuzzleState> {
  PuzzleCubit() : super(PuzzleInitial());

  int score = 0;
  bool gameOver = false;
  List<PuzzleModel> puzzle = [];
  List<PuzzleModel> choosePiece = [];
  void selectImage(int index) {
    if (index == 0) {
      puzzle = [
      PuzzleModel(
        image: ImageManager.gazelle1,
        index: 0,
      ),
      PuzzleModel(
        image: ImageManager.gazelle2,
        index: 1,
      ),
      PuzzleModel(
        image: ImageManager.gazelle3,
        index: 2,
      ),
      PuzzleModel(
        image: ImageManager.gazelle4,
        index: 3,
      ),
    ];
    } else if (index == 1) {
      puzzle = [
      PuzzleModel(
        image: ImageManager.ghost1,
        index: 0,
      ),
      PuzzleModel(
        image: ImageManager.ghost2,
        index: 1,
      ),
      PuzzleModel(
        image: ImageManager.ghost3,
        index: 2,
      ),
      PuzzleModel(
        image: ImageManager.ghost4,
        index: 3,
      ),
    ];  
    }
    emit(PuzzleImageSelected());
  }
  
  void initGame() {
    gameOver = false;
    score = 0;
    choosePiece = List<PuzzleModel>.from(puzzle);
    //puzzle.shuffle();
    choosePiece.shuffle();
  }

  void loadPuzzle(Widget puzzleWidget) {
    emit(PuzzleLoaded(puzzleWidget: puzzleWidget));
  }

  void updateScore(int points) {
    score += points;
    emit(PuzzleScoreUpdated()); // Make sure to create this state
  }

  void showError() {
    emit(PuzzleError());
  }
}
