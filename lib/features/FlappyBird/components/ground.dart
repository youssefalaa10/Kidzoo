import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:kidzo/core/utils/assets.dart';

import '../flappy_bird_game.dart';

class Ground extends SpriteComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  Ground() : super();

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    final gHeight = gameSize.x > gameSize.y ? gameSize.y * 0.10 : gameSize.y * 0.15;
    size = Vector2(2 * gameSize.x, gHeight);
    position = Vector2(0, gameSize.y - gHeight);
  }

  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load(Assets.genImagesFlappyGroundflappy);

    // add Collision Box
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    // Only move ground when game is playing
    if (gameRef.gameState == GameState.playing) {
      position.x -= gameRef.currentGroundSpeed * dt;

      if (position.x + size.x / 2 <= 0) {
        position.x = 0;
      }
    }
  }
}
