import 'package:flutter/material.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

import '../models/game_category_progress.dart';
import '../profile_analytics_state.dart';
import 'badge_wall.dart';
import 'game_analytics_card.dart';
import 'profile_section_title.dart';
import 'recent_activity_list.dart';
import 'score_summary.dart';
import 'story_progress_card.dart';

/// What the child has done, and what they have to show for it.
///
/// Split off from the editing controls so the rewarding half of the Profile is
/// one tap away rather than a long scroll past a form.
class ProfileProgressTab extends StatelessWidget {
  const ProfileProgressTab({
    required this.analytics,
    required this.bottomPadding,
    super.key,
  });

  final ProfileAnalyticsLoaded analytics;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ScoreSummary(
            metrics: <ScoreMetric>[
              ScoreMetric(
                icon: Icons.stars_rounded,
                label: l10n.totalScoreLabel,
                value: '${analytics.totalScore}',
                color: const Color(0xFF7C4DFF),
              ),
              ScoreMetric(
                icon: Icons.auto_awesome_rounded,
                label: l10n.starsEarnedLabel,
                value: '${analytics.stars}',
                color: const Color(0xFFFFC107),
              ),
              ScoreMetric(
                icon: Icons.videogame_asset_rounded,
                label: l10n.gamesPlayedLabel,
                value: '${analytics.gamesPlayed}',
                color: const Color(0xFF26C6DA),
              ),
              ScoreMetric(
                icon: Icons.local_fire_department_rounded,
                label: l10n.currentStreakLabel,
                value: '${analytics.currentStreak} ${l10n.daysSuffix}',
                color: const Color(0xFFFF5252),
              ),
              ScoreMetric(
                icon: Icons.emoji_events_rounded,
                label: l10n.bestScoreLabel,
                value: '${analytics.bestScore}',
                color: const Color(0xFF66BB6A),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ProfileSectionTitle(title: l10n.recentActivityTitle),
          const SizedBox(height: 12),
          RecentActivityList(entries: analytics.recentActivity),
          const SizedBox(height: 24),
          ProfileSectionTitle(title: l10n.storyProgressTitle),
          const SizedBox(height: 12),
          StoryProgressCard(
            nodesCompleted: analytics.storyNodesCompleted,
            pagesFound: analytics.storyPagesFound,
            adventuresCompleted: analytics.adventuresCompleted,
            adventuresStarted: analytics.adventuresStarted,
          ),
          const SizedBox(height: 24),
          ProfileSectionTitle(
            title: l10n.badgeWallTitle,
            trailing: Text(
              l10n.badgeWallCount(
                  analytics.badgesEarned, analytics.badges.length),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          BadgeWall(badges: analytics.badges),
          ProfileSectionTitle(title: l10n.gameProgressTitle),
          const SizedBox(height: 12),
          for (final GameCategoryProgress category in analytics.categories)
            GameAnalyticsCard(category: category),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}
