import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/badge_catalog.dart';
import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';
import 'package:kidzo/core/badges/badge_stats_snapshot.dart';
import 'package:kidzo/core/badges/default_badge_catalog.dart';

/// Every unlock rule, at the boundary where it flips.
///
/// Pure: no database, no widgets. That is the point of routing every rule
/// through [BadgeStatsSnapshot] — the conditions a child is being judged by
/// are readable and checkable in one file.
void main() {
  final BadgeCatalog catalog = buildDefaultBadgeCatalog();

  bool earns(String badgeId, BadgeStatsSnapshot stats) =>
      catalog.findById(badgeId)!.isEarnedBy(stats);

  BadgeStatsSnapshot withPlays(Map<String, int> plays) =>
      _snapshot(playsByGameKey: plays, totalPlays: plays.values.fold(0, _sum));

  group('the catalog itself', () {
    test('holds 21 badges with no duplicate ids', () {
      expect(catalog.all, hasLength(21));
      expect(
        catalog.all.map((BadgeDefinition d) => d.badgeId).toSet(),
        hasLength(21),
      );
    });

    test('keeps the six original ids, on their original keys', () {
      // badgeId is the business key of an EarnedBadges row: renaming one takes
      // the badge away from every child who already has it. The achievement*
      // keys are kept so those twelve strings need no new translation.
      const Map<String, String> originals = <String, String>{
        'first_win': 'achievementFirstWinTitle',
        'memory_master': 'achievementMemoryMasterTitle',
        'math_star': 'achievementMathStarTitle',
        'five_day_streak': 'achievementFiveDayStreakTitle',
        'puzzle_hero': 'achievementPuzzleHeroTitle',
        'super_learner': 'achievementSuperLearnerTitle',
      };
      originals.forEach((String id, String titleKey) {
        final BadgeDefinition? definition = catalog.findById(id);
        expect(definition, isNotNull, reason: '$id went missing');
        expect(definition!.titleLocalizationKey, titleKey);
      });
    });

    test('every pillar has badges in it', () {
      for (final BadgePillar pillar in BadgePillar.values) {
        expect(catalog.forPillar(pillar), isNotEmpty, reason: pillar.name);
      }
    });

    test('nothing is earned by a child who has done nothing', () {
      for (final BadgeDefinition definition in catalog.all) {
        expect(
          definition.isEarnedBy(BadgeStatsSnapshot.empty),
          isFalse,
          reason: '${definition.badgeId} is awarded for free',
        );
      }
    });
  });

  group('Games', () {
    test('first_win needs one finished game', () {
      expect(earns('first_win', _snapshot(totalPlays: 0)), isFalse);
      expect(earns('first_win', _snapshot(totalPlays: 1)), isTrue);
    });

    test('memory_master counts both memory games together', () {
      expect(
        earns('memory_master',
            withPlays(<String, int>{'memory_game': 3, 'color_memory_game': 1})),
        isFalse,
      );
      expect(
        earns('memory_master',
            withPlays(<String, int>{'memory_game': 3, 'color_memory_game': 2})),
        isTrue,
      );
    });

    test('memory_master is no longer unreachable', () {
      // It used to read a Profile category total fed by games that recorded
      // nothing, so the counter was permanently zero. This is the regression
      // guard for that.
      expect(
        earns('memory_master', withPlays(<String, int>{'memory_game': 5})),
        isTrue,
      );
    });

    test('puzzle_hero needs five puzzles', () {
      expect(earns('puzzle_hero', withPlays(<String, int>{'puzzle': 4})),
          isFalse);
      expect(
          earns('puzzle_hero', withPlays(<String, int>{'puzzle': 5})), isTrue);
    });

    test('maze_runner needs three mazes', () {
      expect(earns('maze_runner', withPlays(<String, int>{'maze_game': 2})),
          isFalse);
      expect(earns('maze_runner', withPlays(<String, int>{'maze_game': 3})),
          isTrue);
    });

    test('tier_climber needs a Hard tier cleared, in any game', () {
      expect(
        earns('tier_climber',
            _snapshot(bestLevelByGameKey: <String, int>{'puzzle': 2})),
        isFalse,
      );
      expect(
        earns('tier_climber',
            _snapshot(bestLevelByGameKey: <String, int>{'puzzle': 3})),
        isTrue,
      );
    });

    test('triple_star needs three stars, in any game', () {
      expect(
        earns('triple_star',
            _snapshot(bestStarsByGameKey: <String, int>{'maze_game': 2})),
        isFalse,
      );
      expect(
        earns('triple_star',
            _snapshot(bestStarsByGameKey: <String, int>{'maze_game': 3})),
        isTrue,
      );
    });

    test('game_marathon needs 25 finished games', () {
      expect(earns('game_marathon', _snapshot(totalPlays: 24)), isFalse);
      expect(earns('game_marathon', _snapshot(totalPlays: 25)), isTrue);
    });
  });

  group('Education', () {
    test('math_star needs 80 in a maths game', () {
      expect(
        earns('math_star',
            _snapshot(bestScoreByGameKey: <String, int>{'math_game': 79})),
        isFalse,
      );
      expect(
        earns('math_star',
            _snapshot(bestScoreByGameKey: <String, int>{'math_game': 80})),
        isTrue,
      );
    });

    test('math_star does not count another game high score', () {
      expect(
        earns('math_star',
            _snapshot(bestScoreByGameKey: <String, int>{'puzzle': 500})),
        isFalse,
      );
    });

    test('super_learner needs 500 points overall', () {
      expect(earns('super_learner', _snapshot(totalScore: 499)), isFalse);
      expect(earns('super_learner', _snapshot(totalScore: 500)), isTrue);
    });

    test('quiz_whiz needs five animal quizzes', () {
      expect(earns('quiz_whiz', withPlays(<String, int>{'animal_quiz': 4})),
          isFalse);
      expect(earns('quiz_whiz', withPlays(<String, int>{'animal_quiz': 5})),
          isTrue);
    });

    test('healthy_eater pools the three food games', () {
      expect(
        earns(
          'healthy_eater',
          withPlays(<String, int>{
            'fruits': 2,
            'vegetables': 2,
          }),
        ),
        isFalse,
      );
      expect(
        earns(
          'healthy_eater',
          withPlays(<String, int>{
            'fruits': 2,
            'vegetables': 2,
            'fruit_veg_sorter': 1,
          }),
        ),
        isTrue,
      );
    });

    test('curious_mind counts breadth, not depth', () {
      expect(
        earns('curious_mind', withPlays(<String, int>{'animal_quiz': 40})),
        isFalse,
        reason: 'forty rounds of one game is not four different games',
      );
      expect(
        earns(
          'curious_mind',
          withPlays(<String, int>{
            'animal_quiz': 1,
            'math_game': 1,
            'fruits': 1,
            'vegetables': 1,
          }),
        ),
        isTrue,
      );
    });

    test('perfect_score needs a run that hit its own maximum', () {
      expect(earns('perfect_score', _snapshot(hasPerfectScore: false)), isFalse);
      expect(earns('perfect_score', _snapshot(hasPerfectScore: true)), isTrue);
    });
  });

  group('Story', () {
    test('story_first_step needs one finished node', () {
      expect(earns('story_first_step', _snapshot(storyNodesCompleted: 0)),
          isFalse);
      expect(earns('story_first_step', _snapshot(storyNodesCompleted: 1)),
          isTrue);
    });

    test('page_finder needs a page', () {
      expect(earns('page_finder', _snapshot(storyPagesFound: 0)), isFalse);
      expect(earns('page_finder', _snapshot(storyPagesFound: 1)), isTrue);
    });

    test('story_explorer needs ten nodes', () {
      expect(earns('story_explorer', _snapshot(storyNodesCompleted: 9)),
          isFalse);
      expect(earns('story_explorer', _snapshot(storyNodesCompleted: 10)),
          isTrue);
    });

    test('independent_reader needs three hint-free nodes', () {
      expect(
        earns('independent_reader',
            _snapshot(storyNodesCompleted: 20, storyNodesWithoutHints: 2)),
        isFalse,
      );
      expect(
        earns('independent_reader',
            _snapshot(storyNodesCompleted: 20, storyNodesWithoutHints: 3)),
        isTrue,
      );
    });

    test('story_finisher needs a finished adventure, not a started one', () {
      expect(
        earns('story_finisher',
            _snapshot(adventuresStarted: 3, adventuresCompleted: 0)),
        isFalse,
      );
      expect(earns('story_finisher', _snapshot(adventuresCompleted: 1)),
          isTrue);
    });
  });

  group('Habit', () {
    test('the three streaks step up in order', () {
      expect(earns('three_day_streak', _snapshot(currentStreak: 2)), isFalse);
      expect(earns('three_day_streak', _snapshot(currentStreak: 3)), isTrue);
      expect(earns('five_day_streak', _snapshot(currentStreak: 4)), isFalse);
      expect(earns('five_day_streak', _snapshot(currentStreak: 5)), isTrue);
      expect(earns('ten_day_streak', _snapshot(currentStreak: 9)), isFalse);
      expect(earns('ten_day_streak', _snapshot(currentStreak: 10)), isTrue);
    });

    test('a long streak earns all three at once', () {
      final BadgeStatsSnapshot stats = _snapshot(currentStreak: 12);
      for (final BadgeDefinition definition
          in catalog.forPillar(BadgePillar.habit)) {
        expect(definition.isEarnedBy(stats), isTrue,
            reason: definition.badgeId);
      }
    });
  });
}

int _sum(int a, int b) => a + b;

BadgeStatsSnapshot _snapshot({
  int totalScore = 0,
  int totalPlays = 0,
  int bestScore = 0,
  int totalStars = 0,
  int currentStreak = 0,
  Map<String, int> playsByGameKey = const <String, int>{},
  Map<String, int> bestScoreByGameKey = const <String, int>{},
  Map<String, int> bestStarsByGameKey = const <String, int>{},
  Map<String, int> bestLevelByGameKey = const <String, int>{},
  bool hasPerfectScore = false,
  int storyNodesCompleted = 0,
  int storyNodesWithoutHints = 0,
  int storyPagesFound = 0,
  int adventuresStarted = 0,
  int adventuresCompleted = 0,
}) {
  return BadgeStatsSnapshot(
    totalScore: totalScore,
    totalPlays: totalPlays,
    bestScore: bestScore,
    totalStars: totalStars,
    currentStreak: currentStreak,
    playsByGameKey: playsByGameKey,
    bestScoreByGameKey: bestScoreByGameKey,
    bestStarsByGameKey: bestStarsByGameKey,
    bestLevelByGameKey: bestLevelByGameKey,
    hasPerfectScore: hasPerfectScore,
    storyNodesCompleted: storyNodesCompleted,
    storyNodesWithoutHints: storyNodesWithoutHints,
    storyPagesFound: storyPagesFound,
    adventuresStarted: adventuresStarted,
    adventuresCompleted: adventuresCompleted,
  );
}
