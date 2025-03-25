import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:kidzoo/modules/FlappyBird/components/flappygame_constants.dart';
import 'package:kidzoo/modules/FlappyBird/components/ground.dart';
import 'package:kidzoo/modules/FlappyBird/components/pipe.dart';
import 'package:kidzoo/modules/FlappyBird/flappy_bird_game.dart';

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
    sprite = await Sprite.load("flappy/flappybird.png");

    add(RectangleHitbox());
  }

  /* 
  Jump/flap
  */

  void flap() {
    velocity = jumpStrength;
  }

  /*
  Update -> every second
   */

  @override
  void update(double dt) {
    //apply gravity
    velocity += gravity * dt;

//update bird's position based on current velocity

    position.y += velocity * dt;
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
