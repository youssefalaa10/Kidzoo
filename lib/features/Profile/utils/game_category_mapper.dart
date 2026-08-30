import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class CategoryDefinition {
  const CategoryDefinition({
    required this.id,
    required this.icon,
    required this.color,
  });

  final String id;
  final IconData icon;
  final Color color;
}

const List<CategoryDefinition> kGameCategories = [
  CategoryDefinition(
    id: 'memory',
    icon: Icons.psychology_rounded,
    color: Color(0xFF7C4DFF),
  ),
  CategoryDefinition(
    id: 'math',
    icon: Icons.calculate_rounded,
    color: Color(0xFFFF9F43),
  ),
  CategoryDefinition(
    id: 'puzzle',
    icon: Icons.extension_rounded,
    color: Color(0xFF26C6DA),
  ),
  CategoryDefinition(
    id: 'sports',
    icon: Icons.sports_soccer_rounded,
    color: Color(0xFF66BB6A),
  ),
  CategoryDefinition(
    id: 'language',
    icon: Icons.abc_rounded,
    color: Color(0xFFFF6B81),
  ),
];

/// Localized display title for a category [id] (see [kGameCategories]).
String categoryTitleFor(AppLocalizations l10n, String id) {
  switch (id) {
    case 'memory':
      return l10n.categoryMemoryGames;
    case 'math':
      return l10n.categoryMathGames;
    case 'puzzle':
      return l10n.categoryPuzzleGames;
    case 'sports':
      return l10n.categorySportsGames;
    default:
      return l10n.categoryLanguageGames;
  }
}

/// Maps a raw `gameKey` (as stored in [GameScores.gameKey]) to one of the
/// fixed category ids in [kGameCategories]. New games can be dropped into an
/// existing bucket just by including a matching keyword in their gameKey.
String categoryIdForGameKey(String gameKey) {
  final key = gameKey.toLowerCase();

  const explicitMap = {
    'feed_animal_game': 'memory',
    'vegetables': 'puzzle',
    'vehicles_game': 'sports',
    'fruits': 'language',
  };
  if (explicitMap.containsKey(key)) return explicitMap[key]!;

  if (key.contains('math') || key.contains('number') || key.contains('calc')) {
    return 'math';
  }
  if (key.contains('memory') || key.contains('match')) return 'memory';
  if (key.contains('puzzle') || key.contains('sort')) return 'puzzle';
  if (key.contains('sport') || key.contains('vehicle')) return 'sports';
  return 'language';
}
