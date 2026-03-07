import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:kidzoo/core/utils/assets.dart';
import 'package:kidzoo/features/FlappyBird/components/flappygame_constants.dart';
import 'package:kidzoo/features/FlappyBird/components/ground.dart';
import 'package:kidzoo/features/FlappyBird/components/pipe.dart';
import 'package:kidzoo/features/FlappyBird/flappy_bird_game.dart';

class Bird extends SpriteComponent with CollisionCallbacks {
/*
Init Bird

 */
// Initlize bird position & size
  Bird()
      : super(
            position: Vector2(birdStartX, birdStartY),
            size: Vector2(birdWidth, birdHeight));

  //physical world properties
  double velocity = 0;

  /*
  Load
   */

  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load(Assets.genImagesFlappyFlappybird);

    add(RectangleHitbox());
  }

  /* 
  Jump/flap
  */

  void flap() {
    velocity = jumpStrength;
    (parent as FlappyBirdGame).playFlap();
  }

  /*
  Update -> every second
   */

  @override
  void update(double dt) {
    // Only apply physics if the game is playing
    final game = parent as FlappyBirdGame;
    if (game.gameState == GameState.playing) {
      //apply gravity
      velocity += gravity * dt;

      //update bird's position based on current velocity
      position.y += velocity * dt;

      // Prevent bird from going above screen
      if (position.y < 0) {
        position.y = 0;
        velocity = 0;
      }
    }
  }

  //Closision

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ground) {
      (parent as FlappyBirdGame).gameOver();
    }

    if (other is Pipe) {
      (parent as FlappyBirdGame).gameOver();
    }
  }
}
