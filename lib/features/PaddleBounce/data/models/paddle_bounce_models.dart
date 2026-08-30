import 'dart:math' as math;

/// Game mode: Friend (two players) or AI (single player)
enum PaddleBounceGameMode {
  vsFriend,
  vsAI,
}

/// AI difficulty levels
enum AIDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Game status
enum PaddleBounceGameStatus {
  waiting,
  playing,
  paused,
  gameOver,
}

/// Ball model
class Ball {
  Ball({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    this.radius = 10.0,
  });

  final double x;
  final double y;
  final double velocityX;
  final double velocityY;
  final double radius;

  Ball copyWith({
    double? x,
    double? y,
    double? velocityX,
    double? velocityY,
    double? radius,
  }) {
    return Ball(
      x: x ?? this.x,
      y: y ?? this.y,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      radius: radius ?? this.radius,
    );
  }

  /// Calculate angle based on hit position on paddle
  double calculateBounceAngle(double hitPosition, double paddleWidth) {
    // Normalize hit position to -1 to 1 (center is 0)
    // Clamp to [-1, 1] just in case ball overlaps edge slightly
    final normalized = ((hitPosition - paddleWidth / 2) / (paddleWidth / 2)).clamp(-1.0, 1.0);
    // Return angle in radians (max 70 degrees for sharper edge returns)
    return normalized * (math.pi * 70 / 180);
  }
}

/// Paddle model
class Paddle {
  Paddle({
    required this.x,
    required this.width,
    required this.height,
    this.speed = 5.0,
  });

  final double x;
  final double width;
  final double height;
  final double speed;

  Paddle copyWith({
    double? x,
    double? width,
    double? height,
    double? speed,
  }) {
    return Paddle(
      x: x ?? this.x,
      width: width ?? this.width,
      height: height ?? this.height,
      speed: speed ?? this.speed,
    );
  }
}


/// How a given [AIDifficulty] actually plays.
///
/// The previous AI expressed its handicap as `sin(clock) * pixels` added to the
/// ball position. A sine oscillates *around* the true value, so averaged over a
/// rally it cancels out and the paddle sits exactly on the ball - which is why
/// easy and medium were unbeatable. Worse, every level scaled its own top speed
/// up with the ball speed, so the AI got sharper precisely when the rally got
/// hard.
///
/// The handicap is now three separate, honest levers: it reacts late, it aims
/// at the wrong place by an amount drawn once per rally, and it only predicts
/// wall bounces while the ball is slow enough.
class AiProfile {
  const AiProfile({
    required this.maxSpeedFactor,
    required this.reactionFrames,
    required this.aimErrorHalfWidths,
    required this.centeringWhenIdle,
    required this.ballSpeedBoost,
    required this.predictBouncesBelowSpeedRatio,
  });

  /// Top paddle speed as a fraction of the base paddle speed.
  final double maxSpeedFactor;

  /// Frames the AI stays put after the ball turns towards it (~60fps).
  final int reactionFrames;

  /// Aim error drawn once per rally, measured in paddle half-widths. Above 1.0
  /// the AI can genuinely miss, and the miss rate is `1 - 1 / value`.
  final double aimErrorHalfWidths;

  /// How strongly it drifts back to the centre while the ball moves away.
  /// 1.0 returns fully to the middle, 0.0 stays where it is.
  final double centeringWhenIdle;

  /// How much its top speed scales with ball speed. 0 keeps a fast rally hard
  /// for the AI too.
  final double ballSpeedBoost;

  /// Full wall-bounce prediction is used only while the ball is slower than
  /// this fraction of the maximum speed; above it the AI falls back to a
  /// straight-line guess. Because the AI re-reads the ball every frame it
  /// still corrects late, so this shades the feel rather than deciding rallies
  /// - the aim error is what actually loses them.
  final double predictBouncesBelowSpeedRatio;

  /// Chance the aim error alone puts the ball past the paddle edge.
  double get theoreticalMissRate =>
      aimErrorHalfWidths <= 1 ? 0 : 1 - 1 / aimErrorHalfWidths;

  static const Map<AIDifficulty, AiProfile> byDifficulty = {
    // Reacts late, tracks only where the ball is right now, drifts back to the
    // middle between shots and misses roughly two rallies in five.
    AIDifficulty.easy: AiProfile(
      maxSpeedFactor: 0.32,
      reactionFrames: 22,
      aimErrorHalfWidths: 1.7,
      centeringWhenIdle: 1,
      ballSpeedBoost: 0,
      predictBouncesBelowSpeedRatio: 0,
    ),
    // Extrapolates in a straight line, keeps up with a normal rally, and gives
    // away roughly one point in seven.
    AIDifficulty.medium: AiProfile(
      maxSpeedFactor: 0.46,
      reactionFrames: 14,
      aimErrorHalfWidths: 1.45,
      centeringWhenIdle: 0.6,
      ballSpeedBoost: 0.2,
      predictBouncesBelowSpeedRatio: 0,
    ),
    // Reads bounces and saves ~94% of rallies in simulation: beatable over a
    // match, but it will punish loose play.
    AIDifficulty.hard: AiProfile(
      maxSpeedFactor: 0.76,
      reactionFrames: 6,
      aimErrorHalfWidths: 1.11,
      centeringWhenIdle: 0.3,
      ballSpeedBoost: 0.5,
      predictBouncesBelowSpeedRatio: 0.55,
    ),
    // Reads everything, all the time.
    AIDifficulty.expert: AiProfile(
      maxSpeedFactor: 1,
      reactionFrames: 0,
      aimErrorHalfWidths: 0.45,
      centeringWhenIdle: 0.15,
      ballSpeedBoost: 0.8,
      predictBouncesBelowSpeedRatio: 1.01,
    ),
  };
}

/// Where a ball launched from ([startX], [startY]) with velocity
/// ([velX], [velY]) crosses [targetY], reflecting off the side walls.
///
/// Set [reflectWalls] to false for a naive straight-line guess.
double predictBallXAtY({
  required double startX,
  required double startY,
  required double velX,
  required double velY,
  required double targetY,
  required double leftWall,
  required double rightWall,
  bool reflectWalls = true,
}) {
  if (velY == 0) return startX;

  final timeToReach = (targetY - startY) / velY;
  if (timeToReach <= 0) return startX;

  final projected = startX + velX * timeToReach;
  if (!reflectWalls) return projected.clamp(leftWall, rightWall);

  final width = rightWall - leftWall;
  if (width <= 0) return startX;

  // Fold the straight-line result back and forth between the walls.
  var folded = (projected - leftWall) % (2 * width);
  if (folded < 0) folded += 2 * width;
  if (folded > width) folded = 2 * width - folded;
  return folded + leftWall;
}
