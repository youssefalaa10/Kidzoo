import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/logic/game_cubit.dart';
import '../data/logic/game_logic.dart';
import '../data/models/game_state_model.dart';
import 'widgets/game_board.dart';
import 'widgets/game_dialog.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late GameCubit _gameCubit;

  @override
  void initState() {
    super.initState();
    _gameCubit = context.read<GameCubit>();
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx.abs();
    final dy = velocity.dy.abs();

    if (dx > dy) {
      // Horizontal swipe
      if (velocity.dx > 0) {
        _gameCubit.move(SwipeDirection.right);
      } else {
        _gameCubit.move(SwipeDirection.left);
      }
    } else {
      // Vertical swipe
      if (velocity.dy > 0) {
        _gameCubit.move(SwipeDirection.down);
      } else {
        _gameCubit.move(SwipeDirection.up);
      }
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _gameCubit.move(SwipeDirection.up);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _gameCubit.move(SwipeDirection.down);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _gameCubit.move(SwipeDirection.left);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _gameCubit.move(SwipeDirection.right);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8EF),
        body: BlocConsumer<GameCubit, GameState>(
          listener: (context, state) {
            if (state.status == GameStatus.won) {
              showWinDialog(
                context,
                score: state.currentScore,
                maxTile: state.maxTileAchieved,
                onNewGame: () => _gameCubit.newGame(),
                onContinue: () => _gameCubit.continueAfterWin(),
              );
            } else if (state.status == GameStatus.lost) {
              showLoseDialog(
                context,
                score: state.currentScore,
                maxTile: state.maxTileAchieved,
                onNewGame: () => _gameCubit.newGame(),
                onRetry: () => _gameCubit.restart(),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(state),
                  const SizedBox(height: 20),
                  // Score Board
                  _buildScoreBoard(state),
                  const SizedBox(height: 20),
                  // Control Buttons
                  _buildControlButtons(state),
                  const Spacer(),
                  // Game Board
                  Center(
                    child: GameBoard(
                      board: state.board,
                      onSwipe: _handleSwipe,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
            color: const Color(0xFF776E65),
          ),
          const Text(
            '2048',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF776E65),
            ),
          ),
          IconButton(
            onPressed: () {
              // Show settings or info
              _showInfoDialog();
            },
            icon: const Icon(Icons.info_outline_rounded, size: 28),
            color: const Color(0xFF776E65),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScoreCard('SCORE', state.currentScore, Colors.orange),
          const SizedBox(width: 16),
          _buildScoreCard('BEST', state.bestScore, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(GameState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.refresh_rounded,
            label: 'New',
            color: Colors.blue,
            onPressed: () => _showNewGameConfirmation(),
          ),
          const SizedBox(width: 12),
          if (_gameCubit.settings.undoEnabled)
            _buildControlButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              color: Colors.purple,
              onPressed: () => _gameCubit.undo(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  void _showNewGameConfirmation() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Game?'),
        content: const Text(
          'Your current progress will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _gameCubit.newGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Goal: Reach the 2048 tile!\n\n'
              '📱 Swipe to move tiles\n'
              '⌨️ Use arrow keys (desktop)\n'
              '🔄 Tiles with same number merge\n'
              '✨ Create higher numbers!\n\n'
              'Good luck! 🍀',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
