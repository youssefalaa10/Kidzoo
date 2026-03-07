import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../color_switch_game.dart';
import 'circle_rotator.dart';
import 'color_switcher.dart';
import 'star_component.dart';
import 'ground.dart';

class Player extends PositionComponent with HasGameRef<ColorSwitchGame> {
  Player({
    required super.position,
    this.playerRadius = 15,
  }) {
    color = Colors.yellowAccent; // Temporary default
  }

  final _velocity = Vector2.zero();
  final _gravity = 980.0;
  final _jumpSpeed = 350.0;

  final double playerRadius;
  late Color color;

  Vector2 _startPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2.all(playerRadius * 2);
    anchor = Anchor.center;
    _startPosition = position.clone();
  }

  void resetPosition() {
    position = _startPosition.clone();
    _velocity.setValues(0, 0);
    changeColorRandomly();
  }

  void changeColorRandomly() {
    final oldColor = color;
    List<Color> possible =
        gameRef.gameColors.where((c) => c != oldColor).toList();
    if (possible.isEmpty) possible = gameRef.gameColors;
    possible.shuffle();
    color = possible.first;
    gameRef.updateColorName();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.isStarted) return;

    position += _velocity * dt;

    final groundList = gameRef.world.children.whereType<Ground>();
    if (groundList.isNotEmpty) {
      final ground = groundList.first;
      if (positionOfAnchor(Anchor.bottomCenter).y > ground.position.y) {
        _velocity.setValues(0, 0);
        position = Vector2(position.x, ground.position.y - (height / 2));
      } else {
        _velocity.y += _gravity * dt;
      }
    } else {
      _velocity.y += _gravity * dt;
    }

    _checkCollisions();
    gameRef.checkAndGenerateMore();
  }

  void _checkCollisions() {
    // Check stars
    final stars = gameRef.world.children.whereType<StarComponent>().toList();
    for (var star in stars) {
      if (position.distanceTo(star.position) < playerRadius + star.radius) {
        star.removeFromParent();
        gameRef.incrementScore();
      }
    }

    // Check color switchers
    final switchers =
        gameRef.world.children.whereType<ColorSwitcher>().toList();
    for (var switcher in switchers) {
      if (position.distanceTo(switcher.position) <
          playerRadius + switcher.radius) {
        switcher.removeFromParent();
        changeColorRandomly();
      }
    }

    // Check circle rotators
    final rotators = gameRef.world.children.whereType<CircleRotator>().toList();
    for (var rotator in rotators) {
      final distance = position.distanceTo(rotator.position);
      final ringRadius = rotator.size.x / 2;
      final touchMargin = playerRadius + rotator.thickness / 2;

      if ((distance - ringRadius).abs() < touchMargin) {
        double angle = math.atan2(
            position.y - rotator.position.y, position.x - rotator.position.x);

        while (angle < 0) angle += 2 * math.pi;
        while (angle >= 2 * math.pi) angle -= 2 * math.pi;

        double relativeAngle = angle - rotator.angle;
        while (relativeAngle < 0) relativeAngle += 2 * math.pi;
        while (relativeAngle >= 2 * math.pi) relativeAngle -= 2 * math.pi;

        final circle = math.pi * 2;
        final sweep = circle / gameRef.gameColors.length;
        int arcIndex = (relativeAngle / sweep).floor();

        if (arcIndex >= 0 && arcIndex < gameRef.gameColors.length) {
          Color arcColor = gameRef.gameColors[arcIndex];
          if (arcColor != color) {
            gameRef.gameOver();
          }
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      (size / 2).toOffset(),
      playerRadius,
      Paint()..color = color,
    );
  }

  void jump() {
    _velocity.y = -_jumpSpeed;
  }
}
