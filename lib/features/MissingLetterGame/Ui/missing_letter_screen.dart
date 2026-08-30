import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/features/MissingLetterGame/Data/Logic/cubit/missing_letter_cubit.dart';
import 'package:kidzo/features/MissingLetterGame/Data/Logic/cubit/missing_letter_state.dart';
import 'package:kidzo/features/MissingLetterGame/Data/Model/word_model.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/widgets/fluid_container.dart';
import '../../../shared/widgets/game_exit_button.dart';

class MissingLetterScreen extends StatefulWidget {
  const MissingLetterScreen({super.key});

  @override
  State<MissingLetterScreen> createState() => _MissingLetterScreenState();
}

class _MissingLetterScreenState extends State<MissingLetterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  late final AnimationController _celebrationController;
  late final AnimationController _letterBounceController;

  bool _completionDialogShown = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _letterBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _celebrationController.dispose();
    _letterBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCubit = context.read<LanguageCubit>();
    final isArabic = languageCubit.isArabic;

    return BlocConsumer<MissingLetterCubit, MissingLetterState>(
      listener: (context, state) {
        if (state.isCorrect) {
          _celebrationController.forward(from: 0);
          _letterBounceController.forward(from: 0);
        } else if (state.isIncorrect) {
          _shakeController.forward(from: 0);
        }
        if (state.isGameComplete && !_completionDialogShown) {
          _completionDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showCompletionDialog(context, state);
          });
        }
      },
      builder: (context, state) {
        final gameCubit = context.read<MissingLetterCubit>();
        final word = state.currentWord;

        if (state.languageCode != (isArabic ? 'ar' : 'en')) {
          gameCubit.updateLanguage(isArabic ? 'ar' : 'en');
        }

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: _buildHeader(context, l10n, state),
            body: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          BackgroundResolver(context, BackgroundType.game).resolveBackground()!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SafeArea(
                  child: FluidContainer(
                    padding: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;
                        final availableWidth = constraints.maxWidth;
                        final verticalGap = (availableHeight * 0.03).clamp(8.0, 28.0);

                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: (availableWidth * 0.05).clamp(12.0, 32.0),
                            vertical: verticalGap,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: verticalGap),
                              _buildWordCard(context, state, word, isArabic, availableWidth, availableHeight),
                              SizedBox(height: verticalGap * 1.5),
                              _buildLetterOptions(context, gameCubit, state, word, availableWidth),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (state.isCorrect)
                  _buildFloatingFeedback(
                    context,
                    text: l10n.positiveFeedbackMessages[state.positiveFeedbackIndex],
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                if (state.isIncorrect)
                  _buildFloatingFeedback(
                    context,
                    text: l10n.gentleFeedbackMessages[state.negativeFeedbackIndex],
                    color: Colors.redAccent,
                    icon: Icons.favorite,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildHeader(
      BuildContext context, AppLocalizations l10n, MissingLetterState state) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: GameExitButton(onExit: () => _showExitDialog(context)),
      ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final titleSize = (constraints.maxWidth * 0.09).clamp(16.0, 24.0);
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.missingLetter,
              style: GoogleFonts.daiBannaSil(
                fontSize: titleSize,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 3),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        _HeaderChip(
          icon: Icons.trending_up_rounded,
          label: l10n.currentLevelShort(state.currentLevel),
        ),
        const SizedBox(width: 8),
        _HeaderChip(icon: Icons.star_rounded, label: '${state.score}', iconColor: Colors.amber),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    MissingLetterState state,
    Word word,
    bool isArabic,
    double availableWidth,
    double availableHeight,
  ) {
    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: state.progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          ),
        ),
        SizedBox(height: (availableHeight * 0.03).clamp(10.0, 24.0)),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(state.isIncorrect ? _shakeAnimation.value : 0, 0),
              child: child,
            );
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: min(availableWidth, 560)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all((availableWidth * 0.05).clamp(14.0, 24.0)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: state.isCorrect
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.15),
                    blurRadius: state.isCorrect ? 30 : 20,
                    spreadRadius: state.isCorrect ? 5 : 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: (availableHeight * 0.22).clamp(90.0, 180.0)),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(word.imagePath, fit: BoxFit.contain),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
                  SizedBox(height: (availableHeight * 0.03).clamp(12.0, 26.0)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final letterCount = word.word.length;
                      final maxWidth = constraints.maxWidth;
                      final fontSize =
                          (maxWidth / letterCount * 0.55).clamp(20.0, 46.0);
                      final gap = (maxWidth / letterCount * 0.08).clamp(2.0, 8.0);

                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: gap,
                        children: List.generate(word.word.length, (index) {
                          final isMissing = word.missingIndices.contains(index);
                          final filledLetter = state.filledLetters[index];
                          final isFilled = filledLetter != null;
                          final isActive = isMissing &&
                              !isFilled &&
                              word.missingIndices.indexOf(index) == state.activeMissingPosition;

                          final Widget tile = Container(
                            margin: EdgeInsets.symmetric(horizontal: gap / 2),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isMissing
                                      ? (isFilled ? Colors.green : Colors.orange)
                                      : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Text(
                              isMissing ? (isFilled ? filledLetter : '_') : word.word[index],
                              style: GoogleFonts.comicNeue(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: isMissing
                                    ? (isFilled ? Colors.green : Colors.orange)
                                    : const Color(0xFF6C63FF),
                              ),
                            ),
                          );

                          final Widget pulsing = isActive
                              ? tile
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.12, 1.12),
                                    duration: 600.ms,
                                    curve: Curves.easeInOut,
                                  )
                              : tile;

                          if (isMissing && isFilled && state.allLettersFilled) {
                            return AnimatedBuilder(
                              animation: _letterBounceController,
                              builder: (context, child) => Transform.scale(
                                scale: Curves.elasticOut.transform(_letterBounceController.value),
                                child: child,
                              ),
                              child: tile,
                            );
                          }

                          return pulsing;
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
              .animate(key: ValueKey(word.word))
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.15, end: 0),
        ),
      ],
    );
  }

  Widget _buildLetterOptions(
    BuildContext context,
    MissingLetterCubit gameCubit,
    MissingLetterState state,
    Word word,
    double availableWidth,
  ) {
    final options = word.options;
    final tileSize = (availableWidth / max(options.length, 4) * 0.9).clamp(56.0, 84.0);
    final locked = state.isCorrect || state.isTransitioning;

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return AnimatedOpacity(
          key: ValueKey('${word.word}_$option$index'),
          opacity: locked ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: locked ? null : () => gameCubit.selectLetter(option),
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: FittedBox(
                  child: Text(
                    option,
                    style: GoogleFonts.daiBannaSil(fontSize: tileSize * 0.45, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 80 * index), duration: const Duration(milliseconds: 350))
            .slideY(
              begin: 0.4,
              end: 0,
              delay: Duration(milliseconds: 80 * index),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuad,
            );
      }).toList(),
    );
  }

  Widget _buildFloatingFeedback(
    BuildContext context, {
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.12,
      right: 20,
      left: 20,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.5, end: 0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutBack),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, MissingLetterState state) {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
            const SizedBox(height: 10),
            Text(
              l10n.congratulations,
              style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.youCompletedAllWords,
              style: GoogleFonts.nunito(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.finalScore, style: GoogleFonts.nunito(fontSize: 16)),
                  Text(
                    '${state.score}',
                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(l10n.done, style: GoogleFonts.nunito(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _completionDialogShown = false;
              context.read<MissingLetterCubit>().resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.playAgain, style: GoogleFonts.nunito(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final state = context.read<MissingLetterCubit>().state;
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Text(l10n.pauseGame, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.doYouWantToExit, style: GoogleFonts.nunito(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.currentScore, style: GoogleFonts.nunito(fontSize: 14)),
                      Text(
                        '${state.score}',
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.progress, style: GoogleFonts.nunito(fontSize: 14)),
                      Text(
                        '${state.completedWords}/${state.totalWords}',
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.yourProgressWillBeSaved,
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.resume, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.exit_to_app),
            label: Text(l10n.exitAndSave, style: GoogleFonts.nunito(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, this.iconColor = Colors.white});

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
