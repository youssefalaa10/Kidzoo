import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class GameDialog extends StatefulWidget {
  const GameDialog({
    required this.title,
    required this.message,
    required this.score,
    required this.maxTile,
    this.showConfetti = false,
    this.onNewGame,
    this.onContinue,
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final int score;
  final int maxTile;
  final bool showConfetti;
  final VoidCallback? onNewGame;
  final VoidCallback? onContinue;
  final VoidCallback? onRetry;

  @override
  State<GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    if (widget.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon/Emoji
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.showConfetti
                          ? Colors.amber.shade100
                          : Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.showConfetti ? '🎉' : '🎮',
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.showConfetti
                          ? Colors.amber.shade700
                          : Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(AppLocalizations.of(context).score,
                            widget.score.toString()),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        _buildStatItem(AppLocalizations.of(context).maxTile,
                            widget.maxTile.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Column(
                    children: [
                      if (widget.onContinue != null)
                        _buildButton(
                          AppLocalizations.of(context).continuePlaying,
                          Colors.green,
                          Icons.play_arrow_rounded,
                          widget.onContinue!,
                        ),
                      if (widget.onContinue != null) const SizedBox(height: 12),
                      if (widget.onRetry != null)
                        _buildButton(
                          AppLocalizations.of(context).tryAgain,
                          Colors.orange,
                          Icons.refresh_rounded,
                          widget.onRetry!,
                        ),
                      if (widget.onRetry != null) const SizedBox(height: 12),
                      if (widget.onNewGame != null)
                        _buildButton(
                          AppLocalizations.of(context).newGame,
                          Colors.blue,
                          Icons.add_rounded,
                          widget.onNewGame!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showConfetti)
          Positioned(
            top: 0,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          onPressed();
        },
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

// Convenience functions to show dialogs
void showWinDialog(
  BuildContext context, {
  required int score,
  required int maxTile,
  required VoidCallback onNewGame,
  required VoidCallback onContinue,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => GameDialog(
      title: AppLocalizations.of(context).youWin,
      message: AppLocalizations.of(context).youWinReached(maxTile),
      score: score,
      maxTile: maxTile,
      showConfetti: true,
      onNewGame: onNewGame,
      onContinue: onContinue,
    ),
  );
}

void showLoseDialog(
  BuildContext context, {
  required int score,
  required int maxTile,
  required VoidCallback onNewGame,
  required VoidCallback onRetry,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => GameDialog(
      title: AppLocalizations.of(context).gameOver,
      message: AppLocalizations.of(context).noMoreMoves,
      score: score,
      maxTile: maxTile,
      onNewGame: onNewGame,
      onRetry: onRetry,
    ),
  );
}
