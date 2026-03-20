import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:kidzoo/features/FlappyBird/components/background.dart';
import 'package:kidzoo/features/FlappyBird/components/bird.dart';
import 'package:kidzoo/features/FlappyBird/components/flappygame_constants.dart';
import 'package:kidzoo/features/FlappyBird/components/pipemanager.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';

import 'components/ground.dart';
import 'components/pipe.dart';
import 'components/score.dart';

enum GameState { waiting, playing, gameOver }

class FlappyBirdGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
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
  late ScoreText scoreText;
  late TextComponent startText;

  GameState gameState = GameState.waiting;

  final AudioPlayer _flapPlayer = AudioPlayer();
  final AudioPlayer _scorePlayer = AudioPlayer();

  Future<void> playFlap() async {
    try {
      await _flapPlayer.stop();
      await _flapPlayer.play(AssetSource('audio/boop.wav'));
    } catch (_) {}
  }

  Future<void> playScore() async {
    try {
      await _scorePlayer.stop();
      await _scorePlayer.play(AssetSource('audio/boop.wav'));
    } catch (_) {}
  }

  @override
  void onRemove() {
    _flapPlayer.dispose();
    _scorePlayer.dispose();
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await _flapPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _scorePlayer.setPlayerMode(PlayerMode.lowLatency);
    images.prefix = '';
    background = Background(size);
    add(background);
    bird = Bird();
    add(bird);
    ground = Ground();
    add(ground);
    pipeManager = PipeManager();
    add(pipeManager);
    scoreText = ScoreText();
    add(scoreText);

    // Add start instruction text
    startText = TextComponent(
      text: AppLocalizations.of(buildContext!).tapToStart,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 100),
    );
    add(startText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameState == GameState.waiting) {
      // Start the game on first tap
      gameState = GameState.playing;
      startText.removeFromParent();
      bird.flap();
    } else if (gameState == GameState.playing) {
      // Flap during gameplay
      bird.flap();
    }
  }

  /*
  Score
   */
  int score = 0;
  void incrementScore() {
    score++;
  }

  void resetScore() {
    score = 0;
  }

  /*
  
  Game Over  
  */

  void gameOver() {
    if (gameState == GameState.gameOver) return;
    gameState = GameState.gameOver;
    pauseEngine();

    //show Dialog Box to restart

    showDialog(
        barrierDismissible: false,
        context: buildContext!,
        builder: (context) => AlertDialog(
              backgroundColor: Colors.orange.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                AppLocalizations.of(context).gameOver,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${AppLocalizations.of(context).score}: $score',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).playAgain,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ));
  }

  void resetGame() {
    bird.position = Vector2(birdStartX, size.y / 2);
    bird.velocity = 0;
    resetScore();
    gameState = GameState.waiting;
    //
    children.whereType<Pipe>().forEach((pipe) => pipe.removeFromParent());

    // Re-add start text
    startText = TextComponent(
      text: AppLocalizations.of(buildContext!).tapToStart,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 48,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 100),
    );
    add(startText);

    resumeEngine();
  }
}
