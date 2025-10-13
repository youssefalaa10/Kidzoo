import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:kidzoo/features/FlappyBird/flappy_bird_game.dart';

class FlappyBirdScreen extends StatelessWidget {
  const FlappyBirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The game widget
          GameWidget(game: FlappyBirdGame()),

          // Back button - positioned to not block game touches
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
