import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/maze_models.dart';

/// Show instructions dialog before starting the game
void showMazeInstructionsDialog(
  BuildContext context,
  MazeDifficulty difficulty, {
  required VoidCallback onStart,
}) {
  final l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              difficulty.color.withValues(alpha: 0.15),
              difficulty.color.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animated icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: difficulty.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: difficulty.color.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.grid_4x4,
                        size: 60,
                        color: difficulty.color,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.mazeGame,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: difficulty.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: difficulty.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: difficulty.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  difficulty.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: difficulty.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Instructions with enhanced UI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: difficulty.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInstructionItem(
                      l10n,
                      '1',
                      l10n.mazeInstruction1,
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      l10n,
                      '2',
                      l10n.mazeInstruction2,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      l10n,
                      '3',
                      l10n.mazeInstruction3,
                      Colors.orange,
                    ),
                    if (difficulty.requiredStars > 0) ...[
                      const SizedBox(height: 16),
                      _buildInstructionItem(
                        l10n,
                        '4',
                        l10n.mazeInstruction4(difficulty.requiredStars),
                        Colors.amber,
                      ),
                    ],
                    if (difficulty == MazeDifficulty.hard) ...[
                      const SizedBox(height: 16),
                      _buildInstructionItem(
                        l10n,
                        '5',
                        l10n.mazeInstruction5,
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start Button with enhanced design
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 300;
                  return SizedBox(
                    width: isSmallScreen ? double.infinity : null,
                    child: ElevatedButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: Text(
                        l10n.startPlaying,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: difficulty.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: difficulty.color.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildInstructionItem(
  AppLocalizations l10n,
  String number,
  String instruction,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: color.withValues(alpha: 0.3),
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            instruction,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Show result dialog when game ends
void showMazeResultDialog(
  BuildContext context, {
  required bool won,
  required MazeDifficulty difficulty,
  required int starsCollected,
  required int requiredStars,
  required int timeElapsed,
  required bool touchedWall,
  required VoidCallback onPlayAgain,
  required VoidCallback onExit,
}) {
  final l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                won
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                won
                    ? Colors.green.withValues(alpha: 0.05)
                    : Colors.red.withValues(alpha: 0.05),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Result Icon with enhanced animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.rotate(
                        angle: (1 - value) * 0.3,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: won
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (won ? Colors.green : Colors.red)
                                    .withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            won ? Icons.celebration : Icons.error_outline,
                            size: 70,
                            color: won ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Title with enhanced styling
                Text(
                  won ? '${l10n.congratulations}! 🎉' : '${l10n.gameOver} 😔',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: won ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  won ? l10n.youWin : l10n.tryAgain,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: won ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Stats with enhanced UI
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (won ? Colors.green : Colors.red)
                          .withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                        Icons.grid_4x4,
                        l10n.difficulty,
                        difficulty.displayName,
                        difficulty.color,
                      ),
                      const Divider(height: 20),
                      _buildStatRow(
                        Icons.timer,
                        l10n.time,
                        _formatTime(timeElapsed),
                        Colors.blue,
                      ),
                      if (requiredStars > 0) ...[
                        const Divider(height: 20),
                        _buildStatRow(
                          Icons.star,
                          l10n.stars,
                          '$starsCollected/$requiredStars',
                          Colors.amber,
                        ),
                      ],
                      if (!won && touchedWall) ...[
                        const Divider(height: 20),
                        _buildStatRow(
                          Icons.warning,
                          l10n.reason,
                          l10n.touchedWall,
                          Colors.red,
                        ),
                      ],
                      if (!won && !touchedWall) ...[
                        const Divider(height: 20),
                        _buildStatRow(
                          Icons.warning,
                          l10n.reason,
                          l10n.timeUp,
                          Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons with responsive design
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 300;
                    return isSmallScreen
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: onPlayAgain,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(l10n.playAgain),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        won ? Colors.green : difficulty.color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: onExit,
                                  icon: const Icon(Icons.exit_to_app),
                                  label: Text(l10n.exit),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    side: BorderSide(
                                        color: Colors.grey.shade400, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onExit,
                                  icon: const Icon(Icons.exit_to_app),
                                  label: Text(l10n.exit),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    side: BorderSide(
                                        color: Colors.grey.shade400, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: onPlayAgain,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(l10n.playAgain),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        won ? Colors.green : difficulty.color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
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
      );
    },
  );
}

Widget _buildStatRow(IconData icon, String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
