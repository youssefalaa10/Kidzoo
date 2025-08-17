import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'Data/Logic/Model/level_model.dart';
import 'Data/Logic/Model/game_sequence_model.dart';
import 'Data/Logic/cubit/levelmap_cubit.dart';
import 'Widgets/level_button.dart';
import '../../shared/services/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global state for level completion
class LevelCompletionManager {
  static final LevelCompletionManager _instance =
      LevelCompletionManager._internal();
  factory LevelCompletionManager() => _instance;
  LevelCompletionManager._internal();

  Future<void> completeLevel(int levelId) async {
    final nextLevelId = GameSequence.getNextStageNumber(levelId);
    print('DEBUG: Completing level $levelId, next level is $nextLevelId');

    // Save progress to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highest_unlocked_level', nextLevelId);

    print('DEBUG: Saved progress - highest unlocked level: $nextLevelId');
  }
}

class LevelMapScreen extends StatelessWidget {
  // Define the height of the background image (adjust based on actual image height)
  final double backgroundHeight = 2000;

  const LevelMapScreen(
      {super.key}); // Example height in pixels (adjust as needed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => LevelCubit(),
        child: BlocBuilder<LevelCubit, LevelMapState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: SizedBox(
                // Set the container height to match the image
                height: backgroundHeight,
                child: Stack(
                  children: [
                    // Background Image
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/home/Fav.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Current Level Indicator
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Current Level: ${state.currentLevelId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                    // Debug button to unlock level 2
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              context.read<LevelCubit>().unlockLevel(2);
                              print('DEBUG: Manually unlocked level 2');
                            },
                            child: const Text('Debug: Unlock Level 2'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              context.read<LevelCubit>().unlockLevel(3);
                              print('DEBUG: Manually unlocked level 3');
                            },
                            child: const Text('Debug: Unlock Level 3'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.clear();
                              print('DEBUG: Cleared all progress');
                              // Restart the app or reload the level map
                            },
                            child: const Text('Debug: Reset Progress'),
                          ),
                        ],
                      ),
                    ),
                    // Level Buttons
                    Stack(
                      children: state.levels.map((level) {
                        // Get game info for this level
                        final gameInfo =
                            GameSequence.createGameForLevel(level.id);

                        // Display difficulty level and game type information (reserved for future use)

                        // Determine button color based on game type
                        Color buttonColor;
                        switch (gameInfo.gameType) {
                          case GameType.animalQuiz:
                            buttonColor = Colors.red;
                            break;
                          case GameType.memoryGame:
                            buttonColor = Colors.blue;
                            break;
                          case GameType.puzzle:
                            buttonColor = Colors.green;
                            break;
                          case GameType.mathGame:
                            buttonColor = Colors.orange;
                            break;
                        }

                        return Positioned(
                            left: level.positionX,
                            top: level.positionY,
                            child: LevelButton(
                              level: level,
                              color: buttonColor,
                              onTap: () {
                                if (!level.isLocked) {
                                  // Set this as the current level
                                  context
                                      .read<LevelCubit>()
                                      .setCurrentLevel(level.id);

                                  // Navigate to the appropriate game screen
                                  _navigateToGameScreen(context, level);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Level ${level.id} is locked! Complete previous levels first.'),
                                    ),
                                  );
                                }
                              },
                            ));
                      }).toList(),
                    ),
                    // Game Type Legend
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Game Types:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildLegendItem(Colors.red, 'Animal Quiz'),
                            _buildLegendItem(Colors.blue, 'Memory Game'),
                            _buildLegendItem(Colors.green, 'Puzzle'),
                            _buildLegendItem(Colors.orange, 'Math Game'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build legend items
  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // Navigate to the appropriate game screen based on the level
  void _navigateToGameScreen(BuildContext context, Level level) {
    // Create the game sequence item for this level
    final gameSequenceItem = GameSequence.createGameForLevel(level.id);

    // Get the navigation service
    final navigationService = NavigationService();

    // Capture the cubit before opening dialog to avoid using a deactivated context later
    final levelCubit = context.read<LevelCubit>();

    // Show a dialog with game information
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Level ${level.id}: ${gameSequenceItem.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game: ${gameSequenceItem.name}'),
            Text('Difficulty: Level ${gameSequenceItem.level}'),
            const SizedBox(height: 8),
            // Show the fixed stage mapping information
            Text('Stage: ${level.id}'),
            const SizedBox(height: 16),
            const Text('Ready to play?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog

              navigationService
                  .navigateToGameScreen(context, gameSequenceItem.gameScreen,
                      stageNumber: level.id)
                  .then((result) {
                // Check if the game was completed (result == true)
                print('DEBUG: Game returned result: $result');
                if (result == true) {
                  print(
                      'DEBUG: Game completed successfully, unlocking next level');

                  // Use the global completion manager
                  LevelCompletionManager().completeLevel(level.id).then((_) {
                    // Refresh the level map using the captured cubit
                    levelCubit.completeLevel(level.id);
                  });
                } else {
                  print('DEBUG: Game not completed');
                }
              });
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  // Unused dialogs removed to avoid warnings
}
