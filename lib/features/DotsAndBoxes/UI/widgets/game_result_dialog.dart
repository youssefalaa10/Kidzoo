import 'package:flutter/material.dart';

import '../../data/models/dots_and_boxes_models.dart';

class GameResultDialog extends StatelessWidget {
  const GameResultDialog({
    required this.player1Score, required this.player2Score, required this.gameMode, required this.onNewGame, required this.onClose, super.key,
    this.winner,
    this.moveCount = 0,
    this.maxCombo = 0,
  });

  final int player1Score;
  final int player2Score;
  final Player? winner;
  final GameMode gameMode;
  final VoidCallback onNewGame;
  final VoidCallback onClose;
  final int moveCount;
  final int maxCombo;

  @override
  Widget build(BuildContext context) {
    final isTie = winner == null;
    final isPlayer1Winner = winner == Player.player1;

    String title;
    if (isTie) {
      title = "It's a Tie!";
    } else if (gameMode == GameMode.vsAI) {
      title = isPlayer1Winner ? '🎉 You Win!' : '🤖 AI Wins!';
    } else {
      title = isPlayer1Winner ? '🎉 Player 1 Wins!' : '🎉 Player 2 Wins!';
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isTie 
                  ? Colors.amber.shade50
                  : winner!.lightColor.withValues(alpha:0.3),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isTie ? Colors.amber.shade700 : winner!.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Trophy icon
            if (!isTie)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: winner!.color.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 60,
                  color: winner!.color,
                ),
              ),
            if (isTie)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.handshake_rounded,
                  size: 60,
                  color: Colors.amber.shade700,
                ),
              ),

            const SizedBox(height: 24),

            // Scores
            _buildFinalScores(),

            const SizedBox(height: 16),

            // Game Stats
            _buildGameStats(),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onNewGame,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: isTie 
                          ? Colors.amber.shade600
                          : winner!.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'New Game',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildFinalScores() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreColumn(
            gameMode == GameMode.vsAI ? 'You' : 'Player 1',
            player1Score,
            Player.player1,
          ),
          Container(
            width: 2,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildScoreColumn(
            gameMode == GameMode.vsAI ? 'AI' : 'Player 2',
            player2Score,
            Player.player2,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, int score, Player player) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: player.color,
          ),
        ),
      ],
    );
  }

  Widget _buildGameStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.swap_horiz, 'Moves', '$moveCount'),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),
          _buildStatItem(
            Icons.whatshot,
            'Best Combo',
            maxCombo > 0 ? '×$maxCombo' : 'None',
            iconColor: maxCombo > 0 ? Colors.orange : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, {Color? iconColor}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

