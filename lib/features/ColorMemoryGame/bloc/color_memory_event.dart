import 'package:equatable/equatable.dart';

import '../data/models/color_memory_constants.dart';

/// Base class for all Color Memory Game events
abstract class ColorMemoryEvent extends Equatable {
  const ColorMemoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start a new game
class StartGameEvent extends ColorMemoryEvent {
  const StartGameEvent({
    required this.mode,
    required this.level,
  });

  final ColorMemoryGameMode mode;
  final int level;

  @override
  List<Object?> get props => [mode, level];
}

/// Event to show the sequence to the player
class ShowSequenceEvent extends ColorMemoryEvent {
  const ShowSequenceEvent();
}

/// Event to highlight next color in sequence
class HighlightNextColorEvent extends ColorMemoryEvent {
  const HighlightNextColorEvent();
}

/// Event when sequence display is complete
class SequenceDisplayCompleteEvent extends ColorMemoryEvent {
  const SequenceDisplayCompleteEvent();
}

/// Event when player taps a color
class PlayerTapColorEvent extends ColorMemoryEvent {
  const PlayerTapColorEvent(this.colorIndex);

  final int colorIndex;

  @override
  List<Object?> get props => [colorIndex];
}

/// Event to check if player's sequence is correct
class CheckPlayerSequenceEvent extends ColorMemoryEvent {
  const CheckPlayerSequenceEvent();
}

/// Event when round is successful
class RoundSuccessEvent extends ColorMemoryEvent {
  const RoundSuccessEvent();
}

/// Event when player makes a mistake
class PlayerMistakeEvent extends ColorMemoryEvent {
  const PlayerMistakeEvent(this.correctColorIndex, this.wrongColorIndex);

  final int correctColorIndex;
  final int wrongColorIndex;

  @override
  List<Object?> get props => [correctColorIndex, wrongColorIndex];
}

/// Event to advance to next round
class NextRoundEvent extends ColorMemoryEvent {
  const NextRoundEvent();
}

/// Event to restart the game
class RestartGameEvent extends ColorMemoryEvent {
  const RestartGameEvent();
}

/// Event to update game settings
class UpdateSettingsEvent extends ColorMemoryEvent {
  const UpdateSettingsEvent({
    this.soundEnabled,
    this.hapticsEnabled,
    this.colorBlindMode,
    this.selectedPaletteIndex,
  });

  final bool? soundEnabled;
  final bool? hapticsEnabled;
  final bool? colorBlindMode;
  final int? selectedPaletteIndex;

  @override
  List<Object?> get props => [
        soundEnabled,
        hapticsEnabled,
        colorBlindMode,
        selectedPaletteIndex,
      ];
}

/// Event for timer tick in timed mode
class TimerTickEvent extends ColorMemoryEvent {
  const TimerTickEvent(this.remainingTime);

  final double remainingTime;

  @override
  List<Object?> get props => [remainingTime];
}

/// Event when time runs out in timed mode
class TimeExpiredEvent extends ColorMemoryEvent {
  const TimeExpiredEvent();
}

/// Event to reset highlighted color
class ResetHighlightEvent extends ColorMemoryEvent {
  const ResetHighlightEvent();
}

/// Event to return to main menu
class ReturnToMenuEvent extends ColorMemoryEvent {
  const ReturnToMenuEvent();
}

/// Event to update best score
class UpdateBestScoreEvent extends ColorMemoryEvent {
  const UpdateBestScoreEvent(this.score);

  final int score;

  @override
  List<Object?> get props => [score];
}
