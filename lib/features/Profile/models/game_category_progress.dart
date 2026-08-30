import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class GameCategoryProgress extends Equatable {
  const GameCategoryProgress({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.score,
    required this.bestScore,
    required this.gamesPlayed,
    required this.progress,
    required this.encouragement,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final int score;
  final int bestScore;
  final int gamesPlayed;
  final double progress;
  final String encouragement;

  GameCategoryProgress copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? color,
    int? score,
    int? bestScore,
    int? gamesPlayed,
    double? progress,
    String? encouragement,
  }) {
    return GameCategoryProgress(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      progress: progress ?? this.progress,
      encouragement: encouragement ?? this.encouragement,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, icon, color, score, bestScore, gamesPlayed, progress, encouragement];
}
