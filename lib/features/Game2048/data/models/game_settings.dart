import 'package:equatable/equatable.dart';

class GameSettings extends Equatable {
  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      boardSize: json['boardSize'] as int? ?? 4,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      undoEnabled: json['undoEnabled'] as bool? ?? true,
      targetTile: json['targetTile'] as int? ?? 2048,
    );
  }
  const GameSettings({
    this.boardSize = 4,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.undoEnabled = true,
    this.targetTile = 2048,
  });

  final int boardSize;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool undoEnabled;
  final int targetTile;

  GameSettings copyWith({
    int? boardSize,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? undoEnabled,
    int? targetTile,
  }) {
    return GameSettings(
      boardSize: boardSize ?? this.boardSize,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      undoEnabled: undoEnabled ?? this.undoEnabled,
      targetTile: targetTile ?? this.targetTile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'boardSize': boardSize,
      'soundEnabled': soundEnabled,
      'hapticEnabled': hapticEnabled,
      'undoEnabled': undoEnabled,
      'targetTile': targetTile,
    };
  }

  @override
  List<Object?> get props =>
      [boardSize, soundEnabled, hapticEnabled, undoEnabled, targetTile];
}
