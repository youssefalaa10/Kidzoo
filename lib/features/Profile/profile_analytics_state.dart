import 'package:equatable/equatable.dart';

import 'models/badge_view.dart';
import 'models/game_category_progress.dart';
import 'models/recent_activity_entry.dart';

abstract class ProfileAnalyticsState extends Equatable {
  const ProfileAnalyticsState();

  @override
  List<Object?> get props => [];
}

class ProfileAnalyticsInitial extends ProfileAnalyticsState {}

class ProfileAnalyticsLoading extends ProfileAnalyticsState {}

class ProfileAnalyticsLoaded extends ProfileAnalyticsState {
  const ProfileAnalyticsLoaded({
    required this.totalScore,
    required this.stars,
    required this.gamesPlayed,
    required this.currentStreak,
    required this.bestScore,
    required this.categories,
    required this.badges,
    required this.recentActivity,
    required this.storyNodesCompleted,
    required this.storyPagesFound,
    required this.adventuresCompleted,
    required this.adventuresStarted,
  });

  final int totalScore;
  final int stars;
  final int gamesPlayed;
  final int currentStreak;
  final int bestScore;
  final List<GameCategoryProgress> categories;

  /// Every badge in the catalog, earned or not.
  final List<BadgeView> badges;

  /// Games, story beats and badges, newest first.
  final List<RecentActivityEntry> recentActivity;

  final int storyNodesCompleted;
  final int storyPagesFound;
  final int adventuresCompleted;
  final int adventuresStarted;

  int get badgesEarned =>
      badges.where((BadgeView badge) => badge.isEarned).length;

  @override
  List<Object?> get props => [
        totalScore,
        stars,
        gamesPlayed,
        currentStreak,
        bestScore,
        categories,
        badges,
        recentActivity,
        storyNodesCompleted,
        storyPagesFound,
        adventuresCompleted,
        adventuresStarted,
      ];
}

class ProfileAnalyticsError extends ProfileAnalyticsState {
  const ProfileAnalyticsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
