import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/catalog/default_game_catalog.dart';
import 'package:kidzo/core/catalog/game_catalog.dart';
import 'package:kidzo/core/catalog/game_descriptor.dart';
import 'package:kidzo/core/catalog/game_surface.dart';
import 'package:kidzo/core/difficulty/kid_difficulty.dart';

/// Locks the Games and Education grids to an explicit, reviewed list.
///
/// Originally this asserted the grids were byte-identical to the pre-migration
/// lists. That changed deliberately when Challenge became Adventures: six games
/// had been reachable *only* through the old level map, so they were added to
/// the grids rather than left unreachable. Every entry below is therefore a
/// decision someone made, not an accident.
///
/// The promise Adventure Mode makes is that free play is never altered by story
/// work. `surface` now drives grid membership, so a careless catalog edit could
/// silently add or drop a game. These expectations are the guard, and they are
/// written out longhand on purpose: a test that derived the expected list from
/// the catalog would pass no matter what the catalog said.
void main() {
  const List<String> expectedGamesOrder = <String>[
    'tic_tac_toe',
    'flappy_bird',
    'missing_letter',
    'game_2048',
    'dots_and_boxes',
    'paddle_bounce',
    'draw_lab',
    // Added when Challenge became Adventures. These four were reachable only
    // through the old level map, so leaving them out would have made working
    // games unreachable. See the note in default_game_catalog.dart.
    'memory_game',
    'color_memory_game',
    'puzzle',
    'maze_game',
  ];

  const List<String> expectedEducationOrder = <String>[
    'numbers',
    'animal_names',
    'alphabet',
    'shapes',
    'flag_game',
    'color_switch',
    'feed_animal_game',
    'fruit_veg_sorter',
    'vehicles_game',
    'fruits',
    'vegetables',
    // Appended when Challenge became Adventures, so the eleven above keep the
    // exact order they have always had.
    'animal_quiz',
    'math_game',
  ];

  /// The keys already written to `GameScores.gameKey` before this migration.
  /// If any of these changes, existing score history stops joining.
  const List<String> historicalScoreKeys = <String>[
    'feed_animal_game',
    'fruit_veg_sorter',
    'vehicles_game',
    'fruits',
    'vegetables',
  ];

  late final GameCatalog catalog;

  setUpAll(() {
    catalog = buildDefaultGameCatalog();
  });

  List<String> idsFor(GameSurface surface) => catalog
      .forSurface(surface)
      .map((GameDescriptor descriptor) => descriptor.activityId)
      .toList();

  group('Grid contents', () {
    test('Games grid matches the expected list, in order', () {
      expect(idsFor(GameSurface.games), expectedGamesOrder);
    });

    test('Education grid matches the expected list, in order', () {
      expect(idsFor(GameSurface.education), expectedEducationOrder);
    });

    test('the catalog contains nothing outside the two grids', () {
      expect(catalog.all.length,
          expectedGamesOrder.length + expectedEducationOrder.length);
    });

    test('activityIds are unique', () {
      final List<String> ids = catalog.all
          .map((GameDescriptor descriptor) => descriptor.activityId)
          .toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('Score history stays joinable', () {
    test('every historical gameKey is still an activityId', () {
      for (final String key in historicalScoreKeys) {
        expect(catalog.findByActivityId(key), isNotNull,
            reason: 'historical GameScores.gameKey "$key" vanished from the '
                'catalog, orphaning its score rows');
      }
    });
  });

  group('Descriptor integrity', () {
    Map<String, dynamic> loadLanguageFile(String languageCode) =>
        json.decode(File('assets/lang/$languageCode.json').readAsStringSync())
            as Map<String, dynamic>;

    test('every title key resolves in both locales', () {
      final Map<String, dynamic> english = loadLanguageFile('en');
      final Map<String, dynamic> arabic = loadLanguageFile('ar');
      for (final GameDescriptor descriptor in catalog.all) {
        expect(english.containsKey(descriptor.titleLocalizationKey), isTrue,
            reason: '${descriptor.activityId}: no en.json entry for '
                '"${descriptor.titleLocalizationKey}" — the grid would show '
                'the raw key');
        expect(arabic.containsKey(descriptor.titleLocalizationKey), isTrue,
            reason: '${descriptor.activityId}: no ar.json entry for '
                '"${descriptor.titleLocalizationKey}"');
      }
    });

    test('every icon and flip image exists on disk', () {
      for (final GameDescriptor descriptor in catalog.all) {
        expect(File(descriptor.iconAsset).existsSync(), isTrue,
            reason:
                '${descriptor.activityId}: missing ${descriptor.iconAsset}');
        expect(File(descriptor.flipImageAsset).existsSync(), isTrue,
            reason:
                '${descriptor.activityId}: missing ${descriptor.flipImageAsset}');
      }
    });

    test('screenBuilder is lazy — constructing the catalog builds no screens',
        () {
      // The previous registry stored constructed Widgets, so listing the grid
      // built all 18 screens and their BlocProviders on every rebuild. If this
      // ever regresses, building the catalog would do real work (and, for the
      // Bloc-wrapped entries, throw outside a widget tree).
      expect(() => buildDefaultGameCatalog(), returnsNormally);
      for (final GameDescriptor descriptor in catalog.all) {
        expect(descriptor.screenBuilder, isA<Function>());
      }
    });
  });

  group('Difficulty tiers', () {
    /// The exact set of games whose card opens the picker instead of the game.
    ///
    /// Adding a game here is a product decision: it means a child can no
    /// longer reach it in one tap. Dropping one silently strands whatever
    /// Medium and Hard content that game already implements, which is the bug
    /// this whole feature exists to undo.
    const Set<String> expectedTieredIds = <String>{
      'animal_quiz',
      'color_memory_game',
      'math_game',
      'maze_game',
      'memory_game',
      'puzzle',
    };

    test('exactly the six free-play games offer tiers', () {
      final Set<String> actual = catalog.all
          .where((GameDescriptor d) => d.hasDifficultyTiers)
          .map((GameDescriptor d) => d.activityId)
          .toSet();
      expect(actual, expectedTieredIds);
    });

    test('every tier description key resolves in both locales', () {
      // These keys are read through AppLocalizations.resolve rather than a
      // getter, so locale_parity_test cannot see them. Without this guard a
      // missing key degrades silently to a blank line on the card.
Map<String, dynamic> loadLocale(String code) =>          json.decode(File('assets/lang/$code.json').readAsStringSync())              as Map<String, dynamic>;      final Map<String, dynamic> english = loadLocale('en');      final Map<String, dynamic> arabic = loadLocale('ar');
      const List<String> prefixes = <String>[
        'animalQuiz',
        'colorMemory',
        'math',
        'maze',
        'memory',
        'puzzle',
      ];
      for (final String prefix in prefixes) {
        for (final String tier in <String>['Easy', 'Medium', 'Hard']) {
          final String key = '$prefix${tier}Description';
          expect(english.containsKey(key), isTrue,
              reason: 'no en.json entry for "$key"');
          expect(arabic.containsKey(key), isTrue,
              reason: 'no ar.json entry for "$key"');
        }
      }
    });

    test('the tiered builders cover all three tiers', () {
      for (final GameDescriptor descriptor in catalog.all
          .where((GameDescriptor d) => d.hasDifficultyTiers)) {
        for (final KidDifficulty tier in KidDifficulty.values) {
          expect(() => descriptor.tieredScreenBuilder!(tier), returnsNormally,
              reason: " cannot build ");
        }
      }
    });
  });
}
