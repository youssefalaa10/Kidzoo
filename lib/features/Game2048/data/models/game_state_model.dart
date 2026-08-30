import 'package:equatable/equatable.dart';

import 'board_model.dart';

enum GameStatus {
  initial,
  playing,
  won,
  lost,
  wonContinued,
}

class GameState extends Equatable {
  const GameState({
    required this.board,
    this.status = GameStatus.initial,
    this.bestScore = 0,
    this.gamesPlayed = 0,
    this.maxTileAchieved = 0,
    this.totalPlayTimeSeconds = 0,
    this.winCount = 0,
    this.moveCount = 0,
  });

  factory GameState.initial() {
    return GameState(
      board: Board.empty(),
    );
  }

  final Board board;
  final GameStatus status;
  final int bestScore;
  final int gamesPlayed;
  final int maxTileAchieved;
  final int totalPlayTimeSeconds;
  final int winCount;
  final int moveCount;

  int get currentScore => board.score;

  GameState copyWith({
    Board? board,
    GameStatus? status,
    int? bestScore,
    int? gamesPlayed,
    int? maxTileAchieved,
    int? totalPlayTimeSeconds,
    int? winCount,
    int? moveCount,
  }) {
    return GameState(
      board: board ?? this.board,
      status: status ?? this.status,
      bestScore: bestScore ?? this.bestScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      maxTileAchieved: maxTileAchieved ?? this.maxTileAchieved,
      totalPlayTimeSeconds: totalPlayTimeSeconds ?? this.totalPlayTimeSeconds,
      winCount: winCount ?? this.winCount,
      moveCount: moveCount ?? this.moveCount,
    );
  }

  @override
  List<Object?> get props => [
        board,
        status,
        bestScore,
        gamesPlayed,
        maxTileAchieved,
        totalPlayTimeSeconds,
        winCount,
        moveCount,
      ];
}
