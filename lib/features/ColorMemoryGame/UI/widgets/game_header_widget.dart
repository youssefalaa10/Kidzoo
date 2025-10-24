import 'package:flutter/material.dart';

import '../../data/models/color_memory_constants.dart';
import '../../data/models/game_state_model.dart';

class GameHeaderWidget extends StatelessWidget {
  const GameHeaderWidget({
    required this.state,
    required this.onBack,
    required this.onRestart,
    super.key,
  });

  final ColorMemoryGameState state;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Top bar with back and restart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: ColorMemoryConstants.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: onBack,
                ),
              ),

              // Title
              Text(
                'Color Memory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),

              // Restart button
              Container(
                decoration: BoxDecoration(
                  color: ColorMemoryConstants.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  onPressed: onRestart,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatCard(
                icon: Icons.emoji_events,
                label: 'Score',
                value: state.score.currentScore.toString(),
                color: Colors.amber.shade600,
              ),
              _StatCard(
                icon: Icons.psychology,
                label: 'Round',
                value: state.score.currentRound.toString(),
                color: Colors.blue.shade600,
              ),
              _StatCard(
                icon: Icons.layers,
                label: 'Length',
                value: state.sequence.length.toString(),
                color: Colors.purple.shade600,
              ),
              _StatCard(
                icon: Icons.stars,
                label: 'Best',
                value: state.bestScore.toString(),
                color: Colors.green.shade600,
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorMemoryConstants.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
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
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}


