import 'package:flutter/material.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';
import 'package:kidzo/core/badges/badge_unlock_rule.dart';

/// One badge: what it is called, how it looks, and what earns it.
///
/// Title and description are **keys**, never resolved strings. That is what
/// lets the catalog be a plain injected value with no `AppLocalizations`
/// dependency, and what lets the badge evaluator run with no `BuildContext` —
/// it is invoked the moment a game finishes, from a cubit, where there may not
/// be a widget tree left to read from.
@immutable
class BadgeDefinition {
  const BadgeDefinition({
    required this.badgeId,
    required this.titleLocalizationKey,
    required this.descriptionLocalizationKey,
    required this.icon,
    required this.color,
    required this.pillar,
    required this.isEarnedBy,
  });

  /// Stable identity, and the only part of a badge stored in the database.
  ///
  /// Never change one: it is the business key of an `EarnedBadges` row, so a
  /// rename silently takes the badge away from every child who has it.
  final String badgeId;

  final String titleLocalizationKey;
  final String descriptionLocalizationKey;
  final IconData icon;
  final Color color;
  final BadgePillar pillar;
  final BadgeUnlockRule isEarnedBy;
}
