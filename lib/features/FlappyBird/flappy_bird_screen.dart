import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/features/FlappyBird/flappy_bird_game.dart';
import 'package:kidzo/shared/widgets/game_exit_button.dart';

class FlappyBirdScreen extends StatefulWidget {
  const FlappyBirdScreen({super.key});

  @override
  State<FlappyBirdScreen> createState() => _FlappyBirdScreenState();
}

class _FlappyBirdScreenState extends State<FlappyBirdScreen> {
  late FlappyBirdGame _game;

  @override
  void initState() {
    super.initState();
    _game = FlappyBirdGame();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MusicCubit, MusicState>(
      listener: (context, state) {
        _game.isSoundEnabled = state.isSoundEnabled;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // The game widget
            GameWidget(game: _game),

            // Navigation bar at top
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button using unified GameExitButton
                    const GameExitButton(),
                    // Settings button
                    BlocBuilder<MusicCubit, MusicState>(
                      builder: (context, state) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              state.isSoundEnabled
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              context
                                  .read<MusicCubit>()
                                  .setSoundEnabled(!state.isSoundEnabled);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
