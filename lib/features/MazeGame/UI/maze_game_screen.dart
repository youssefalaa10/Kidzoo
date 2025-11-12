import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../LevelsMap/levelmap_screen.dart';
import '../data/logic/maze_cubit.dart';
import '../data/models/maze_models.dart';
import '../data/models/maze_state.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/interactive_maze.dart';

class MazeGameScreen extends StatelessWidget {
  const MazeGameScreen({super.key, this.level = 1});

  final int level;

  @override
  Widget build(BuildContext context) {
    final difficulty = level == 1
        ? MazeDifficulty.easy
        : level == 2
            ? MazeDifficulty.medium
            : MazeDifficulty.hard;

    return BlocProvider(
      create: (context) => MazeCubit(difficulty: difficulty),
      child: const _MazeGameContent(),
    );
  }
}

class _MazeGameContent extends StatefulWidget {
  const _MazeGameContent();

  @override
  State<_MazeGameContent> createState() => _MazeGameContentState();
}

class _MazeGameContentState extends State<_MazeGameContent> {
  bool _hasShownInstructions = false;

  @override
  void initState() {
    super.initState();
    // Show instructions after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasShownInstructions) {
        _showInstructionsDialog();
        _hasShownInstructions = true;
      }
    });
  }

  void _showInstructionsDialog() {
    final cubit = context.read<MazeCubit>();
    showMazeInstructionsDialog(
      context,
      cubit.state.difficulty,
      onStart: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocConsumer<MazeCubit, MazeState>(
        listener: (context, state) {
          if (state.status == MazeGameStatus.won) {
            _showResultDialog(state, true);
          } else if (state.status == MazeGameStatus.lost) {
            _showResultDialog(state, false);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 8),
                _buildGameInfo(state),
                const SizedBox(height: 8),
                _buildHelpText(state),
                const SizedBox(height: 8),
                Expanded(
                  child: InteractiveMaze(
                    state: state,
                    onStartDrawing: (pos) =>
                        context.read<MazeCubit>().startDrawing(pos),
                    onContinueDrawing: (pos) =>
                        context.read<MazeCubit>().continueDrawing(pos),
                    onEndDrawing: () => context.read<MazeCubit>().endDrawing(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildControls(context),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MazeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _showExitConfirmation(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Maze Game - لعبة المتاهة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.difficulty.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: state.difficulty.color),
                  ),
                  child: Text(
                    state.difficulty.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: state.difficulty.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restart',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('New Maze'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'instructions',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 8),
                    Text('How to Play'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'restart') {
                context.read<MazeCubit>().resetGame();
              } else if (value == 'instructions') {
                _showInstructionsDialog();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText(MazeState state) {
    String message;
    Color color;

    if (state.currentPosition == null) {
      message = 'Tap and drag from Start (green) - اسحب من البداية';
      color = Colors.green.shade700;
    } else if (state.currentPosition == state.endPosition) {
      message = 'You reached the end! - وصلت للنهاية!';
      color = Colors.green.shade700;
    } else {
      message = 'Keep dragging to Finish (red) - استمر للنهاية';
      color = Colors.blue.shade700;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Game?'),
        content: const Text('Your progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo(MazeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.requiredStars > 0) ...[
            _buildInfoChip(
              Icons.star,
              '${state.starsCollected}/${state.requiredStars}',
              Colors.yellow.shade700,
              state.hasCollectedAllStars,
            ),
            const SizedBox(width: 12),
          ],
          if (state.timeRemaining != null)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(
                begin: 1.0,
                end: state.timeRemaining! < 30 ? 1.1 : 1.0,
              ),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: _buildInfoChip(
                    Icons.timer,
                    _formatTime(state.timeRemaining!),
                    state.timeRemaining! < 30
                        ? Colors.red
                        : state.timeRemaining! < 60
                            ? Colors.orange
                            : Colors.blue,
                    false,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoChip(
      IconData icon, String text, Color color, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: isComplete ? 2 : 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (isComplete) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle, size: 16, color: color),
          ],
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.read<MazeCubit>().resetGame(),
              icon: const Icon(Icons.refresh),
              label: const Text('New Maze - متاهة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showResultDialog(MazeState state, bool won) {
    // Complete the level if won
    if (won) {
      // Get the level from the parent widget
      final parentWidget =
          context.findAncestorWidgetOfExactType<MazeGameScreen>();
      if (parentWidget != null) {
        final stageNumber = _getStageNumberForLevel(parentWidget.level);
        if (stageNumber != null) {
          LevelCompletionManager().completeLevel(stageNumber);
        }
      }
    }

    // Use kid-friendly dialog
    showMazeResultDialog(
      context,
      won: won,
      difficulty: state.difficulty,
      starsCollected: state.starsCollected,
      requiredStars: state.requiredStars,
      timeElapsed: state.timeElapsed,
      touchedWall: state.touchedWall,
      onPlayAgain: () {
        Navigator.pop(context); // Close dialog
        context.read<MazeCubit>().resetGame();
      },
      onExit: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context, won); // Return to map
      },
    );
  }

  int? _getStageNumberForLevel(int level) {
    // Map level (1, 2, 3) to stage numbers (6, 12, 18)
    switch (level) {
      case 1:
        return 6;
      case 2:
        return 12;
      case 3:
        return 18;
      default:
        return null;
    }
  }
}
