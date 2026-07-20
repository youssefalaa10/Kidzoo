import 'dart:math';

import 'package:flame/components.dart';
import 'package:kidzo/features/FlappyBird/components/flappygame_constants.dart';
import 'package:kidzo/features/FlappyBird/components/pipe.dart';
import 'package:kidzo/features/FlappyBird/flappy_bird_game.dart';

class PipeManager extends Component with HasGameRef<FlappyBirdGame> {
  double pipeSpawnTimer = 0;

  @override
  void update(double dt) {
    // Only spawn pipes when game is playing
    if (gameRef.gameState == GameState.playing) {
      pipeSpawnTimer += dt;

      if (pipeSpawnTimer > pipeInterval) {
        pipeSpawnTimer = 0;
        spwanPipe();
      }
    }
  }

  void spwanPipe() {
    final double screenHeight = gameRef.size.y;
    final double groundHeight = gameRef.groundHeight;
    const double minPipeHeight = 50;
    const double pipeWidth = 60;

    final double availableHeight = screenHeight - groundHeight;

    double currentGap = gameRef.currentPipeGap;

    // To ensure pipes have enough room to vary vertically, maxPipeHeight - minPipeHeight should be at least 80 pixels.
    // We calculate a target gap to guarantee 80 pixels of vertical variation, without shrinking the gap too much.
    double targetMaxGap = availableHeight - (minPipeHeight * 2) - 80;
    
    if (currentGap > targetMaxGap) {
      currentGap = targetMaxGap;
    }
    
    // Absolute minimum gap ensuring playability
    if (currentGap < 110) {
      currentGap = 110; 
    }

    double maxPipeHeight = availableHeight - currentGap - minPipeHeight;
    if (maxPipeHeight < minPipeHeight) {
      maxPipeHeight = minPipeHeight;
    }

    final double bottomPipeHeight =
        minPipeHeight + Random().nextDouble() * (maxPipeHeight - minPipeHeight);

    final double topPipeHeight = availableHeight - bottomPipeHeight - currentGap;

    final bottomPipe = Pipe(
        Vector2(gameRef.size.x, availableHeight - bottomPipeHeight),
        Vector2(pipeWidth, bottomPipeHeight),
        isUpPipe: false);

    final topPipe = Pipe(
        Vector2(gameRef.size.x, 0), Vector2(pipeWidth, topPipeHeight),
        isUpPipe: true);

    gameRef.add(bottomPipe);
    gameRef.add(topPipe);
  }
}
