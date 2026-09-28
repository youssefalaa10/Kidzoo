import 'dart:math' as math;

import '../models/paddle_bounce_models.dart';

/// The opponent paddle's brain, kept apart from the game loop so it can be
/// driven frame by frame in a test instead of only through a `Timer`.
///
/// It owns the little bit of state a believable handicap needs: when the
/// current rally started, and the single aim mistake it will make during it.
class PaddleAi {
  PaddleAi({required this.difficulty, math.Random? random})
      : _random = random ?? math.Random();

  final AIDifficulty difficulty;
  final math.Random _random;

  AiProfile get profile => AiProfile.byDifficulty[difficulty]!;

  double _rallyAimError = 0;
  int _framesSinceApproach = 0;
  int _lastBallDirection = 0;

  /// Aim error currently in play, in pixels. Exposed for tests and debugging.
  double get rallyAimError => _rallyAimError;

  void resetRally() {
    _rallyAimError = 0;
    _framesSinceApproach = 0;
    _lastBallDirection = 0;
  }

  /// The paddle's new left edge for this frame.
  double nextPaddleX({
    required double paddleX,
    required double paddleWidth,
    required double paddleHeight,
    required Ball ball,
    required double screenWidth,
    required double paddlePadding,
    required double maxBallSpeed,
    required double baseBallSpeed,
    required double basePaddleSpeed,
  }) {
    final halfWidth = paddleWidth / 2;
    final approaching = ball.velocityY < 0;
    final direction = approaching ? -1 : 1;

    if (direction != _lastBallDirection) {
      _lastBallDirection = direction;
      _framesSinceApproach = 0;
      if (approaching) {
        // One mistake per rally, scaled to the paddle so it means the same
        // thing on a phone and on a tablet.
        _rallyAimError = (_random.nextDouble() * 2 - 1) *
            profile.aimErrorHalfWidths *
            halfWidth;
      }
    } else if (approaching) {
      _framesSinceApproach++;
    }

    final centre = screenWidth / 2;
    double targetCentreX;

    if (!approaching) {
      // Drift back towards the middle rather than shadowing a ball that is
      // moving away; the old easy AI stayed glued to it and so was never out
      // of position when the ball came back.
      targetCentreX =
          centre + (ball.x - centre) * (1 - profile.centeringWhenIdle);
    } else if (_framesSinceApproach < profile.reactionFrames) {
      targetCentreX = paddleX + halfWidth;
    } else {
      final ballSpeed = math.sqrt(
          ball.velocityX * ball.velocityX + ball.velocityY * ball.velocityY);
      final speedRatio = maxBallSpeed <= 0 ? 0.0 : ballSpeed / maxBallSpeed;
      final targetY = paddleHeight + paddlePadding + ball.radius;

      if (profile.predictBouncesBelowSpeedRatio <= 0) {
        // No trajectory model: easy watches where the ball is right now,
        // medium extrapolates a short way ahead.
        targetCentreX = difficulty == AIDifficulty.easy
            ? ball.x
            : ball.x + ball.velocityX * 10;
      } else {
        targetCentreX = predictBallXAtY(
          startX: ball.x,
          startY: ball.y,
          velX: ball.velocityX,
          velY: ball.velocityY,
          targetY: targetY,
          leftWall: paddlePadding + ball.radius,
          rightWall: screenWidth - paddlePadding - ball.radius,
          // A fast smash outruns the AI's read of the walls, which is the
          // skill-based way through hard.
          reflectWalls: speedRatio <= profile.predictBouncesBelowSpeedRatio,
        );
      }

      targetCentreX += _rallyAimError;
    }

    // Expert deliberately meets the ball off-centre to return sharp angles.
    if (difficulty == AIDifficulty.expert && approaching) {
      if ((paddleX + halfWidth - targetCentreX).abs() < 30) {
        targetCentreX +=
            ball.x < centre ? paddleWidth * 0.3 : -paddleWidth * 0.3;
      }
    }

    var deltaX = (targetCentreX - halfWidth) - paddleX;

    // Only the higher tiers speed up as the ball does. Easy staying slow is
    // the point: a quick rally should be hard for the AI too.
    final ballSpeed = math.sqrt(
        ball.velocityX * ball.velocityX + ball.velocityY * ball.velocityY);
    final speedMultiplier = 1 +
        ((ballSpeed / baseBallSpeed).clamp(1.0, 2.0) - 1) *
            profile.ballSpeedBoost;
    final maxStep = basePaddleSpeed * profile.maxSpeedFactor * speedMultiplier;

    if (deltaX.abs() > maxStep) {
      deltaX = maxStep * deltaX.sign;
    }

    return (paddleX + deltaX)
        .clamp(paddlePadding, screenWidth - paddleWidth - paddlePadding);
  }
}
