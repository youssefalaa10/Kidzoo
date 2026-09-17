import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/PaddleBounce/data/logic/paddle_ai.dart';
import 'package:kidzo/features/PaddleBounce/data/models/paddle_bounce_models.dart';

// Mirrors the constants the cubit runs with.
const double _screenWidth = 400;
const double _screenHeight = 780;
const double _paddlePadding = 20;
const double _paddleWidth = _screenWidth * 0.35;
const double _paddleHeight = 16;
const double _paddleSpeed = 6;
const double _initialBallSpeed = 4;
const double _maxBallSpeed = 10;
const double _ballRadius = 10;

/// Plays one rally: the ball leaves the player's end and travels to the AI,
/// bouncing off the side walls, while the AI paddle moves one frame at a time.
/// Returns true when the AI reaches it.
bool _aiSavesRally({
  required PaddleAi ai,
  required math.Random random,
  required double ballSpeed,
}) {
  final leftWall = _paddlePadding + _ballRadius;
  final rightWall = _screenWidth - _paddlePadding - _ballRadius;
  final hitY = _paddleHeight + _paddlePadding + _ballRadius;

  // Serve from a random spot along the player's paddle at a random angle.
  final angle = (random.nextDouble() * 2 - 1) * (math.pi * 65 / 180);
  var ball = Ball(
    x: leftWall + random.nextDouble() * (rightWall - leftWall),
    y: _screenHeight - _paddlePadding - _paddleHeight - _ballRadius,
    velocityX: ballSpeed * math.sin(angle),
    velocityY: -ballSpeed * math.cos(angle),
  );

  var paddleX = (_screenWidth - _paddleWidth) / 2;

  // Let the AI settle with the ball moving away first, as it would mid-match.
  for (var i = 0; i < 20; i++) {
    paddleX = _step(ai, paddleX, ball.copyWith(velocityY: ballSpeed));
  }

  for (var frame = 0; frame < 4000; frame++) {
    paddleX = _step(ai, paddleX, ball);

    var nextX = ball.x + ball.velocityX;
    var nextVelX = ball.velocityX;
    if (nextX <= leftWall || nextX >= rightWall) {
      nextVelX = -nextVelX;
      nextX = nextX.clamp(leftWall, rightWall);
    }
    final nextY = ball.y + ball.velocityY;

    if (nextY <= hitY) {
      return nextX >= paddleX && nextX <= paddleX + _paddleWidth;
    }
    ball = ball.copyWith(x: nextX, y: nextY, velocityX: nextVelX);
  }
  return true;
}

double _step(PaddleAi ai, double paddleX, Ball ball) => ai.nextPaddleX(
      paddleX: paddleX,
      paddleWidth: _paddleWidth,
      paddleHeight: _paddleHeight,
      ball: ball,
      screenWidth: _screenWidth,
      paddlePadding: _paddlePadding,
      maxBallSpeed: _maxBallSpeed,
      baseBallSpeed: _initialBallSpeed,
      basePaddleSpeed: _paddleSpeed,
    );

double _saveRate(AIDifficulty difficulty, {double ballSpeed = 6, int rallies = 400}) {
  final random = math.Random(4242);
  var saves = 0;
  for (var i = 0; i < rallies; i++) {
    final ai = PaddleAi(difficulty: difficulty, random: random);
    if (_aiSavesRally(ai: ai, random: random, ballSpeed: ballSpeed)) saves++;
  }
  return saves / rallies;
}

void main() {
  group('AI difficulty ladder', () {
    // Measured save rates with this profile set: easy 0.64, medium 0.81,
    // hard 0.94, expert ~1.00. The bounds below leave tuning room while
    // pinning the property that matters: the lower tiers must actually lose.
    test('easy loses often enough for a child to win', () {
      final rate = _saveRate(AIDifficulty.easy);
      expect(rate, lessThan(0.75), reason: 'easy saved $rate of rallies');
      expect(rate, greaterThan(0.25), reason: 'easy should still play, not gift');
    });

    test('medium is beatable but noticeably tighter than easy', () {
      final easy = _saveRate(AIDifficulty.easy);
      final medium = _saveRate(AIDifficulty.medium);
      expect(medium, greaterThan(easy));
      expect(medium, lessThan(0.88), reason: 'medium saved $medium of rallies');
    });

    test('hard is strong but can still be beaten', () {
      final medium = _saveRate(AIDifficulty.medium);
      final hard = _saveRate(AIDifficulty.hard);
      expect(hard, greaterThan(medium));
      expect(hard, lessThan(0.97), reason: 'hard saved $hard of rallies');
    });

    test('expert is the wall the others are not', () {
      final hard = _saveRate(AIDifficulty.hard);
      final expert = _saveRate(AIDifficulty.expert);
      expect(expert, greaterThan(hard));
      expect(expert, greaterThan(0.9));
    });

    test('difficulty ordering holds on every lever', () {
      const order = [
        AIDifficulty.easy,
        AIDifficulty.medium,
        AIDifficulty.hard,
        AIDifficulty.expert,
      ];
      for (var i = 1; i < order.length; i++) {
        final slower = AiProfile.byDifficulty[order[i - 1]]!;
        final faster = AiProfile.byDifficulty[order[i]]!;
        expect(faster.maxSpeedFactor, greaterThan(slower.maxSpeedFactor));
        expect(faster.reactionFrames, lessThan(slower.reactionFrames));
        expect(faster.aimErrorHalfWidths, lessThan(slower.aimErrorHalfWidths));
      }
    });

    test('easy and medium can genuinely miss on aim alone', () {
      expect(AiProfile.byDifficulty[AIDifficulty.easy]!.theoreticalMissRate,
          greaterThan(0.3));
      expect(AiProfile.byDifficulty[AIDifficulty.medium]!.theoreticalMissRate,
          greaterThan(0.1));
      expect(AiProfile.byDifficulty[AIDifficulty.expert]!.theoreticalMissRate, 0);
    });
  });

  group('Ball prediction', () {
    test('a straight vertical ball lands where it started', () {
      final x = predictBallXAtY(
        startX: 150,
        startY: 700,
        velX: 0,
        velY: -5,
        targetY: 50,
        leftWall: 30,
        rightWall: 370,
      );
      expect(x, closeTo(150, 0.001));
    });

    test('reflects off a wall instead of running past it', () {
      final x = predictBallXAtY(
        startX: 300,
        startY: 700,
        velX: 5,
        velY: -5,
        targetY: 500,
        leftWall: 30,
        rightWall: 370,
      );
      // Straight line would be 500; the right wall is at 370, so it folds back.
      expect(x, closeTo(370 - (500 - 370), 0.001));
      expect(x, inInclusiveRange(30, 370));
    });

    test('stays inside the walls over many bounces', () {
      final random = math.Random(9);
      for (var i = 0; i < 500; i++) {
        final x = predictBallXAtY(
          startX: 30 + random.nextDouble() * 340,
          startY: 760,
          velX: (random.nextDouble() * 2 - 1) * 9,
          velY: -(0.5 + random.nextDouble() * 9),
          targetY: 46,
          leftWall: 30,
          rightWall: 370,
        );
        expect(x, inInclusiveRange(30, 370));
      }
    });

    test('the naive mode ignores walls but stays clamped', () {
      final x = predictBallXAtY(
        startX: 300,
        startY: 700,
        velX: 9,
        velY: -1,
        targetY: 50,
        leftWall: 30,
        rightWall: 370,
        reflectWalls: false,
      );
      expect(x, 370);
    });
  });
}
