import 'package:flutter/material.dart';

import '../../data/models/color_memory_constants.dart';

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    required this.score,
    required this.bestScore,
    required this.round,
    required this.longestSequence,
    required this.onRestart,
    required this.onExit,
    super.key,
  });

  final int score;
  final int bestScore;
  final int round;
  final int longestSequence;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isNewBest = score >= bestScore && score > 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ColorMemoryConstants.borderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ColorMemoryConstants.cardBackgroundColor,
          borderRadius:
              BorderRadius.circular(ColorMemoryConstants.borderRadius),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Prevent overflow on small screens
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: 400,
          ),
          child: SafeArea(
            minimum: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      // Game over icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isNewBest
                              ? Colors.amber.shade50
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNewBest ? Icons.emoji_events : Icons.cancel,
                          size: 48,
                          color: isNewBest
                              ? Colors.amber.shade600
                              : Colors.red.shade600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        isNewBest ? 'New Best Score!' : 'Game Over',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'You reached Round $round',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Your score only
                      _StatCard(
                        icon: Icons.emoji_events,
                        label: 'Your Score',
                        value: score.toString(),
                        color: Colors.blue.shade600,
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onExit,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Exit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onRestart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Restart',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // end Row
                    ],
                    // end children
                  ),
                  // end ListView
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
