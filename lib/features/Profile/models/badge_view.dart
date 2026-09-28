import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:kidzo/core/badges/badge_pillar.dart';

/// One badge as the Profile shows it: the definition, resolved, plus whether
/// this particular child has it.
///
/// Replaces the old `Achievement`, which carried the same fields but was
/// rebuilt from scratch on every screen open and had no notion of *when* a
/// badge was earned — so it could never say "you got this on Tuesday", and
/// nothing could tell that a badge was new.
class BadgeView extends Equatable {
  const BadgeView({
    required this.badgeId,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.pillar,
    this.earnedAt,
  });

  final String badgeId;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final BadgePillar pillar;

  /// Null while the badge is still locked.
  final DateTime? earnedAt;

  bool get isEarned => earnedAt != null;

  @override
  List<Object?> get props => <Object?>[badgeId, earnedAt];
}
