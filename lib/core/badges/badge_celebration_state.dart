import 'package:equatable/equatable.dart';
import 'package:kidzo/core/badges/badge_definition.dart';

/// Badges waiting to be celebrated, in the order they were earned.
///
/// The queue *is* the state. Several badges can come true on one run — a
/// child's twenty-fifth game might also be their first three-star and their
/// fifth day in a row — and showing three overlapping pop-ups would be worse
/// than showing none.
class BadgeCelebrationState extends Equatable {
  const BadgeCelebrationState({this.pending = const <BadgeDefinition>[]});

  final List<BadgeDefinition> pending;

  BadgeDefinition? get current => pending.isEmpty ? null : pending.first;

  bool get isCelebrating => pending.isNotEmpty;

  @override
  List<Object?> get props =>
      <Object?>[pending.map((BadgeDefinition b) => b.badgeId).toList()];
}
