import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../color_switch_game.dart';

class CircleRotator extends PositionComponent with HasGameRef<ColorSwitchGame> {
  CircleRotator({
    required super.position,
    required Vector2 size,
    this.thickness = 16.0,
    this.rotationSpeed = 1.0,
  })  : assert(size.x == size.y),
        super(size: size, anchor: Anchor.center);

  final double thickness;
  final double rotationSpeed;

  @override
  void onLoad() {
    super.onLoad();

    const circleAngle = math.pi * 2;
    final sweep = circleAngle / gameRef.gameColors.length;
    for (int i = 0; i < gameRef.gameColors.length; i++) {
      add(CircleArc(
        color: gameRef.gameColors[i],
        startAngle: i * sweep,
        sweepAngle: sweep,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle += rotationSpeed * dt;
    angle %= math.pi * 2;
  }
}

class CircleArc extends PositionComponent with ParentIsA<CircleRotator> {

  CircleArc({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
  }) : super(anchor: Anchor.center);
  final Color color;
  final double startAngle;
  final double sweepAngle;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = parent.size;
    position = size / 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawArc(
      size.toRect().deflate(parent.thickness / 2),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = parent.thickness,
    );
  }
}
