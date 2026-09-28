import 'package:equatable/equatable.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_load_status.dart';

/// What the picker knows about one game's three tiers.
class DifficultySelectState extends Equatable {
  const DifficultySelectState({
    required this.status,
    required this.completed,
    required this.bestStars,
    required this.bestScores,
  });

  const DifficultySelectState.loading()
      : status = DifficultyLoadStatus.loading,
        completed = const <KidDifficulty>{},
        bestStars = const <KidDifficulty, int>{},
        bestScores = const <KidDifficulty, int>{};

  final DifficultyLoadStatus status;

  /// Tiers this child has finished at least once.
  final Set<KidDifficulty> completed;
  final Map<KidDifficulty, int> bestStars;
  final Map<KidDifficulty, int> bestScores;

  /// Easy is always open; every other tier needs the one below it finished.
  ///
  /// Finishing is enough — stars are the thing to come back for, not the toll
  /// to get through. A child who scrapes a single star still moves on.
  bool isUnlocked(KidDifficulty difficulty) {
    final KidDifficulty? previous = difficulty.previous;
    if (previous == null) {
      return true;
    }
    return completed.contains(previous);
  }

  int starsFor(KidDifficulty difficulty) => bestStars[difficulty] ?? 0;

  int? bestScoreFor(KidDifficulty difficulty) => bestScores[difficulty];

  bool hasPlayed(KidDifficulty difficulty) => completed.contains(difficulty);

  @override
  List<Object?> get props =>
      <Object?>[status, completed, bestStars, bestScores];
}
