import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/profile_dao.dart';
import 'package:kidzo/core/database/models/game_tier_record.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_load_status.dart';
import 'package:kidzo/features/Difficulty/logic/difficulty_select_state.dart';

/// Reads one game's tier history so the picker knows what to open.
class DifficultySelectCubit extends Cubit<DifficultySelectState> {
  DifficultySelectCubit({
    required this.gameScoresDao,
    required this.profileDao,
    required this.gameKey,
  }) : super(const DifficultySelectState.loading());

  final GameScoresDao gameScoresDao;
  final ProfileDao profileDao;
  final String gameKey;

  /// Called on create and again every time the child comes back from a run,
  /// so stars appear on the card they were just earned on.
  Future<void> loadProgress() async {
    try {
      final List<Profile> profiles = await profileDao.getAllProfiles();
      if (profiles.isEmpty) {
        emit(const DifficultySelectState(
          status: DifficultyLoadStatus.ready,
          completed: <KidDifficulty>{},
          bestStars: <KidDifficulty, int>{},
          bestScores: <KidDifficulty, int>{},
        ));
        return;
      }
      final List<GameTierRecord> records = await gameScoresDao.getTierRecords(
        profileId: profiles.first.id,
        gameKey: gameKey,
      );
      emit(_stateFrom(records));
    } catch (_) {
      // A read failure must not strand the child on a spinner: fall back to
      // Easy-only, which is exactly what a brand new profile sees.
      emit(const DifficultySelectState(
        status: DifficultyLoadStatus.failed,
        completed: <KidDifficulty>{},
        bestStars: <KidDifficulty, int>{},
        bestScores: <KidDifficulty, int>{},
      ));
    }
  }

  DifficultySelectState _stateFrom(List<GameTierRecord> records) {
    final Set<KidDifficulty> completed = <KidDifficulty>{};
    final Map<KidDifficulty, int> stars = <KidDifficulty, int>{};
    final Map<KidDifficulty, int> scores = <KidDifficulty, int>{};
    for (final GameTierRecord record in records) {
      final KidDifficulty tier = KidDifficulty.fromLevel(record.level);
      if (record.plays > 0) {
        completed.add(tier);
      }
      // fromLevel clamps, so a stray level 4 row folds onto hard; keep the
      // better of the two rather than letting order decide.
      stars[tier] = record.bestStars > (stars[tier] ?? 0)
          ? record.bestStars
          : (stars[tier] ?? 0);
      scores[tier] = record.bestScore > (scores[tier] ?? 0)
          ? record.bestScore
          : (scores[tier] ?? 0);
    }
    return DifficultySelectState(
      status: DifficultyLoadStatus.ready,
      completed: completed,
      bestStars: stars,
      bestScores: scores,
    );
  }
}
