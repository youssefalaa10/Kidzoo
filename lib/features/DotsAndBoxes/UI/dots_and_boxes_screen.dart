import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/logic/dots_and_boxes_cubit.dart';
import '../data/models/dots_and_boxes_models.dart';
import '../data/models/game_state_model.dart';
import 'widgets/game_result_dialog.dart';
import 'widgets/interactive_game_board.dart';
import 'widgets/score_board.dart';

class DotsAndBoxesScreen extends StatelessWidget {
  const DotsAndBoxesScreen({
    super.key,
    this.level = 1,
  });

  final int level;

  @override
  Widget build(BuildContext context) {
    // Map level to difficulty
    final difficulty = level == 1
        ? GameDifficulty.easy
        : level == 2
            ? GameDifficulty.medium
            : GameDifficulty.hard;

    return BlocProvider(
      create: (context) => DotsAndBoxesCubit(
        difficulty: difficulty,
        gameMode: GameMode.vsAI, // Default to AI mode for fun games
      ),
      child: const _DotsAndBoxesScreenContent(),
    );
  }
}

class _DotsAndBoxesScreenContent extends StatefulWidget {
  const _DotsAndBoxesScreenContent();

  @override
  State<_DotsAndBoxesScreenContent> createState() =>
      _DotsAndBoxesScreenContentState();
}

class _DotsAndBoxesScreenContentState
    extends State<_DotsAndBoxesScreenContent> {
  @override
  void initState() {
    super.initState();
    // Show mode selection dialog on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showModeSelectionDialog();
    });
  }

  void _showModeSelectionDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Choose Game Mode',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Who would you like to play against?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildModeCard(
              context: dialogContext,
              icon: Icons.smart_toy,
              title: 'Play vs AI',
              description: 'Challenge the computer',
              color: Colors.blue,
              mode: GameMode.vsAI,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              context: dialogContext,
              icon: Icons.people,
              title: 'Play vs Friend',
              description: 'Play with a friend',
              color: Colors.green,
              mode: GameMode.vsPlayer,
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required GameMode mode,
    required Gradient gradient,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        this.context.read<DotsAndBoxesCubit>().changeGameMode(mode);

        // If AI mode, show AI difficulty selector
        if (mode == GameMode.vsAI) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _showAIDifficultyDialog();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAIDifficultyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Select AI Difficulty',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AIDifficulty.values.map((difficulty) {
            Color color;
            IconData icon;

            switch (difficulty) {
              case AIDifficulty.easy:
                color = Colors.green;
                icon = Icons.sentiment_satisfied;
                break;
              case AIDifficulty.medium:
                color = Colors.orange;
                icon = Icons.sentiment_neutral;
                break;
              case AIDifficulty.hard:
                color = Colors.red;
                icon = Icons.psychology;
                break;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  context
                      .read<DotsAndBoxesCubit>()
                      .changeAIDifficulty(difficulty);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              difficulty.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              difficulty.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: color, size: 16),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocConsumer<DotsAndBoxesCubit, DotsAndBoxesState>(
        listener: (context, state) {
          if (state.status == GameStatus.finished) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (context.mounted) {
                _showResultDialog(context, state);
              }
            });
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, state),
                const SizedBox(height: 16),

                // Score Board
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ScoreBoard(
                    player1Score: state.player1Score,
                    player2Score: state.player2Score,
                    currentPlayer: state.currentPlayer,
                    gameMode: state.gameMode,
                  ),
                ),
                const SizedBox(height: 16),

                // Current Turn Indicator
                _buildTurnIndicator(state),
                const SizedBox(height: 8),

                // Combo Indicator (if active)
                if (state.isComboActive) _buildComboIndicator(state),

                // Stats Row
                _buildStatsRow(state),
                const SizedBox(height: 8),

                // Game Board
                Expanded(
                  child: Center(
                    child: InteractiveGameBoard(
                      state: state,
                      onLineTapped: (start, end) {
                        context.read<DotsAndBoxesCubit>().drawLine(start, end);
                      },
                    ),
                  ),
                ),

                // Control Buttons
                _buildControlButtons(context, state),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DotsAndBoxesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.black87,
            iconSize: 24,
          ),

          // Title
          Column(
            children: [
              const Text(
                'Dots & Boxes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                state.difficulty.displayName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          // Settings button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'difficulty',
                child: Row(
                  children: [
                    Icon(Icons.grid_3x3, size: 20),
                    SizedBox(width: 8),
                    Text('Grid Size'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mode',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Game Mode'),
                  ],
                ),
              ),
              if (state.gameMode == GameMode.vsAI)
                const PopupMenuItem(
                  value: 'ai',
                  child: Row(
                    children: [
                      Icon(Icons.psychology, size: 20),
                      SizedBox(width: 8),
                      Text('AI Difficulty'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'how',
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
              if (value == 'difficulty') {
                _showDifficultySelector(context, state);
              } else if (value == 'mode') {
                _showModeSelector(context, state);
              } else if (value == 'ai') {
                _showAIDifficultySelector(context, state);
              } else if (value == 'how') {
                _showHowToPlayDialog(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator(DotsAndBoxesState state) {
    if (state.status != GameStatus.playing) return const SizedBox.shrink();

    final isAITurn = state.gameMode == GameMode.vsAI &&
        state.currentPlayer == Player.player2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: state.currentPlayer.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.currentPlayer.color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: state.currentPlayer.color,
              shape: state.currentPlayer == Player.player1
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius: state.currentPlayer == Player.player2
                  ? BorderRadius.circular(2)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isAITurn
                ? 'AI thinking...'
                : '${state.currentPlayer.displayName}\'s turn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: state.currentPlayer.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboIndicator(DotsAndBoxesState state) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade300,
            Colors.orange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flash_on, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            'Combo ×${state.currentCombo}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DotsAndBoxesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatChip(
              Icons.swap_horiz, 'Moves: ${state.moveCount}', Colors.blue),
          const SizedBox(width: 12),
          _buildStatChip(
              Icons.local_fire_department,
              'Best: ×${state.maxCombo}',
              state.maxCombo > 0 ? Colors.orange : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.8)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context, DotsAndBoxesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showRestartConfirmation(context);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('New Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, DotsAndBoxesState state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameResultDialog(
        player1Score: state.player1Score,
        player2Score: state.player2Score,
        winner: state.winner,
        gameMode: state.gameMode,
        moveCount: state.moveCount,
        maxCombo: state.maxCombo,
        onNewGame: () {
          Navigator.pop(dialogContext);
          context.read<DotsAndBoxesCubit>().resetGame();
        },
        onClose: () {
          Navigator.pop(dialogContext);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRestartConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Start New Game?'),
        content: const Text('Current game progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DotsAndBoxesCubit>().resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _showDifficultySelector(BuildContext context, DotsAndBoxesState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Select Grid Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GameDifficulty.values.map((difficulty) {
            final isSelected = difficulty == state.difficulty;
            return ListTile(
              title: Text(difficulty.displayName),
              leading: Radio<GameDifficulty>(
                value: difficulty,
                groupValue: state.difficulty,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(dialogContext);
                    context.read<DotsAndBoxesCubit>().changeDifficulty(value);
                  }
                },
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<DotsAndBoxesCubit>().changeDifficulty(difficulty);
              },
              selected: isSelected,
              selectedTileColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showModeSelector(BuildContext context, DotsAndBoxesState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Select Game Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GameMode.values.map((mode) {
            final isSelected = mode == state.gameMode;
            return ListTile(
              title: Text(mode.displayName),
              leading: Radio<GameMode>(
                value: mode,
                groupValue: state.gameMode,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(dialogContext);
                    context.read<DotsAndBoxesCubit>().changeGameMode(value);
                  }
                },
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<DotsAndBoxesCubit>().changeGameMode(mode);
              },
              selected: isSelected,
              selectedTileColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAIDifficultySelector(
      BuildContext context, DotsAndBoxesState state) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Select AI Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AIDifficulty.values.map((difficulty) {
            final isSelected = difficulty == state.aiDifficulty;
            return ListTile(
              title: Text(difficulty.displayName),
              subtitle: Text(
                difficulty.description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              leading: Radio<AIDifficulty>(
                value: difficulty,
                groupValue: state.aiDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(dialogContext);
                    context.read<DotsAndBoxesCubit>().changeAIDifficulty(value);
                  }
                },
              ),
              onTap: () {
                Navigator.pop(dialogContext);
                context
                    .read<DotsAndBoxesCubit>()
                    .changeAIDifficulty(difficulty);
              },
              selected: isSelected,
              selectedTileColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHowToPlayDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('How to Play'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHowToPlayItem(
                '1',
                'Players take turns drawing lines between adjacent dots',
              ),
              const SizedBox(height: 12),
              _buildHowToPlayItem(
                '2',
                'When you complete the 4th side of a box, you claim it and get another turn',
              ),
              const SizedBox(height: 12),
              _buildHowToPlayItem(
                '3',
                'The game ends when all boxes are claimed',
              ),
              const SizedBox(height: 12),
              _buildHowToPlayItem(
                '4',
                'The player with the most boxes wins!',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Try to avoid giving your opponent easy boxes!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
