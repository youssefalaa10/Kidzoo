import 'package:flutter/material.dart';

abstract class PuzzleState {
  const PuzzleState();

  @override
  List<Object> get props => [];
}

class PuzzleInitial extends PuzzleState {}

class PuzzleLoaded extends PuzzleState {
  final Widget puzzleWidget;

  const PuzzleLoaded({required this.puzzleWidget});

  @override
  List<Object> get props => [puzzleWidget];
}

class PuzzleScoreUpdated extends PuzzleState {}
class PuzzleImageSelected extends PuzzleState {}

class PuzzleError extends PuzzleState {}
