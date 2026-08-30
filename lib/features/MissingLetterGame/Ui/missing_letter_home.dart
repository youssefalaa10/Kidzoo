import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/widgets/fluid_container.dart';
import '../Data/Logic/cubit/missing_letter_cubit.dart';
import '../Data/game_storage.dart';
import '../Data/word_list.dart';
import 'missing_letter_screen.dart';

class MissingLetterHome extends StatefulWidget {
  const MissingLetterHome({super.key});

  @override
  State<MissingLetterHome> createState() => _MissingLetterHomeState();
}

class _MissingLetterHomeState extends State<MissingLetterHome> {
  final MissingLetterStorage _storage = MissingLetterStorage();
  bool _hasProgress = false;
  int _currentIndex = 0;
  int _currentScore = 0;
  int _bestScore = 0;
  int _completedWords = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hasProgress = await _storage.hasProgress();
    final currentIndex = await _storage.getCurrentIndex();
    final currentScore = await _storage.getTotalScore();
    final bestScore = await _storage.getBestScore();
    final completedWords = await _storage.getCompletedCount();

    setState(() {
      _hasProgress = hasProgress;
      _currentIndex = currentIndex;
      _currentScore = currentScore;
      _bestScore = bestScore;
      _completedWords = completedWords;
    });
  }

  void _startNewGame() {
    final languageCubit = context.read<LanguageCubit>();
    final languageCode = languageCubit.state.languageCode;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) => MissingLetterCubit(
            languageCode: languageCode,
          ),
          child: const MissingLetterScreen(),
        ),
      ),
    );
  }

  void _continueGame() {
    final languageCubit = context.read<LanguageCubit>();
    final languageCode = languageCubit.state.languageCode;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BlocProvider(
          create: (context) => MissingLetterCubit(
            initialIndex: _currentIndex,
            initialScore: _currentScore,
            languageCode: languageCode,
          )..loadProgress(),
          child: const MissingLetterScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BackgroundResolver(context, BackgroundType.game).resolveBackground()!),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: FluidContainer(
            padding: EdgeInsets.zero,
            child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button and language toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => _showLanguageDialog(context),
                      icon: const Icon(Icons.language, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Title
                Center(
                  child: Text(
                    l10n.missingLetter,
                    style: GoogleFonts.daiBannaSil(
                      fontSize: 42,
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    l10n.learnTheAlphabet,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Stats Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.yourProgress,
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Icons.emoji_events,
                            label: l10n.bestScore,
                            value: '$_bestScore',
                            color: Colors.amber,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey.shade300,
                          ),
                          _buildStatItem(
                            icon: Icons.check_circle,
                            label: l10n.completed,
                            value: '$_completedWords/${WordList.getTotalWords()}',
                            color: Colors.green,
                          ),
                        ],
                      ),
                      if (_hasProgress) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.currentScore,
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_currentScore',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                // Action Buttons
                if (_hasProgress)
                  _buildButton(
                    label: l10n.continueGame,
                    icon: Icons.play_arrow_rounded,
                    colors: const [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    onPressed: _continueGame,
                  ),
                if (_hasProgress) const SizedBox(height: 16),
                _buildButton(
                  label: l10n.newGame,
                  icon: Icons.refresh_rounded,
                  colors: const [Color(0xFFFF9800), Color(0xFFFF5722)],
                  onPressed: _startNewGame,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCubit = context.read<LanguageCubit>();
    final isArabic = languageCubit.isArabic;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.blue, size: 32),
            const SizedBox(width: 12),
            Text(
              l10n.changeLanguage,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          isArabic ? l10n.translateToEnglish : l10n.translateToArabic,
          style: GoogleFonts.nunito(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.no,
              style: GoogleFonts.nunito(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              languageCubit.toggleLanguage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.yes,
              style: GoogleFonts.nunito(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
