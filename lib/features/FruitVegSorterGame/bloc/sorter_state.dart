import 'package:equatable/equatable.dart';

import '../data/sorter_models.dart';

/// What the round is doing right now.
///
/// This replaces the previous five sibling state classes, each of which
/// repeated `roundData`/`currentRound`/`totalRounds`. The UI had to unpack them
/// through a chain of `is` checks and could silently fall through to defaults;
/// one state plus a phase keeps every field reachable in every phase.
enum SorterPhase { loading, playing, correct, wrong, complete }

class SorterGameState extends Equatable {
  const SorterGameState({
    required this.phase,
    this.roundData,
    this.currentRound = 1,
    this.totalRounds = 10,
    this.score = 0,
    this.incorrectAttempts = 0,
    this.showHint = false,
    this.selectedFoodId,
    this.wrongFoodId,
    this.wrongBasket,
  });

  const SorterGameState.loading() : this(phase: SorterPhase.loading);

  final SorterPhase phase;
  final SorterGameRoundData? roundData;
  final int currentRound;
  final int totalRounds;
  final int score;

  /// Wrong tries in the current round; drives the hint.
  final int incorrectAttempts;
  final bool showHint;

  /// Food picked by tapping, waiting for a basket. Null while dragging.
  final String? selectedFoodId;

  /// Food that was just answered wrongly, so only that card shakes.
  final String? wrongFoodId;

  /// Basket that just refused an item, so only that basket flashes red.
  final FoodType? wrongBasket;

  bool get isInteractive => phase == SorterPhase.playing;

  SorterGameState copyWith({
    SorterPhase? phase,
    SorterGameRoundData? roundData,
    int? currentRound,
    int? totalRounds,
    int? score,
    int? incorrectAttempts,
    bool? showHint,
    String? selectedFoodId,
    String? wrongFoodId,
    FoodType? wrongBasket,
    bool clearSelection = false,
    bool clearWrong = false,
  }) {
    return SorterGameState(
      phase: phase ?? this.phase,
      roundData: roundData ?? this.roundData,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      score: score ?? this.score,
      incorrectAttempts: incorrectAttempts ?? this.incorrectAttempts,
      showHint: showHint ?? this.showHint,
      selectedFoodId:
          clearSelection ? null : (selectedFoodId ?? this.selectedFoodId),
      wrongFoodId: clearWrong ? null : (wrongFoodId ?? this.wrongFoodId),
      wrongBasket: clearWrong ? null : (wrongBasket ?? this.wrongBasket),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        roundData,
        currentRound,
        totalRounds,
        score,
        incorrectAttempts,
        showHint,
        selectedFoodId,
        wrongFoodId,
        wrongBasket,
      ];
}
