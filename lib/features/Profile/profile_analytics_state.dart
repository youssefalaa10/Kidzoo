import 'package:equatable/equatable.dart';

import 'models/achievement.dart';
import 'models/game_category_progress.dart';

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
    required this.achievements,
  });

  final int totalScore;
  final int stars;
  final int gamesPlayed;
  final int currentStreak;
  final int bestScore;
  final List<GameCategoryProgress> categories;
  final List<Achievement> achievements;

  @override
  List<Object?> get props =>
      [totalScore, stars, gamesPlayed, currentStreak, bestScore, categories, achievements];
}

class ProfileAnalyticsError extends ProfileAnalyticsState {
  const ProfileAnalyticsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
