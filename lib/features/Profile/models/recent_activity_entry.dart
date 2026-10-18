import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:kidzo/features/Profile/models/recent_activity_kind.dart';

/// One line in the Profile's "lately" feed.
///
/// Three very different sources — a score row, a finished story beat, an
/// earned badge — flattened into one shape so they can be sorted together by
/// when they happened. A child does not think of those as three separate
/// histories, and showing them as three lists would be the app's filing
/// system leaking into their profile.
class RecentActivityEntry extends Equatable {
  const RecentActivityEntry({
    required this.kind,
    required this.title,
    required this.icon,
    required this.color,
    required this.occurredAt,
    this.subtitle,
  });

  final RecentActivityKind kind;

  /// Already resolved for display.
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final DateTime occurredAt;

  @override
  List<Object?> get props => <Object?>[kind, title, subtitle, occurredAt];
}
