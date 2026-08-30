import 'package:flutter/material.dart';

class GameResultDialog extends StatelessWidget {
  const GameResultDialog({
    required this.result,
    required this.gameMode,
    required this.onNewGame,
    required this.onClose,
    super.key,
  });

  final String result; // 'X', 'O', or 'Draw'
  final GameMode gameMode;
  final VoidCallback onNewGame;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getIconColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 60,
                color: _getIconColor(),
              ),
            ),

            const SizedBox(height: 20),

            // Result Title
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Result Message
            Text(
              _getMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNewGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getIconColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'New Game',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (result == 'Draw') return Icons.handshake;
    if (result == 'X') return Icons.emoji_events;
    return Icons.smart_toy;
  }

  Color _getIconColor() {
    if (result == 'Draw') return Colors.orange;
    if (result == 'X') return Colors.green;
    return Colors.blue;
  }

  String _getTitle() {
    if (result == 'Draw') return 'Draw!';
    if (result == 'X') return 'You Win!';
    if (gameMode == GameMode.vsAI) return 'AI Wins!';
    return 'Player O Wins!';
  }

  String _getMessage() {
    if (result == 'Draw') return 'Great game! It\'s a tie.';
    if (result == 'X') {
      return gameMode == GameMode.vsAI
          ? 'Congratulations! You beat the AI!'
          : 'Player X takes the victory!';
    }
    if (gameMode == GameMode.vsAI) {
      return 'The AI outsmarted you this time!';
    }
    return 'Player O takes the victory!';
  }
}

enum GameMode { twoPlayer, vsAI }
