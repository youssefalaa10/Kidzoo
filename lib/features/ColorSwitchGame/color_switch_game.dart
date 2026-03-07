import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/player.dart';
import 'components/ground.dart';
import 'components/circle_rotator.dart';
import 'components/color_switcher.dart';
import 'components/star_component.dart';

class ColorSwitchGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  late Player myPlayer;
  late TextComponent colorNameText;
  late TextComponent scoreText;
  late TextComponent startText;

  bool isGameOver = false;
  bool isStarted = false;
  int score = 0;

  final List<Color> gameColors = const [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.yellowAccent,
  ];

  final Map<Color, String> colorNames = {
    Colors.redAccent: 'Red',
    Colors.greenAccent: 'Green',
    Colors.blueAccent: 'Blue',
    Colors.yellowAccent: 'Yellow',
  };

  ColorSwitchGame() : super();

  @override
  Color backgroundColor() => const Color(0xff222222);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // Add ground
    world.add(Ground(position: Vector2(size.x / 2, size.y - 100)));

    // Add player
    myPlayer = Player(position: Vector2(size.x / 2, size.y - 250));
    world.add(myPlayer);

    // Initial color
    final initialColors = gameColors.toList()..shuffle();
    myPlayer.color = initialColors.first;

    // UI overlays
    colorNameText = TextComponent(
      text: colorNames[myPlayer.color]!,
      position: Vector2(size.x / 2, 50),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          color: myPlayer.color,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(colorNameText);

    scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(20, 50),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    startText = TextComponent(
      text: 'Tap to Start!',
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(startText);

    generateGameComponents();
  }

  void updateColorName() {
    try {
      if (!isLoaded) return;
      colorNameText.text = colorNames[myPlayer.color] ?? 'Unknown';
      colorNameText.textRenderer = TextPaint(
        style: TextStyle(
          color: myPlayer.color,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      );
    } catch (_) {}
  }

  void incrementScore() {
    score++;
    scoreText.text = 'Score: $score';
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isStarted) return;
    final cameraY = camera.viewfinder.position.y;
    final playerY = myPlayer.position.y;

    if (playerY < cameraY + size.y / 2) {
      camera.viewfinder.position = Vector2(0, playerY - size.y / 2);
    }

    if (playerY > camera.viewfinder.position.y + size.y) {
      gameOver();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) {
      return;
    }
    if (!isStarted) {
      isStarted = true;
      startText.removeFromParent();
      myPlayer.jump();
    } else {
      myPlayer.jump();
    }
    super.onTapDown(event);
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    pauseEngine();

    showDialog<void>(
      barrierDismissible: false,
      context: buildContext!,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.orange.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Game Over!',
          style: TextStyle(
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
              'Score: $score',
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
              child: const Text(
                'Play Again',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    score = 0;
    scoreText.text = 'Score: 0';

    final rotators = world.children.whereType<CircleRotator>().toList();
    for (var r in rotators) {
      r.removeFromParent();
    }

    final switchers = world.children.whereType<ColorSwitcher>().toList();
    for (var s in switchers) {
      s.removeFromParent();
    }

    final stars = world.children.whereType<StarComponent>().toList();
    for (var s in stars) {
      s.removeFromParent();
    }

    myPlayer.resetPosition();
    camera.viewfinder.position = Vector2(0, 0);
    generateGameComponents();

    isStarted = false;
    isGameOver = false;

    add(startText);

    resumeEngine();
  }

  double lastComponentY = 100;

  void generateGameComponents() {
    lastComponentY = size.y / 2 - 200;
    for (int i = 0; i < 5; i++) {
      _generateBlock(lastComponentY - 400);
      lastComponentY -= 400;
    }
  }

  void checkAndGenerateMore() {
    if (myPlayer.position.y < lastComponentY + 800) {
      for (int i = 0; i < 5; i++) {
        _generateBlock(lastComponentY - 400);
        lastComponentY -= 400;
      }
    }
  }

  void _generateBlock(double yPos) {
    world.add(CircleRotator(
      position: Vector2(size.x / 2, yPos),
      size: Vector2(200, 200),
    ));

    world.add(StarComponent(
      position: Vector2(size.x / 2, yPos),
    ));

    world.add(ColorSwitcher(
      position: Vector2(size.x / 2, yPos - 200),
    ));
  }
}
