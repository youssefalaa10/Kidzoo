import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Ground extends PositionComponent {
  Ground({required super.position})
      : super(
          size: Vector2(200, 2),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    // Optionally render a line or nothing
  }
}
