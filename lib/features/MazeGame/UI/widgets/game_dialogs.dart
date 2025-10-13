import 'package:flutter/material.dart';

import '../../data/models/maze_models.dart';

/// Show instructions dialog before starting the game
void showMazeInstructionsDialog(
  BuildContext context,
  MazeDifficulty difficulty, {
  required VoidCallback onStart,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              difficulty.color.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: difficulty.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.grid_4x4,
                    size: 48,
                    color: difficulty.color,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Maze Game - لعبة المتاهة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    difficulty.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      color: difficulty.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions
            _buildInstructionItem(
              '1',
              'Tap & drag from Start (green)',
              'اضغط واسحب من البداية (الأخضر)',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              '2',
              'Keep finger down, follow path',
              'أبقِ إصبعك على الشاشة واتبع الطريق',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              '3',
              'Don\'t touch walls!',
              'لا تلمس الجدران!',
              Colors.orange,
            ),
            if (difficulty.requiredStars > 0) ...[
              const SizedBox(height: 12),
              _buildInstructionItem(
                '4',
                'Collect ${difficulty.requiredStars} stars',
                'اجمع ${difficulty.requiredStars} نجوم',
                Colors.amber,
              ),
            ],
            if (difficulty == MazeDifficulty.hard) ...[
              const SizedBox(height: 12),
              _buildInstructionItem(
                '5',
                'Complete within 2 minutes',
                'أكمل خلال دقيقتين',
                Colors.red,
              ),
            ],
            const SizedBox(height: 24),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: difficulty.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Playing - ابدأ اللعب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInstructionItem(
  String number,
  String english,
  String arabic,
  Color color,
) {
  return Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              english,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              arabic,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    ],
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
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                won
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Result Icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: won
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        won ? Icons.celebration : Icons.error_outline,
                        size: 60,
                        color: won ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                won ? 'Congratulations! 🎉' : 'Game Over 😔',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                won ? 'فزت! أحسنت' : 'حاول مرة أخرى',
                style: TextStyle(
                  fontSize: 18,
                  color: won ? Colors.green.shade700 : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 20),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      Icons.grid_4x4,
                      'Difficulty',
                      difficulty.displayName,
                      difficulty.color,
                    ),
                    const Divider(height: 16),
                    _buildStatRow(
                      Icons.timer,
                      'Time',
                      _formatTime(timeElapsed),
                      Colors.blue,
                    ),
                    if (requiredStars > 0) ...[
                      const Divider(height: 16),
                      _buildStatRow(
                        Icons.star,
                        'Stars',
                        '$starsCollected/$requiredStars',
                        Colors.amber,
                      ),
                    ],
                    if (!won && touchedWall) ...[
                      const Divider(height: 16),
                      _buildStatRow(
                        Icons.warning,
                        'Reason',
                        'Touched Wall',
                        Colors.red,
                      ),
                    ],
                    if (!won && !touchedWall) ...[
                      const Divider(height: 16),
                      _buildStatRow(
                        Icons.warning,
                        'Reason',
                        'Time\'s Up',
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Exit - خروج'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onPlayAgain,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Play Again - العب مرة أخرى'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: won ? Colors.green : difficulty.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    },
  );
}

Widget _buildStatRow(IconData icon, String label, String value, Color color) {
  return Row(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}
