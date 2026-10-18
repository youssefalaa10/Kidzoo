import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/badges/badge_catalog.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_service.dart';
import 'package:kidzo/core/badges/badge_stats_reader.dart';
import 'package:kidzo/core/badges/badge_stats_snapshot.dart';
import 'package:kidzo/core/catalog/game_catalog.dart';
import 'package:kidzo/core/catalog/game_descriptor.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/badge_dao.dart';
import 'package:kidzo/core/database/daos/game_scores_dao.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

import 'models/badge_view.dart';
import 'models/game_category_progress.dart';
import 'models/recent_activity_entry.dart';
import 'models/recent_activity_kind.dart';
import 'profile_analytics_state.dart';
import 'utils/game_category_mapper.dart';

/// Everything the Profile screen shows.
///
/// The headline numbers now come from [BadgeStatsReader] rather than being
/// recomputed here. That is not tidiness: the badge rules and this screen were
/// each going to define "total score", "stars" and "streak" separately, and
/// the star counts in particular disagreed — this screen counted rows scoring
/// 80 or more, while the badges would have read the real `starsEarned`. One
/// reader means the number on the pill is the number the badge was judged by.
class ProfileAnalyticsCubit extends Cubit<ProfileAnalyticsState> {
  ProfileAnalyticsCubit({
    required this.gameScoresDao,
    required this.storyDao,
    required this.badgeDao,
    required this.badgeCatalog,
    required this.badgeStatsReader,
    required this.gameCatalog,
    this.badgeService,
  }) : super(ProfileAnalyticsInitial());

  final GameScoresDao gameScoresDao;
  final StoryDao storyDao;
  final BadgeDao badgeDao;
  final BadgeCatalog badgeCatalog;
  final BadgeStatsReader badgeStatsReader;

  /// Used to resolve a `gameKey` to the activity's display name, rather than
  /// duplicating that map here where it would rot.
  final GameCatalog gameCatalog;

  /// Optional: opening the Profile is a second chance to catch a badge that a
  /// crashed session missed.
  final BadgeService? badgeService;

  /// Points that count as one full category bar.
  static const int _levelUpScore = 200;

  /// How many rows the activity feed shows.
  static const int _activityLimit = 8;

  Future<void> load(int profileId, AppLocalizations l10n) async {
    emit(ProfileAnalyticsLoading());
    try {
      await badgeService?.evaluateForProfile(profileId);
      final BadgeStatsSnapshot stats =
          await badgeStatsReader.readSnapshot(profileId);
      final List<GameScore> scores =
          await gameScoresDao.getScoresForProfile(profileId);
      final List<EarnedBadge> earned = await badgeDao.badgesFor(profileId);

      final List<GameCategoryProgress> categories =
          _buildCategories(scores, l10n);

      emit(ProfileAnalyticsLoaded(
        totalScore: stats.totalScore,
        stars: stats.totalStars,
        gamesPlayed: stats.totalPlays,
        currentStreak: stats.currentStreak,
        bestScore: stats.bestScore,
        categories: categories,
        badges: _buildBadgeViews(earned, l10n),
        recentActivity: await _buildRecentActivity(profileId, earned, l10n),
        storyNodesCompleted: stats.storyNodesCompleted,
        storyPagesFound: stats.storyPagesFound,
        adventuresCompleted: stats.adventuresCompleted,
        adventuresStarted: stats.adventuresStarted,
      ));
    } catch (e) {
      emit(ProfileAnalyticsError(e.toString()));
    }
  }

  /// Merges the catalog with what this child has actually earned.
  List<BadgeView> _buildBadgeViews(
    List<EarnedBadge> earned,
    AppLocalizations l10n,
  ) {
    final Map<String, DateTime> earnedAt = <String, DateTime>{
      for (final EarnedBadge row in earned) row.badgeId: row.earnedAt,
    };
    return badgeCatalog.all
        .map((BadgeDefinition definition) => BadgeView(
              badgeId: definition.badgeId,
              title: l10n.resolve(definition.titleLocalizationKey),
              description: l10n.resolve(definition.descriptionLocalizationKey),
              icon: definition.icon,
              color: definition.color,
              pillar: definition.pillar,
              earnedAt: earnedAt[definition.badgeId],
            ))
        .toList(growable: false);
  }

  /// The three histories, flattened and sorted by when they happened.
  Future<List<RecentActivityEntry>> _buildRecentActivity(
    int profileId,
    List<EarnedBadge> earned,
    AppLocalizations l10n,
  ) async {
    final List<RecentActivityEntry> entries = <RecentActivityEntry>[];

    final List<GameScore> recentScores =
        await gameScoresDao.getRecentScoresForProfile(profileId);
    for (final GameScore row in recentScores) {
      final GameDescriptor? descriptor =
          gameCatalog.findByActivityId(row.gameKey);
      final CategoryDefinition category = _categoryFor(row.gameKey);
      entries.add(RecentActivityEntry(
        kind: RecentActivityKind.game,
        title: descriptor == null
            ? categoryTitleFor(l10n, category.id)
            : l10n.resolve(descriptor.titleLocalizationKey),
        subtitle: _scoreSubtitle(row, l10n),
        icon: category.icon,
        color: category.color,
        occurredAt: row.playedAt,
      ));
    }

    final List<StoryNodeProgressData> nodes =
        await storyDao.allNodesFor(profileId);
    for (final StoryNodeProgressData node in nodes
        .where((StoryNodeProgressData n) => n.completion == 'completed')) {
      entries.add(RecentActivityEntry(
        kind: RecentActivityKind.storyNode,
        title: l10n.storyBeatsLabel,
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF8D6E63),
        occurredAt: node.updatedAt,
      ));
    }

    for (final EarnedBadge row in earned) {
      final BadgeDefinition? definition = badgeCatalog.findById(row.badgeId);
      if (definition == null) {
        // A badge that was retired from the catalog. The row stays in the
        // database — badges are never taken back — but there is nothing left
        // to render it with.
        continue;
      }
      entries.add(RecentActivityEntry(
        kind: RecentActivityKind.badge,
        title: l10n.resolve(definition.titleLocalizationKey),
        subtitle: l10n.badgeEarnedCaption,
        icon: definition.icon,
        color: definition.color,
        occurredAt: row.earnedAt,
      ));
    }

    entries.sort((RecentActivityEntry a, RecentActivityEntry b) =>
        b.occurredAt.compareTo(a.occurredAt));
    return entries.take(_activityLimit).toList(growable: false);
  }

  String _scoreSubtitle(GameScore row, AppLocalizations l10n) {
    final String points = l10n.pointsShortLabel(row.score);
    final int? stars = row.starsEarned;
    if (stars == null || stars <= 0) {
      return points;
    }
    return '$points  ${'★' * stars}';
  }

  CategoryDefinition _categoryFor(String gameKey) {
    final String id = categoryIdForGameKey(gameKey);
    return kGameCategories.firstWhere(
      (CategoryDefinition def) => def.id == id,
      orElse: () => kGameCategories.last,
    );
  }

  List<GameCategoryProgress> _buildCategories(
      List<GameScore> scores, AppLocalizations l10n) {
    return kGameCategories.map((CategoryDefinition def) {
      final List<GameScore> categoryScores = scores
          .where((GameScore s) => categoryIdForGameKey(s.gameKey) == def.id)
          .toList();

      final int score =
          categoryScores.fold<int>(0, (int sum, GameScore s) => sum + s.score);
      final int gamesPlayed = categoryScores.length;
      final int bestScore = categoryScores.isEmpty
          ? 0
          : categoryScores
              .map((GameScore s) => s.score)
              .reduce((int a, int b) => a > b ? a : b);
      final double progress = (score / _levelUpScore).clamp(0.0, 1.0);

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

  String _encouragementFor(AppLocalizations l10n, String categoryId,
      int gamesPlayed, double progress) {
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
}
