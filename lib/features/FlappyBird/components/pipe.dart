import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:kidzo/core/utils/assets.dart';
import 'package:kidzo/features/FlappyBird/flappy_bird_game.dart';

class Pipe extends SpriteComponent
    with HasGameRef<FlappyBirdGame>, CollisionCallbacks {
  Pipe(Vector2 position, Vector2 size, {required this.isUpPipe})
      : super(position: position, size: size);
  final bool isUpPipe;
  bool isScored = false;

  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load(isUpPipe
        ? Assets.genImagesFlappyPipedown
        : Assets.genImagesFlappyPipeup);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    // Only move pipes when game is playing
    if (gameRef.gameState == GameState.playing) {
      position.x -= gameRef.currentPipeSpeed * dt;

      //check if bird has passed the pipe
      if (!isScored && position.x + size.x < gameRef.bird.position.x) {
        isScored = true;
        // avoid double scoring
        if (isUpPipe) {
          gameRef.incrementScore();
          gameRef.playScore();
        }
      }

      if (position.x + size.x <= 0) {
        removeFromParent();
      }
    }
  }
}
