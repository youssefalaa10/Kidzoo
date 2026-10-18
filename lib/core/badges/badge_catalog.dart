import 'package:kidzo/core/badges/badge_definition.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';

/// Every badge the app can award.
///
/// Mirrors `GameCatalog`: a plain injected value, never a singleton, built by
/// a top-level function so tests can hand in a smaller set.
class BadgeCatalog {
  BadgeCatalog(List<BadgeDefinition> definitions)
      : _definitions = List<BadgeDefinition>.unmodifiable(definitions) {
    assert(
      _definitions.map((BadgeDefinition d) => d.badgeId).toSet().length ==
          _definitions.length,
      'duplicate badgeId: badgeId is the business key of an EarnedBadges row, '
      'so two definitions sharing one would fight over the same award',
    );
  }

  final List<BadgeDefinition> _definitions;

  List<BadgeDefinition> get all => _definitions;

  List<BadgeDefinition> forPillar(BadgePillar pillar) => _definitions
      .where((BadgeDefinition d) => d.pillar == pillar)
      .toList(growable: false);

  BadgeDefinition? findById(String badgeId) {
    for (final BadgeDefinition definition in _definitions) {
      if (definition.badgeId == badgeId) {
        return definition;
      }
    }
    return null;
  }
}
