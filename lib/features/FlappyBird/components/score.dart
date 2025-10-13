import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:kidzoo/features/FlappyBird/flappy_bird_game.dart';

class ScoreText extends TextComponent with HasGameRef<FlappyBirdGame> {
  ScoreText()
      : super(
            text: '0',
            anchor: Anchor.topCenter,
            textRenderer: TextPaint(
                style: const TextStyle(
                    fontSize: 60,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                  Shadow(
                    offset: Offset(3, 3),
                    blurRadius: 5,
                  ),
                ])));

  @override
  FutureOr<void> onLoad() {
    // set the position to top center
    position = Vector2(gameRef.size.x / 2, 50);
  }

  //update score
  @override
  void update(double dt) {
    final neWtext = gameRef.score.toString();
    if (text != neWtext) {
      text = neWtext;
    }
  }
}
