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

/// Show kid-friendly result dialog when game ends
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
  final primaryColor = won ? Colors.green : Colors.red;
  final gameEmoji = won ? '🎉' : '😔';

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.1),
              primaryColor.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, dialogConstraints) {
              final isSmallDialog = dialogConstraints.maxWidth < 350;
              final emojiIconSize = isSmallDialog ? 80.0 : 100.0;
              final emojiFontSize = isSmallDialog ? 50.0 : 60.0;
              final titleFontSize = isSmallDialog ? 24.0 : 32.0;
              final starSize = isSmallDialog ? 18.0 : 24.0;
              final messageFontSize = isSmallDialog ? 18.0 : 22.0;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large emoji icon
                    Container(
                      width: emojiIconSize,
                      height: emojiIconSize,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          gameEmoji,
                          style: TextStyle(fontSize: emojiFontSize),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallDialog ? 16 : 20),
                    // Title with stars
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallDialog ? 8 : 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '⭐',
                            style: TextStyle(fontSize: starSize),
                          ),
                          SizedBox(width: isSmallDialog ? 6 : 8),
                          Flexible(
                            child: Text(
                              won ? l10n.congratulations : l10n.gameOver,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: isSmallDialog ? 0.8 : 1.2,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          SizedBox(width: isSmallDialog ? 6 : 8),
                          Text(
                            '⭐',
                            style: TextStyle(fontSize: starSize),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallDialog ? 12 : 16),
                    // Game result message
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallDialog ? 8 : 0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallDialog ? 16 : 20,
                          vertical: isSmallDialog ? 10 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          won ? l10n.youWin : l10n.tryAgain,
                          style: TextStyle(
                            fontSize: messageFontSize,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallDialog ? 16 : 20),
                    // Game stats container
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 350;
                        final fontSize = isSmallScreen ? 14.0 : 16.0;
                        final emojiSize = isSmallScreen ? 18.0 : 20.0;
                        final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

                        return Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
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
                              // Difficulty badge
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      difficulty.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                        difficulty.color.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '🎯',
                                      style: TextStyle(fontSize: emojiSize),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${l10n.difficulty}: ${difficulty.displayName}',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: difficulty.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (requiredStars > 0) ...[
                                const SizedBox(height: 12),
                                // Stars collected
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.amber.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '⭐',
                                        style: TextStyle(fontSize: emojiSize),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${l10n.stars}: $starsCollected/$requiredStars',
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Time elapsed
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.blue.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '⏱️',
                                      style: TextStyle(fontSize: emojiSize),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${l10n.time}: ${_formatTime(timeElapsed)}',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!won) ...[
                                const SizedBox(height: 12),
                                // Failure reason
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '⚠️',
                                        style: TextStyle(fontSize: emojiSize),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${l10n.reason}: ${touchedWall ? l10n.touchedWall : l10n.timeUp}',
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade900,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Action buttons - Made responsive
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 300;
                        return isSmallScreen
                            ? Column(
                                children: [
                                  // Back to Map button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: onExit,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '🗺️',
                                                  style:
                                                      TextStyle(fontSize: 20),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    l10n.exit,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (won) ...[
                                    const SizedBox(height: 12),
                                    // Play Again button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              primaryColor,
                                              Color.lerp(primaryColor,
                                                      Colors.black, 0.3) ??
                                                  primaryColor,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withValues(
                                                  alpha: 0.5),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: onPlayAgain,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    '🎮',
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      l10n.playAgain,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Back to Map button
                                  Expanded(
                                    child: Container(
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: onExit,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  '🗺️',
                                                  style:
                                                      TextStyle(fontSize: 20),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    l10n.exit,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (won) ...[
                                    const SizedBox(width: 16),
                                    // Play Again button
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        height: 55,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              primaryColor,
                                              Color.lerp(primaryColor,
                                                      Colors.black, 0.3) ??
                                                  primaryColor,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withValues(
                                                  alpha: 0.5),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: onPlayAgain,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    '🚀',
                                                    style:
                                                        TextStyle(fontSize: 24),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      l10n.playAgain,
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: 1.2,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}
