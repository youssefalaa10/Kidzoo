import 'package:flutter/material.dart';
import 'package:kidzo/core/badges/badge_catalog.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';
import 'package:kidzo/core/badges/badge_stats_snapshot.dart';

/// Games whose `gameKey` counts towards the memory badges.
const Set<String> _memoryGameKeys = <String>{
  'memory_game',
  'color_memory_game',
};

/// The food games, which between them teach the same vocabulary.
const Set<String> _foodGameKeys = <String>{
  'fruits',
  'vegetables',
  'fruit_veg_sorter',
};

/// Everything on the Education surface that records a score.
const Set<String> _educationGameKeys = <String>{
  'animal_quiz',
  'math_game',
  'feed_animal_game',
  'fruit_veg_sorter',
  'vehicles_game',
  'fruits',
  'vegetables',
};

/// The badge set, across the four pillars.
///
/// **The six original ids are preserved verbatim**, with their original
/// localization keys, icons and colours: `badgeId` is what an `EarnedBadges`
/// row stores, so renaming one would take the badge away from every child who
/// already has it, and reusing the `achievement*` keys means those twelve
/// strings need no new translation.
///
/// Three of those six could never actually be won. `memory_master`,
/// `math_star` and `puzzle_hero` were keyed off the Profile's game *category*
/// totals, and the games feeding those categories recorded nothing at all, so
/// the counters they read were permanently zero. They now key off literal
/// `gameKey`s, which — together with those games finally recording their runs
/// — makes them earnable for the first time.
///
/// Story badges count nodes, pages and chapters rather than whole adventures,
/// so the set stays meaningful however many adventures ship.
BadgeCatalog buildDefaultBadgeCatalog() {
  return BadgeCatalog(<BadgeDefinition>[
    // ---- Games ----
    BadgeDefinition(
      badgeId: 'first_win',
      titleLocalizationKey: 'achievementFirstWinTitle',
      descriptionLocalizationKey: 'achievementFirstWinDesc',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFC107),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) => s.totalPlays >= 1,
    ),
    BadgeDefinition(
      badgeId: 'memory_master',
      titleLocalizationKey: 'achievementMemoryMasterTitle',
      descriptionLocalizationKey: 'achievementMemoryMasterDesc',
      icon: Icons.psychology_rounded,
      color: const Color(0xFF7C4DFF),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) => s.playsAcross(_memoryGameKeys) >= 5,
    ),
    BadgeDefinition(
      badgeId: 'puzzle_hero',
      titleLocalizationKey: 'achievementPuzzleHeroTitle',
      descriptionLocalizationKey: 'achievementPuzzleHeroDesc',
      icon: Icons.extension_rounded,
      color: const Color(0xFF26C6DA),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) =>
          s.playsAcross(const <String>{'puzzle'}) >= 5,
    ),
    BadgeDefinition(
      badgeId: 'maze_runner',
      titleLocalizationKey: 'badgeMazeRunnerTitle',
      descriptionLocalizationKey: 'badgeMazeRunnerDesc',
      icon: Icons.alt_route_rounded,
      color: const Color(0xFF3F8EFC),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) =>
          s.playsAcross(const <String>{'maze_game'}) >= 3,
    ),
    BadgeDefinition(
      badgeId: 'tier_climber',
      titleLocalizationKey: 'badgeTierClimberTitle',
      descriptionLocalizationKey: 'badgeTierClimberDesc',
      icon: Icons.trending_up_rounded,
      color: const Color(0xFFAB47BC),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) => s.hasClearedAnyHardTier,
    ),
    BadgeDefinition(
      badgeId: 'triple_star',
      titleLocalizationKey: 'badgeTripleStarTitle',
      descriptionLocalizationKey: 'badgeTripleStarDesc',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFFFFB300),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) => s.hasAnyThreeStar,
    ),
    BadgeDefinition(
      badgeId: 'game_marathon',
      titleLocalizationKey: 'badgeGameMarathonTitle',
      descriptionLocalizationKey: 'badgeGameMarathonDesc',
      icon: Icons.sports_esports_rounded,
      color: const Color(0xFF00897B),
      pillar: BadgePillar.games,
      isEarnedBy: (BadgeStatsSnapshot s) => s.totalPlays >= 25,
    ),

    // ---- Education ----
    BadgeDefinition(
      badgeId: 'math_star',
      titleLocalizationKey: 'achievementMathStarTitle',
      descriptionLocalizationKey: 'achievementMathStarDesc',
      icon: Icons.calculate_rounded,
      color: const Color(0xFFFF9F43),
      pillar: BadgePillar.education,
      isEarnedBy: (BadgeStatsSnapshot s) => s.bestScoreFor('math_game') >= 80,
    ),
    BadgeDefinition(
      badgeId: 'super_learner',
      titleLocalizationKey: 'achievementSuperLearnerTitle',
      descriptionLocalizationKey: 'achievementSuperLearnerDesc',
      icon: Icons.school_rounded,
      color: const Color(0xFF66BB6A),
      pillar: BadgePillar.education,
      isEarnedBy: (BadgeStatsSnapshot s) => s.totalScore >= 500,
    ),
    BadgeDefinition(
      badgeId: 'quiz_whiz',
      titleLocalizationKey: 'badgeQuizWhizTitle',
      descriptionLocalizationKey: 'badgeQuizWhizDesc',
      icon: Icons.quiz_rounded,
      color: const Color(0xFFEF6C00),
      pillar: BadgePillar.education,
      isEarnedBy: (BadgeStatsSnapshot s) =>
          s.playsAcross(const <String>{'animal_quiz'}) >= 5,
    ),
    BadgeDefinition(
      badgeId: 'healthy_eater',
      titleLocalizationKey: 'badgeHealthyEaterTitle',
      descriptionLocalizationKey: 'badgeHealthyEaterDesc',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFF7CB342),
      pillar: BadgePillar.education,
      isEarnedBy: (BadgeStatsSnapshot s) => s.playsAcross(_foodGameKeys) >= 5,
    ),
    BadgeDefinition(
      badgeId: 'curious_mind',
      titleLocalizationKey: 'badgeCuriousMindTitle',
      descriptionLocalizationKey: 'badgeCuriousMindDesc',
      icon: Icons.travel_explore_rounded,
      color: const Color(0xFF5C6BC0),
      pillar: BadgePillar.education,
      isEarnedBy: (BadgeStatsSnapshot s) =>
          s.distinctPlayedAmong(_educationGameKeys) >= 4,
    ),
    BadgeDefinition(
      badgeId: 'perfect_score',
      titleLocalizationKey: 'badgePerfectScoreTitle',
      descriptionLocalizationKey: 'badgePerfectScoreDesc',
      icon: Icons.verified_rounded,
      color: const Color(0xFFD81B60),
      pillar: BadgePillar.education,
      isEarnedBy: (BadgeStatsSnapshot s) => s.hasPerfectScore,
    ),

    // ---- Story ----
    BadgeDefinition(
      badgeId: 'story_first_step',
      titleLocalizationKey: 'badgeStoryFirstStepTitle',
      descriptionLocalizationKey: 'badgeStoryFirstStepDesc',
      icon: Icons.auto_stories_rounded,
      color: const Color(0xFF8D6E63),
      pillar: BadgePillar.story,
      isEarnedBy: (BadgeStatsSnapshot s) => s.storyNodesCompleted >= 1,
    ),
    BadgeDefinition(
      badgeId: 'page_finder',
      titleLocalizationKey: 'badgePageFinderTitle',
      descriptionLocalizationKey: 'badgePageFinderDesc',
      icon: Icons.description_rounded,
      color: const Color(0xFF26A69A),
      pillar: BadgePillar.story,
      isEarnedBy: (BadgeStatsSnapshot s) => s.storyPagesFound >= 1,
    ),
    BadgeDefinition(
      badgeId: 'story_explorer',
      titleLocalizationKey: 'badgeStoryExplorerTitle',
      descriptionLocalizationKey: 'badgeStoryExplorerDesc',
      icon: Icons.explore_rounded,
      color: const Color(0xFF43A047),
      pillar: BadgePillar.story,
      isEarnedBy: (BadgeStatsSnapshot s) => s.storyNodesCompleted >= 10,
    ),
    BadgeDefinition(
      badgeId: 'independent_reader',
      titleLocalizationKey: 'badgeIndependentReaderTitle',
      descriptionLocalizationKey: 'badgeIndependentReaderDesc',
      icon: Icons.emoji_objects_rounded,
      color: const Color(0xFFFDD835),
      pillar: BadgePillar.story,
      isEarnedBy: (BadgeStatsSnapshot s) => s.storyNodesWithoutHints >= 3,
    ),
    BadgeDefinition(
      badgeId: 'story_finisher',
      titleLocalizationKey: 'badgeStoryFinisherTitle',
      descriptionLocalizationKey: 'badgeStoryFinisherDesc',
      icon: Icons.flag_rounded,
      color: const Color(0xFFE53935),
      pillar: BadgePillar.story,
      isEarnedBy: (BadgeStatsSnapshot s) => s.adventuresCompleted >= 1,
    ),

    // ---- Habit ----
    BadgeDefinition(
      badgeId: 'three_day_streak',
      titleLocalizationKey: 'badgeThreeDayStreakTitle',
      descriptionLocalizationKey: 'badgeThreeDayStreakDesc',
      icon: Icons.whatshot_rounded,
      color: const Color(0xFFFF7043),
      pillar: BadgePillar.habit,
      isEarnedBy: (BadgeStatsSnapshot s) => s.currentStreak >= 3,
    ),
    BadgeDefinition(
      badgeId: 'five_day_streak',
      titleLocalizationKey: 'achievementFiveDayStreakTitle',
      descriptionLocalizationKey: 'achievementFiveDayStreakDesc',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF5252),
      pillar: BadgePillar.habit,
      isEarnedBy: (BadgeStatsSnapshot s) => s.currentStreak >= 5,
    ),
    BadgeDefinition(
      badgeId: 'ten_day_streak',
      titleLocalizationKey: 'badgeTenDayStreakTitle',
      descriptionLocalizationKey: 'badgeTenDayStreakDesc',
      icon: Icons.military_tech_rounded,
      color: const Color(0xFFC62828),
      pillar: BadgePillar.habit,
      isEarnedBy: (BadgeStatsSnapshot s) => s.currentStreak >= 10,
    ),
  ]);
}
