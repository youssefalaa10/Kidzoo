import 'dart:async';

import 'package:flame/components.dart';
import 'package:kidzo/core/utils/assets.dart';

class Background extends SpriteComponent {
  Background(Vector2 size) : super(size: size, position: Vector2(0, 0));

  @override
  FutureOr<void> onLoad() async {
    sprite = await Sprite.load(Assets.genImagesFlappyBackgroundflappy);
  }
}
