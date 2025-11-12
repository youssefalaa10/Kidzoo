import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/paddle_bounce_models.dart';

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    required this.winner,
    required this.player1Score,
    required this.player2Score,
    required this.gameMode,
    required this.onPlayAgain,
    required this.onMainMenu,
    super.key,
  });

  final int winner; // 1 for player 1, 2 for player 2
  final int player1Score;
  final int player2Score;
  final PaddleBounceGameMode gameMode;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPlayer1Winner = winner == 1;
    final winnerText = gameMode == PaddleBounceGameMode.vsAI
        ? (isPlayer1Winner ? l10n.youWin : l10n.aiWins)
        : (isPlayer1Winner ? l10n.player1Wins : l10n.player2Wins);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isPlayer1Winner ? Colors.pink.shade100 : Colors.cyan.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isPlayer1Winner
                    ? Colors.pink.shade100
                    : Colors.cyan.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isPlayer1Winner ? Colors.pink : Colors.cyan)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            // Winner text
            Text(
              winnerText,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPlayer1Winner
                    ? Colors.pink.shade700
                    : Colors.cyan.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Scores
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            gameMode == PaddleBounceGameMode.vsAI
                                ? 'AI'
                                : l10n.player2,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.cyan.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$player2Score',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'VS',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            l10n.player1,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.pink.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$player1Score',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMainMenu,
                    icon: const Icon(Icons.home),
                    label: Text(l10n.mainMenu),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onPlayAgain,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.playAgain),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
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
}
