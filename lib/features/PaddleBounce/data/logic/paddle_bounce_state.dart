import '../models/paddle_bounce_models.dart';

class PaddleBounceState {
  factory PaddleBounceState.initial({
    required PaddleBounceGameMode gameMode,
    required AIDifficulty aiDifficulty,
    required double screenWidth,
    required double screenHeight,
    int winningScore = 5,
  }) {
    final paddleWidth = screenWidth * 0.35;
    final paddleHeight = 20.0;
    final ballRadius = 10.0;

    return PaddleBounceState(
      gameMode: gameMode,
      aiDifficulty: aiDifficulty,
      status: PaddleBounceGameStatus.waiting,
      ball: Ball(
        x: screenWidth / 2,
        y: screenHeight / 2,
        velocityX: 0,
        velocityY: 0,
        radius: ballRadius,
      ),
      topPaddle: Paddle(
        x: (screenWidth - paddleWidth) / 2,
        width: paddleWidth,
        height: paddleHeight,
      ),
      bottomPaddle: Paddle(
        x: (screenWidth - paddleWidth) / 2,
        width: paddleWidth,
        height: paddleHeight,
      ),
      player1Score: 0,
      player2Score: 0,
      winningScore: winningScore,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }
  PaddleBounceState({
    required this.gameMode,
    required this.aiDifficulty,
    required this.status,
    required this.ball,
    required this.topPaddle,
    required this.bottomPaddle,
    required this.player1Score,
    required this.player2Score,
    required this.winningScore,
    this.winner,
    this.screenWidth = 0.0,
    this.screenHeight = 0.0,
  });

  final PaddleBounceGameMode gameMode;
  final AIDifficulty aiDifficulty;
  final PaddleBounceGameStatus status;
  final Ball ball;
  final Paddle topPaddle;
  final Paddle bottomPaddle;
  final int player1Score;
  final int player2Score;
  final int winningScore;
  final int? winner; // 1 for player 1, 2 for player 2
  final double screenWidth;
  final double screenHeight;

  PaddleBounceState copyWith({
    PaddleBounceGameMode? gameMode,
    AIDifficulty? aiDifficulty,
    PaddleBounceGameStatus? status,
    Ball? ball,
    Paddle? topPaddle,
    Paddle? bottomPaddle,
    int? player1Score,
    int? player2Score,
    int? winningScore,
    int? winner,
    double? screenWidth,
    double? screenHeight,
  }) {
    return PaddleBounceState(
      gameMode: gameMode ?? this.gameMode,
      aiDifficulty: aiDifficulty ?? this.aiDifficulty,
      status: status ?? this.status,
      ball: ball ?? this.ball,
      topPaddle: topPaddle ?? this.topPaddle,
      bottomPaddle: bottomPaddle ?? this.bottomPaddle,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      winningScore: winningScore ?? this.winningScore,
      winner: winner,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
    );
  }

  bool get isGameOver => winner != null;
  bool get isPaused => status == PaddleBounceGameStatus.paused;
  bool get isPlaying => status == PaddleBounceGameStatus.playing;
}
