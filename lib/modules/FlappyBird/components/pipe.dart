import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:kidzoo/modules/FlappyBird/flappy_bird_game.dart';

class Pipe extends SpriteComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  final bool isUpPipe;
  bool isScored = false;

  Pipe(Vector2 position, Vector2 size, {required this.isUpPipe})
      : super(position: position, size: size);

  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load(
        isUpPipe ? "flappy/pipedown.png" : "flappy/pipeup.png");
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    position.x -= 200 * dt;

    //check if bird has passed the pipe
    if (!isScored && position.x + size.x < gameRef.bird.position.x) {
      isScored = true;
      // avoid double scoring

      if (isUpPipe) {
        gameRef.incrementScore();
      }
    }

    if (position.x + size.x <= 0) {
      removeFromParent();
    }
  }
}
