import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  Achievement copyWith({bool? isUnlocked}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      color: color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  @override
  List<Object?> get props => [id, title, description, icon, color, isUnlocked];
}
