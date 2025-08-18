import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../flappy_bird_game.dart';

class Ground extends SpriteComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  Ground() : super();

  @override
  FutureOr<void> onLoad() async {
    size = Vector2(2 * gameRef.size.x, 200);
    position = Vector2(0, gameRef.size.y - size.y);
    sprite = await Sprite.load('flappy/groundflappy.png');

    // add Collision Box
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    position.x -= 100 * dt;

    if (position.x + size.x / 2 <= 0) {
      position.x = 0;
    }
  }
}
