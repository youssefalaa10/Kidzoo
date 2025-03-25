import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:kidzoo/modules/FlappyBird/flappy_bird_game.dart';

class ScoreText extends TextComponent with HasGameRef<FlappyBirdGame> {
  ScoreText()
      : super(
            text: "0",
            textRenderer:
                TextPaint(style: TextStyle(fontSize: 40, color: Colors.white)));

  @override
  FutureOr<void> onLoad() {
    // set the position to lower middle
    position = Vector2(gameRef.size.x / 2, gameRef.size.y - 50);
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
