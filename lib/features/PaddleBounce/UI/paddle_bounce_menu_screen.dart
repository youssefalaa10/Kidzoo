import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/logic/paddle_bounce_cubit.dart';
import '../data/models/paddle_bounce_models.dart';
import 'paddle_bounce_game_screen.dart';

class PaddleBounceMenuScreen extends StatelessWidget {
  const PaddleBounceMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.blue.shade900,
                  Colors.indigo.shade900,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Game Title
                      Text(
                        l10n.paddleBounce,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.cyan,
                              blurRadius: 20,
                            ),
                            const Shadow(
                              color: Colors.pink,
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      // Play vs Friend Button
                      _buildMenuButton(
                        context: context,
                        icon: Icons.people,
                        title: l10n.playVsFriend,
                        subtitle: l10n.playWithAFriend,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => BlocProvider(
                                create: (context) => PaddleBounceCubit(
                                  screenWidth: screenSize.width,
                                  screenHeight: screenSize.height,
                                ),
                                child: const PaddleBounceGameScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Play vs AI Button
                      _buildMenuButton(
                        context: context,
                        icon: Icons.smart_toy,
                        title: l10n.playVsAI,
                        subtitle: l10n.challengeTheComputer,
                        color: Colors.orange,
                        onTap: () {
                          _showAIDifficultyDialog(context, screenSize);
                        },
                      ),
                      const SizedBox(height: 40),
                      // Back Button
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: Text(
                          l10n.mainMenu,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAIDifficultyDialog(BuildContext context, Size screenSize) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.selectAIDifficulty,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption(
              context: dialogContext,
              difficulty: AIDifficulty.easy,
              title: l10n.easy,
              description: l10n.easy,
              color: Colors.green,
              screenSize: screenSize,
            ),
            const SizedBox(height: 16),
            _buildDifficultyOption(
              context: dialogContext,
              difficulty: AIDifficulty.hard,
              title: l10n.hard,
              description: l10n.hard,
              color: Colors.red,
              screenSize: screenSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption({
    required BuildContext context,
    required AIDifficulty difficulty,
    required String title,
    required String description,
    required Color color,
    required Size screenSize,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => BlocProvider(
              create: (context) => PaddleBounceCubit(
                screenWidth: screenSize.width,
                screenHeight: screenSize.height,
                gameMode: PaddleBounceGameMode.vsAI,
                aiDifficulty: difficulty,
              ),
              child: const PaddleBounceGameScreen(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
