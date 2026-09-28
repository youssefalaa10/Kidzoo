import 'package:kidzo/core/scoring/star_rating.dart';
import 'package:kidzo/features/ColorMemoryGame/data/models/color_memory_constants.dart';

/// Stars for a finished colour-memory level, rated on time.
///
/// `GamePhase.levelComplete` is reachable only by a clean run — one wrong tap
/// ends the game instead — so every completion would score the same on
/// accuracy. How long the child took is the only thing left that varies.
class ColorMemoryStarRule {
  const ColorMemoryStarRule._();

  /// Seconds a comfortable run of this level should take.
  ///
  /// Every round shows a sequence and then waits for it to be tapped back, and
  /// the sequence grows by one each round. [_secondsPerStep] covers watching a
  /// step, thinking, and tapping it, and is deliberately unhurried: this
  /// budget decides stars, never whether the child passes.
  static int parSecondsFor(int level) {
    final LevelConfig config = LevelConfig.forLevel(level);
    return totalStepsFor(config) * _secondsPerStep;
  }

  /// Total taps across the whole level: the sequence length summed per round.
  static int totalStepsFor(LevelConfig config) {
    final int rounds = config.maxRounds;
    return rounds * config.initialSequenceLength +
        (rounds * (rounds - 1)) ~/ 2;
  }

  static int rate({required int level, required int elapsedSeconds}) =>
      StarRating.fromDuration(
        seconds: elapsedSeconds,
        parSeconds: parSecondsFor(level),
      );

  static const int _secondsPerStep = 3;
}
