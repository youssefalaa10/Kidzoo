import 'dart:math' as math;

/// Game mode: Friend (two players) or AI (single player)
enum PaddleBounceGameMode {
  vsFriend,
  vsAI,
}

/// AI difficulty levels
enum AIDifficulty {
  easy,
  hard,
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
    final normalized = (hitPosition - paddleWidth / 2) / (paddleWidth / 2);
    // Return angle in radians (max 60 degrees)
    return normalized * math.pi / 3;
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
