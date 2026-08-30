import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../color_switch_game.dart';

class ColorSwitcher extends PositionComponent with HasGameRef<ColorSwitchGame> {
  ColorSwitcher({
    required super.position,
    this.radius = 15,
  }) : super(
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  final double radius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw a ball with 4 colors
    final colors = gameRef.gameColors;
    if (colors.isEmpty) return;

    final sweepAngle = (math.pi * 2) / colors.length;
    for (int i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: (size / 2).toOffset(), radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        Paint()..color = colors[i],
      );
    }
  }
}
