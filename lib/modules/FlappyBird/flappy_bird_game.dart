import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:kidzoo/modules/FlappyBird/components/background.dart';
import 'package:kidzoo/modules/FlappyBird/components/bird.dart';
import 'package:kidzoo/modules/FlappyBird/components/flappygame_constants.dart';
import 'package:kidzoo/modules/FlappyBird/components/pipemanager.dart';

import 'components/ground.dart';
import 'components/pipe.dart';

class FlappyBirdGame extends FlameGame with TapDetector, HasCollisionDetection {
  /* 
  Basic Game Componenets:
  -bird
  -background
  -ground
  -pipes
  -score
  
   */

  late Bird bird;
  late Background background;
  late Ground ground;
  late PipeManager pipeManager;

  @override
  FutureOr<void> onLoad() {
    background = Background(size);
    add(background);
    bird = Bird();
    add(bird);
    ground = Ground();
    add(ground);
    pipeManager = PipeManager();
    add(pipeManager);
  }

  @override
  void onTap() {
    bird.flap();
  }

  /*
  
  Game Over  
  */

  bool isGameOver = false;
  void gameOver() {
    if (isGameOver) return;

    isGameOver = true;
    pauseEngine();
    //show Dialog Box to restart

    showDialog(
        barrierDismissible: false,
        context: buildContext!,
        builder: (context) => AlertDialog(
              title: const Text("Game Over"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    resetGame();
                  },
                  child: Text(
                    "Restart",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ));
  }

  void resetGame() {
    bird.position = Vector2(birdStartX, birdStartY);
    bird.velocity = 0;
    isGameOver = false;
    //
    children.whereType<Pipe>().forEach((pipe) => pipe.removeFromParent());
    resumeEngine();
  }
}
