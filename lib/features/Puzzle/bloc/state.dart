import 'package:flutter/material.dart';

abstract class PuzzleState {
  const PuzzleState();

  List<Object> get props => [];
}

class PuzzleInitial extends PuzzleState {}

class PuzzleLoaded extends PuzzleState {
  const PuzzleLoaded({required this.puzzleWidget});
  final Widget puzzleWidget;

  @override
  List<Object> get props => [puzzleWidget];
}

class PuzzleScoreUpdated extends PuzzleState {}

class PuzzleImageSelected extends PuzzleState {}

class PuzzleError extends PuzzleState {}
