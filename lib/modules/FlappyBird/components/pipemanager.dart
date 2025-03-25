import 'dart:math';

import 'package:flame/components.dart';
import 'package:kidzoo/modules/FlappyBird/components/pipe.dart';
import 'package:kidzoo/modules/FlappyBird/flappy_bird_game.dart';

class PipeManager extends Component with HasGameRef<FlappyBirdGame> {
  double pipeSpawnTimer = 0;

  @override
  void update(double dt) {
    pipeSpawnTimer += dt;
    const double pipeInterval = 2;

    if (pipeSpawnTimer > pipeInterval) {
      pipeSpawnTimer = 0;
      spwanPipe();
    }
  }

  void spwanPipe() {
    final double screenHeight = gameRef.size.y;
    const double pipeGap = 200;
    const double minPipeHeight = 50;
    const double pipeWidth = 60;

    //Calculate pipe heights
    final double maxPipeHeight = screenHeight - 200 - pipeGap - minPipeHeight;
    //height of bottom pipe -> randomly select between min and max

    final double bottomPipeHeight =
        minPipeHeight + Random().nextDouble() * (maxPipeHeight - minPipeHeight);

    final double topPipeHeight =
        screenHeight - 200 - bottomPipeHeight - pipeGap;

    final bottomPipe = Pipe(
        Vector2(gameRef.size.x, screenHeight - 200 - bottomPipeHeight),
        Vector2(pipeWidth, bottomPipeHeight),
        isUpPipe: false);

    final topPipe = Pipe(
        Vector2(gameRef.size.x, 0), Vector2(pipeWidth, topPipeHeight),
        isUpPipe: true);

    gameRef.add(bottomPipe);
    gameRef.add(topPipe);
  }
}
