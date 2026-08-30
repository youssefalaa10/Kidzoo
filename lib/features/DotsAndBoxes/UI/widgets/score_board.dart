import 'package:flutter/material.dart';

import '../../data/models/dots_and_boxes_models.dart';

class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    required this.player1Score,
    required this.player2Score,
    required this.currentPlayer,
    required this.gameMode,
    super.key,
  });

  final int player1Score;
  final int player2Score;
  final Player currentPlayer;
  final GameMode gameMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerScore(
            gameMode == GameMode.vsAI ? 'You' : 'Player 1',
            player1Score,
            Player.player1,
            currentPlayer == Player.player1,
          ),
          _buildDivider(),
          _buildPlayerScore(
            gameMode == GameMode.vsAI ? 'AI' : 'Player 2',
            player2Score,
            Player.player2,
            currentPlayer == Player.player2,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(
      String label, int score, Player player, bool isActive) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? player.color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? player.color.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlayerIcon(player),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? player.color : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 30 : 26,
                fontWeight: FontWeight.bold,
                color: player.color.withValues(alpha: isActive ? 1.0 : 0.7),
              ),
              child: Text('$score'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerIcon(Player player) {
    if (player == Player.player1) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: player.color,
          shape: BoxShape.circle,
        ),
      );
    } else {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: player.color,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
  }

  Widget _buildDivider() {
    return Container(
      width: 2,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
