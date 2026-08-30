import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

import 'models/achievement.dart';
import 'models/game_category_progress.dart';
import 'profile_analytics_state.dart';
import 'utils/game_category_mapper.dart';

class ProfileAnalyticsCubit extends Cubit<ProfileAnalyticsState> {
  ProfileAnalyticsCubit(this.gameScoresDao) : super(ProfileAnalyticsInitial());

  final GameScoresDao gameScoresDao;

  static const int _starThreshold = 80;
  static const int _levelUpScore = 200;

  Future<void> load(int profileId, AppLocalizations l10n) async {
    emit(ProfileAnalyticsLoading());
    try {
      final scores = await gameScoresDao.getScoresForProfile(profileId);

      final totalScore = scores.fold<int>(0, (sum, s) => sum + s.score);
      final gamesPlayed = scores.length;
      final bestScore =
          scores.isEmpty ? 0 : scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      final stars = scores.where((s) => s.score >= _starThreshold).length;
      final currentStreak = _computeStreak(scores.map((s) => s.playedAt).toList());

      final categories = _buildCategories(scores, l10n);
      final achievements = _buildAchievements(
        gamesPlayed: gamesPlayed,
        totalScore: totalScore,
        currentStreak: currentStreak,
        categories: categories,
        l10n: l10n,
      );

      emit(ProfileAnalyticsLoaded(
        totalScore: totalScore,
        stars: stars,
        gamesPlayed: gamesPlayed,
        currentStreak: currentStreak,
        bestScore: bestScore,
        categories: categories,
        achievements: achievements,
      ));
    } catch (e) {
      emit(ProfileAnalyticsError(e.toString()));
    }
  }

  int _computeStreak(List<DateTime> playedAt) {
    if (playedAt.isEmpty) return 0;
    final days = playedAt.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<GameCategoryProgress> _buildCategories(List<GameScore> scores, AppLocalizations l10n) {
    return kGameCategories.map((def) {
      final categoryScores =
          scores.where((s) => categoryIdForGameKey(s.gameKey) == def.id).toList();

      final score = categoryScores.fold<int>(0, (sum, s) => sum + s.score);
      final gamesPlayed = categoryScores.length;
      final bestScore = categoryScores.isEmpty
          ? 0
          : categoryScores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
      final progress = (score / _levelUpScore).clamp(0.0, 1.0);

      return GameCategoryProgress(
        id: def.id,
        title: categoryTitleFor(l10n, def.id),
        icon: def.icon,
        color: def.color,
        score: score,
        bestScore: bestScore,
        gamesPlayed: gamesPlayed,
        progress: progress,
        encouragement: _encouragementFor(l10n, def.id, gamesPlayed, progress),
      );
    }).toList();
  }

  String _encouragementFor(
      AppLocalizations l10n, String categoryId, int gamesPlayed, double progress) {
    if (gamesPlayed == 0) return l10n.encouragementNewbie;
    if (progress >= 1.0) {
      switch (categoryId) {
        case 'memory':
          return l10n.encouragementMemoryMastered;
        case 'math':
          return l10n.encouragementMathMastered;
        case 'puzzle':
          return l10n.encouragementPuzzleMastered;
        case 'sports':
          return l10n.encouragementSportsMastered;
        default:
          return l10n.encouragementLanguageMastered;
      }
    }
    if (progress >= 0.5) return l10n.encouragementImproving;
    return l10n.encouragementKeepPracticing;
  }

  List<Achievement> _buildAchievements({
    required int gamesPlayed,
    required int totalScore,
    required int currentStreak,
    required List<GameCategoryProgress> categories,
    required AppLocalizations l10n,
  }) {
    GameCategoryProgress categoryOf(String id) => categories.firstWhere((c) => c.id == id);

    return [
      Achievement(
        id: 'first_win',
        title: l10n.achievementFirstWinTitle,
        description: l10n.achievementFirstWinDesc,
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFC107),
        isUnlocked: gamesPlayed >= 1,
      ),
      Achievement(
        id: 'memory_master',
        title: l10n.achievementMemoryMasterTitle,
        description: l10n.achievementMemoryMasterDesc,
        icon: Icons.psychology_rounded,
        color: const Color(0xFF7C4DFF),
        isUnlocked: categoryOf('memory').gamesPlayed >= 5,
      ),
      Achievement(
        id: 'math_star',
        title: l10n.achievementMathStarTitle,
        description: l10n.achievementMathStarDesc,
        icon: Icons.calculate_rounded,
        color: const Color(0xFFFF9F43),
        isUnlocked: categoryOf('math').bestScore >= _starThreshold,
      ),
      Achievement(
        id: 'five_day_streak',
        title: l10n.achievementFiveDayStreakTitle,
        description: l10n.achievementFiveDayStreakDesc,
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF5252),
        isUnlocked: currentStreak >= 5,
      ),
      Achievement(
        id: 'puzzle_hero',
        title: l10n.achievementPuzzleHeroTitle,
        description: l10n.achievementPuzzleHeroDesc,
        icon: Icons.extension_rounded,
        color: const Color(0xFF26C6DA),
        isUnlocked: categoryOf('puzzle').gamesPlayed >= 5,
      ),
      Achievement(
        id: 'super_learner',
        title: l10n.achievementSuperLearnerTitle,
        description: l10n.achievementSuperLearnerDesc,
        icon: Icons.school_rounded,
        color: const Color(0xFF66BB6A),
        isUnlocked: totalScore >= 500,
      ),
    ];
  }
}
