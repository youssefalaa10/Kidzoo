import 'package:equatable/equatable.dart';
import '../data/sorter_models.dart';

abstract class SorterGameState extends Equatable {
  const SorterGameState();

  @override
  List<Object?> get props => [];
}

class SorterGameLoading extends SorterGameState {}

class SorterGamePlaying extends SorterGameState {

  const SorterGamePlaying({
    required this.roundData,
    required this.currentRound,
    required this.totalRounds,
    this.incorrectAttempts = 0,
    this.showHint = false,
  });
  final SorterGameRoundData roundData;
  final int currentRound;
  final int totalRounds;
  final int incorrectAttempts;
  final bool showHint;

  @override
  List<Object?> get props => [roundData, currentRound, totalRounds, incorrectAttempts, showHint];

  SorterGamePlaying copyWith({
    SorterGameRoundData? roundData,
    int? currentRound,
    int? totalRounds,
    int? incorrectAttempts,
    bool? showHint,
  }) {
    return SorterGamePlaying(
      roundData: roundData ?? this.roundData,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      showHint: showHint ?? this.showHint,
    );
  }
}

class SorterGameSuccess extends SorterGameState {

  const SorterGameSuccess({
    required this.roundData,
    required this.currentRound,
    required this.totalRounds,
    required this.droppedFood,
  });
  final SorterGameRoundData roundData;
  final int currentRound;
  final int totalRounds;
  final FoodItem droppedFood;

  @override
  List<Object?> get props => [roundData, currentRound, totalRounds, droppedFood];
}

class SorterGameWrong extends SorterGameState {

  const SorterGameWrong({
    required this.roundData,
    required this.currentRound,
    required this.totalRounds,
  });
  final SorterGameRoundData roundData;
  final int currentRound;
  final int totalRounds;

  @override
  List<Object?> get props => [roundData, currentRound, totalRounds];
}

class SorterGameComplete extends SorterGameState {}
