import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:kidzoo/core/utils/assets.dart';
import 'package:kidzoo/features/FlappyBird/components/flappygame_constants.dart';

import '../flappy_bird_game.dart';

class Ground extends SpriteComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  Ground() : super();

  @override
  FutureOr<void> onLoad() async {
    size = Vector2(2 * gameRef.size.x, 200);
    position = Vector2(0, gameRef.size.y - size.y);
    sprite = await Sprite.load(Assets.genImagesFlappyGroundflappy);

    // add Collision Box
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    // Only move ground when game is playing
    if (gameRef.gameState == GameState.playing) {
      position.x -= groundSpeed * dt;

      if (position.x + size.x / 2 <= 0) {
        position.x = 0;
      }
    }
  }
}
