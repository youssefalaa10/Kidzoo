import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/navigation_service.dart';
import 'Data/Logic/Model/game_sequence_model.dart';
import 'Data/Logic/Model/level_model.dart';
import 'Data/Logic/cubit/levelmap_cubit.dart';
import 'Widgets/level_button.dart';
import 'package:kidzoo/core/utils/assets.dart';

// Global state for level completion
class LevelCompletionManager {
  factory LevelCompletionManager() => _instance;
  LevelCompletionManager._internal();
  static final LevelCompletionManager _instance =
      LevelCompletionManager._internal();

  Future<void> completeLevel(int levelId) async {
    final nextLevelId = GameSequence.getNextStageNumber(levelId);

    // Save progress to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highest_unlocked_level', nextLevelId);
  }
}

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});
  // Define the height of the background image (adjust based on actual image height)
  final double backgroundHeight =
      2300; // Increased height to accommodate all 18 stages

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                          image: AssetImage(Assets.genImagesHomeFav),
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
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.currentLevelLabel(state.currentLevelId),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                    // Debug buttons removed
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
                          case GameType.colorMemoryGame:
                            buttonColor = Colors.purple;
                            break;
                          case GameType.puzzle:
                            buttonColor = Colors.green;
                            break;
                          case GameType.mathGame:
                            buttonColor = Colors.orange;
                            break;
                          case GameType.mazeGame:
                            buttonColor =
                                const Color(0xFF8B4513); // SaddleBrown
                            break;
                          case GameType.dotsAndBoxes:
                            buttonColor = Colors.teal;
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
                                          l10n.lockedLevelMessage(level.id)),
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
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.gameTypesLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildLegendItem(Colors.red, l10n.animalNameGame),
                            _buildLegendItem(Colors.blue, l10n.memoryGame),
                            _buildLegendItem(Colors.purple, l10n.colorMemory),
                            _buildLegendItem(Colors.green, l10n.puzzleFrame),
                            _buildLegendItem(Colors.orange, l10n.mathMagic),
                            _buildLegendItem(
                                const Color(0xFF8B4513), l10n.mazeGame),
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

    // Determine emoji and color based on game type
    String gameEmoji;
    Color primaryColor;
    switch (gameSequenceItem.gameType) {
      case GameType.animalQuiz:
        gameEmoji = '🐾';
        primaryColor = Colors.red;
        break;
      case GameType.memoryGame:
        gameEmoji = '🧠';
        primaryColor = Colors.blue;
        break;
      case GameType.colorMemoryGame:
        gameEmoji = '🎨';
        primaryColor = Colors.purple;
        break;
      case GameType.puzzle:
        gameEmoji = '🧩';
        primaryColor = Colors.green;
        break;
      case GameType.mathGame:
        gameEmoji = '🔢';
        primaryColor = Colors.orange;
        break;
      case GameType.mazeGame:
        gameEmoji = '🌀';
        primaryColor = const Color(0xFF8B4513);
        break;
      case GameType.dotsAndBoxes:
        gameEmoji = '⚫';
        primaryColor = Colors.teal;
        break;
    }

    // Show a kid-friendly dialog with game information
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: 0.1),
                primaryColor.withValues(alpha: 0.05),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large emoji icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      gameEmoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Level title with star
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '⭐',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.levelLabel(level.id),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '⭐',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Game name
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gameSequenceItem.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.amber.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎯',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.difficultyLevel(gameSequenceItem.level),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Ready message
                Text(
                  l10n.readyToPlay,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons - Made responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 300;
                    return isSmallScreen
                        ? Column(
                            children: [
                              // Play button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        Color.lerp(primaryColor, Colors.black, 0.3) ??
                                            primaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(dialogContext);
                                        navigationService
                                            .navigateToGameScreen<bool>(
                                                context, gameSequenceItem.gameScreen,
                                                stageNumber: level.id)
                                            .then((result) {
                                          if (result == true) {
                                            LevelCompletionManager()
                                                .completeLevel(level.id)
                                                .then((_) {
                                              levelCubit.completeLevel(level.id);
                                            });
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '🎮',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                l10n.play,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Cancel button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(dialogContext),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '❌',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                l10n.cancel,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel button
                    Expanded(
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(dialogContext),
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '❌',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                l10n.cancel,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Play button
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              Color.lerp(primaryColor, Colors.black, 0.3) ??
                                  primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext); // Close dialog

                              navigationService
                                  .navigateToGameScreen<bool>(
                                      context, gameSequenceItem.gameScreen,
                                      stageNumber: level.id)
                                  .then((result) {
                                // Check if the game was completed (result == true)
                                if (result == true) {
                                  // Use the global completion manager
                                  LevelCompletionManager()
                                      .completeLevel(level.id)
                                      .then((_) {
                                    // Refresh the level map using the captured cubit
                                    levelCubit.completeLevel(level.id);
                                  });
                                } else {
                                  print('DEBUG: Game not completed');
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🚀',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.play,
                                      style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
                  },
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  // Unused dialogs removed to avoid warnings
}