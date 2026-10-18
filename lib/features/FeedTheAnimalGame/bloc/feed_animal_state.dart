import 'package:equatable/equatable.dart';

import '../data/feed_animal_models.dart';

/// What the round is doing right now.
///
/// One state object with a phase replaces the previous five sibling classes,
/// each of which re-declared the same five fields and forced the UI into a
/// chain of `is` checks with silent fallbacks.
enum FeedPhase { loading, playing, correct, wrong, complete }

class FeedAnimalState extends Equatable {
  const FeedAnimalState({
    required this.phase,
    this.roundData,
    this.currentRound = 1,
    this.totalRounds = 10,
    this.score = 0,
    this.showHint = false,
    this.selectedFoodId,
    this.wrongFoodId,
    this.eatenFood,
  });

  const FeedAnimalState.loading() : this(phase: FeedPhase.loading);

  final FeedPhase phase;
  final GameRoundData? roundData;
  final int currentRound;
  final int totalRounds;
  final int score;
  final bool showHint;

  /// Food picked by tapping and waiting to be given to the animal.
  final String? selectedFoodId;

  /// Food that was just refused, so only that card shakes.
  final String? wrongFoodId;

  /// Food currently flying into the animal's mouth.
  final FeedItem? eatenFood;

  bool get isInteractive => phase == FeedPhase.playing;

  FeedAnimalState copyWith({
    FeedPhase? phase,
    GameRoundData? roundData,
    int? currentRound,
    int? totalRounds,
    int? score,
    bool? showHint,
    String? selectedFoodId,
    String? wrongFoodId,
    FeedItem? eatenFood,
    bool clearSelection = false,
    bool clearWrong = false,
    bool clearEaten = false,
  }) {
    return FeedAnimalState(
      phase: phase ?? this.phase,
      roundData: roundData ?? this.roundData,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      score: score ?? this.score,
      showHint: showHint ?? this.showHint,
      selectedFoodId:
          clearSelection ? null : (selectedFoodId ?? this.selectedFoodId),
      wrongFoodId: clearWrong ? null : (wrongFoodId ?? this.wrongFoodId),
      eatenFood: clearEaten ? null : (eatenFood ?? this.eatenFood),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        roundData,
        currentRound,
        totalRounds,
        score,
        showHint,
        selectedFoodId,
        wrongFoodId,
        eatenFood,
      ];
}
