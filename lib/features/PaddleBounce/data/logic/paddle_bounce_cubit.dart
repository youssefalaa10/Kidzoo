import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/paddle_bounce_models.dart';
import 'paddle_bounce_state.dart';

class PaddleBounceCubit extends Cubit<PaddleBounceState> {
  PaddleBounceCubit({
    required double screenWidth,
    required double screenHeight,
    PaddleBounceGameMode gameMode = PaddleBounceGameMode.vsFriend,
    AIDifficulty aiDifficulty = AIDifficulty.easy,
    int winningScore = 5,
  }) : super(PaddleBounceState.initial(
          gameMode: gameMode,
          aiDifficulty: aiDifficulty,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          winningScore: winningScore,
        )) {
    _gameLoopTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 FPS
      (_) => _updateGame(),
    );
    _boopPlayer = AudioPlayer();
    _boopPlayer.setPlayerMode(PlayerMode.lowLatency);
  }
  Timer? _gameLoopTimer;
  static const double _initialBallSpeed = 4.0;
  static const double _maxBallSpeed = 10.0;
  static const double _speedIncreaseFactor = 1.05; // 5% increase per bounce
  static const double _paddleSpeed = 6.0;
  static const double _paddlePadding = 20.0; // Padding from screen edges
  static const double _topPaddlePaddingFriend =
      80.0; // Extra padding for top paddle in friend mode to avoid appbar

  late AudioPlayer _boopPlayer;

  @override
  Future<void> close() {
    _gameLoopTimer?.cancel();
    _boopPlayer.dispose();
    return super.close();
  }

  Future<void> _playBoop() async {
    try {
      await _boopPlayer.stop();
      await _boopPlayer.play(AssetSource('audio/boop.wav'));
    } catch (_) {}
  }

  void startGame() {
    if (state.status == PaddleBounceGameStatus.waiting) {
      final random = math.Random();
      final angle =
          (random.nextDouble() * math.pi / 3) + math.pi / 6; // 30-90 degrees
      final direction = random.nextBool() ? 1 : -1;

      emit(state.copyWith(
        status: PaddleBounceGameStatus.playing,
        ball: state.ball.copyWith(
          velocityX: direction * _initialBallSpeed * math.cos(angle),
          velocityY: _initialBallSpeed * math.sin(angle),
        ),
      ));
      // no sound for game_start
    }
  }

  void pauseGame() {
    if (state.status == PaddleBounceGameStatus.playing) {
      emit(state.copyWith(status: PaddleBounceGameStatus.paused));
    } else if (state.status == PaddleBounceGameStatus.paused) {
      emit(state.copyWith(status: PaddleBounceGameStatus.playing));
    }
  }

  void moveTopPaddle(double deltaX) {
    if (state.status != PaddleBounceGameStatus.playing) return;

    // deltaX is difference from last touch position, multiply by screen width and speed factor
    // Use smoother movement with interpolation for better control
    final movementSpeed = _paddleSpeed * 0.4; // Increased for smoother response
    final newX =
        (state.topPaddle.x + deltaX * state.screenWidth * movementSpeed).clamp(
            _paddlePadding,
            state.screenWidth - state.topPaddle.width - _paddlePadding);

    // Reduced threshold for smoother updates
    if ((newX - state.topPaddle.x).abs() > 0.05) {
      emit(state.copyWith(
        topPaddle: state.topPaddle.copyWith(x: newX),
      ));
    }
  }

  void moveBottomPaddle(double deltaX) {
    if (state.status != PaddleBounceGameStatus.playing) return;

    // deltaX is difference from last touch position, multiply by screen width and speed factor
    // Use smoother movement with interpolation for better control
    final movementSpeed = _paddleSpeed * 0.4; // Increased for smoother response
    final newX =
        (state.bottomPaddle.x + deltaX * state.screenWidth * movementSpeed)
            .clamp(_paddlePadding,
                state.screenWidth - state.bottomPaddle.width - _paddlePadding);

    // Reduced threshold for smoother updates
    if ((newX - state.bottomPaddle.x).abs() > 0.05) {
      emit(state.copyWith(
        bottomPaddle: state.bottomPaddle.copyWith(x: newX),
      ));
    }
  }

  void _updateGame() {
    if (state.status != PaddleBounceGameStatus.playing) return;

    // Update AI paddle if in AI mode
    if (state.gameMode == PaddleBounceGameMode.vsAI) {
      _updateAIPaddle();
    }

    // Update ball position
    var newBallX = state.ball.x + state.ball.velocityX;
    var newBallY = state.ball.y + state.ball.velocityY;
    var newVelocityX = state.ball.velocityX;
    var newVelocityY = state.ball.velocityY;
    var newPlayer1Score = state.player1Score;
    var newPlayer2Score = state.player2Score;
    var newStatus = state.status;
    var newWinner = state.winner;

    // Check wall collisions (left and right) - account for padding
    if (newBallX - state.ball.radius <= _paddlePadding ||
        newBallX + state.ball.radius >= state.screenWidth - _paddlePadding) {
      newVelocityX = -newVelocityX;
      newBallX = newBallX.clamp(
        state.ball.radius + _paddlePadding,
        state.screenWidth - state.ball.radius - _paddlePadding,
      );
      _playBoop();
    }

    // Check top paddle collision (account for padding from top)
    // Use extra padding for friend mode to avoid appbar overlap
    final topPaddlePadding = state.gameMode == PaddleBounceGameMode.vsFriend
        ? _topPaddlePaddingFriend
        : _paddlePadding;

    if (newBallY - state.ball.radius <=
            state.topPaddle.height + topPaddlePadding &&
        newBallY - state.ball.radius >= topPaddlePadding &&
        newBallX >= state.topPaddle.x &&
        newBallX <= state.topPaddle.x + state.topPaddle.width) {
      final hitPosition = newBallX - state.topPaddle.x;
      final angle =
          state.ball.calculateBounceAngle(hitPosition, state.topPaddle.width);
      final currentSpeed =
          math.sqrt(newVelocityX * newVelocityX + newVelocityY * newVelocityY);
      // Increase speed on each bounce up to max
      final nextSpeed = (currentSpeed * _speedIncreaseFactor)
          .clamp(_initialBallSpeed, _maxBallSpeed);

      newVelocityX = nextSpeed * math.sin(angle);
      newVelocityY = nextSpeed * math.cos(angle);
      newBallY = state.topPaddle.height + state.ball.radius + topPaddlePadding;
      _playBoop();
    }

    // Check bottom paddle collision (account for padding from bottom)
    if (newBallY + state.ball.radius >=
            state.screenHeight - state.bottomPaddle.height - _paddlePadding &&
        newBallY + state.ball.radius <= state.screenHeight - _paddlePadding &&
        newBallX >= state.bottomPaddle.x &&
        newBallX <= state.bottomPaddle.x + state.bottomPaddle.width) {
      final hitPosition = newBallX - state.bottomPaddle.x;
      final angle = state.ball
          .calculateBounceAngle(hitPosition, state.bottomPaddle.width);
      final currentSpeed =
          math.sqrt(newVelocityX * newVelocityX + newVelocityY * newVelocityY);
      // Increase speed on each bounce up to max
      final nextSpeed = (currentSpeed * _speedIncreaseFactor)
          .clamp(_initialBallSpeed, _maxBallSpeed);

      newVelocityX = nextSpeed * math.sin(angle);
      newVelocityY = -nextSpeed * math.cos(angle);
      newBallY = state.screenHeight -
          state.bottomPaddle.height -
          state.ball.radius -
          _paddlePadding;
      _playBoop();
    }

    // Check scoring (account for paddle padding)
    // Use extra padding for friend mode to avoid appbar overlap
    final topPaddlePaddingForScoring =
        state.gameMode == PaddleBounceGameMode.vsFriend
            ? _topPaddlePaddingFriend
            : _paddlePadding;

    if (newBallY - state.ball.radius < topPaddlePaddingForScoring) {
      // Player 1 (bottom) scores
      newPlayer1Score = state.player1Score + 1;
      _playBoop();
      if (newPlayer1Score >= state.winningScore) {
        newStatus = PaddleBounceGameStatus.gameOver;
        newWinner = 1;
        // Emit game over state
        emit(state.copyWith(
          player1Score: newPlayer1Score,
          player2Score: newPlayer2Score,
          status: newStatus,
          winner: newWinner,
        ));
        // no sound for game_win
        return;
      } else {
        // Emit score update first, then reset ball
        emit(state.copyWith(
          player1Score: newPlayer1Score,
          player2Score: newPlayer2Score,
        ));
        _resetBallAfterScore();
        return;
      }
    } else if (newBallY + state.ball.radius >
        state.screenHeight - _paddlePadding) {
      // Player 2 (top) scores
      newPlayer2Score = state.player2Score + 1;
      _playBoop();
      if (newPlayer2Score >= state.winningScore) {
        newStatus = PaddleBounceGameStatus.gameOver;
        newWinner = 2;
        // Emit game over state
        emit(state.copyWith(
          player1Score: newPlayer1Score,
          player2Score: newPlayer2Score,
          status: newStatus,
          winner: newWinner,
        ));
        // no sound for game_win
        return;
      } else {
        // Emit score update first, then reset ball
        emit(state.copyWith(
          player1Score: newPlayer1Score,
          player2Score: newPlayer2Score,
        ));
        _resetBallAfterScore();
        return;
      }
    }

    emit(state.copyWith(
      ball: state.ball.copyWith(
        x: newBallX,
        y: newBallY,
        velocityX: newVelocityX,
        velocityY: newVelocityY,
      ),
      player1Score: newPlayer1Score,
      player2Score: newPlayer2Score,
      status: newStatus,
      winner: newWinner,
    ));
  }

  void _updateAIPaddle() {
    final aiPaddle = state.topPaddle;
    final ballX = state.ball.x;
    final targetX = ballX - aiPaddle.width / 2;

    // AI difficulty affects reaction speed and accuracy
    final reactionDelay = state.aiDifficulty == AIDifficulty.easy ? 0.7 : 0.95;
    final accuracy = state.aiDifficulty == AIDifficulty.easy ? 0.8 : 0.98;

    final currentCenter = aiPaddle.x + aiPaddle.width / 2;
    final distance = targetX - currentCenter;
    final moveDistance = distance * reactionDelay * accuracy;

    // Scale AI reaction speed based on current ball speed to keep it challenging
    final currentBallSpeed = math.sqrt(
        state.ball.velocityX * state.ball.velocityX +
            state.ball.velocityY * state.ball.velocityY);
    final speedMultiplier =
        (currentBallSpeed / _initialBallSpeed).clamp(1.0, 1.5);

    final newX = (aiPaddle.x + moveDistance * 0.3 * speedMultiplier).clamp(
        _paddlePadding, state.screenWidth - aiPaddle.width - _paddlePadding);

    if ((newX - aiPaddle.x).abs() > 0.5) {
      emit(state.copyWith(
        topPaddle: aiPaddle.copyWith(x: newX),
      ));
    }
  }

  void _resetBallAfterScore() {
    emit(state.copyWith(
      ball: state.ball.copyWith(
        x: state.screenWidth / 2,
        y: state.screenHeight / 2,
        velocityX: 0,
        velocityY: 0,
      ),
      status: PaddleBounceGameStatus.waiting,
    ));
    // Don't auto-start - wait for user to tap
  }

  void resetGame() {
    emit(PaddleBounceState.initial(
      gameMode: state.gameMode,
      aiDifficulty: state.aiDifficulty,
      screenWidth: state.screenWidth,
      screenHeight: state.screenHeight,
      winningScore: state.winningScore,
    ));
  }
}
