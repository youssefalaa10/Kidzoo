import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kidzo/core/localization/language_provider.dart';
import 'package:kidzo/features/MissingLetterGame/Data/Logic/cubit/missing_letter_cubit.dart';
import 'package:kidzo/features/MissingLetterGame/Data/Logic/cubit/missing_letter_state.dart';

import '../../../core/localization/app_localizations.dart';

class MissingLetterScreen extends StatefulWidget {
  const MissingLetterScreen({super.key});

  @override
  State<MissingLetterScreen> createState() => _MissingLetterScreenState();
}

class _MissingLetterScreenState extends State<MissingLetterScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundScaleAnimation;
  late AnimationController _celebrationController;
  late AnimationController _letterBounceController;

  final List<Color> _backgroundColors = [
    const Color(0xFF9C27B0),
    const Color(0xFF3F51B5),
    const Color(0xFF2196F3),
    const Color(0xFF00BCD4),
  ];

  @override
  void initState() {
    super.initState();

    // Shake animation for incorrect answers
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticInOut,
      ),
    );

    // Background animation
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    _backgroundScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Celebration animation
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Letter bounce animation
    _letterBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _backgroundAnimationController.dispose();
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
        if (state.allLettersFilled) {
          _celebrationController.forward(from: 0);
          _letterBounceController.forward(from: 0);
        } else if (state.isIncorrect) {
          _shakeController.forward(from: 0);
        }
      },
      builder: (context, state) {
        final gameCubit = context.read<MissingLetterCubit>();
        final word = state.currentWord;

        // Update language in cubit if needed
        if (state.languageCode != (isArabic ? 'ar' : 'en')) {
          gameCubit.updateLanguage(isArabic ? 'ar' : 'en');
        }

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => _showExitDialog(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.pause_rounded, color: Colors.white),
                  onPressed: () => _showExitDialog(context),
                ),
              ],
            ),
            body: Stack(
              children: [
                // Animated background
                AnimatedBuilder(
                  animation: _backgroundAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _backgroundScaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _backgroundColors,
                            stops: const [0.1, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Animated background elements
                ...List.generate(
                  10,
                  (index) => Positioned(
                    left: (MediaQuery.of(context).size.width / 10) * index,
                    top:
                        (MediaQuery.of(context).size.height / 10) * (index % 5),
                    child: Container(
                      width: 50,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .moveY(
                          begin: 0,
                          end: 50,
                          duration: Duration(seconds: 6 + index),
                          curve: Curves.easeInOut,
                        )
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: Duration(seconds: 4 + index),
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(
                          duration: const Duration(seconds: 1),
                        ),
                  ),
                ),

                // Celebration animation
                // if (state.isCorrect)
                //   Positioned.fill(
                //     child: IgnorePointer(
                //       child: LottieBuilder.network(
                //         'https://assets10.lottiefiles.com/packages/lf20_xlkxtmul.json',
                //         controller: _celebrationController,
                //         fit: BoxFit.cover,
                //       ),
                //     ),
                //   ),

                // Game content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Progress indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${state.score}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${state.completedWords}/${state.totalWords}',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: state.progress,
                            minHeight: 8,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Game title
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            l10n.missingLetter,
                            style: GoogleFonts.daiBannaSil(
                              fontSize: 32,
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
                        )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .slideY(begin: -0.2, end: 0),

                        const SizedBox(height: 60),

                        // Word display
                        Directionality(
                          textDirection: isArabic ? TextDirection.ltr : TextDirection.ltr,
                          child: AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  state.isIncorrect ? _shakeAnimation.value : 0,
                                  0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final letterCount = word.word.length;
                                      final availableWidth = constraints.maxWidth;
                                      final fontSize =
                                          (availableWidth / letterCount * 0.6)
                                              .clamp(20.0, 40.0);
                                      final horizontalPadding =
                                          (availableWidth / letterCount * 0.1)
                                              .clamp(2.0, 8.0);
                          
                                      return Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: horizontalPadding,
                                        children: List.generate(word.word.length,
                                            (index) {
                                          final bool isMissingLetter =
                                              word.missingIndices.contains(index);
                                          final filledLetter =
                                              state.filledLetters[index];
                                          final isFilled = filledLetter != null;
                          
                                          final Widget letterWidget = Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: horizontalPadding),
                                            child: Text(
                                              isMissingLetter
                                                  ? (isFilled
                                                      ? filledLetter
                                                      : '_')
                                                  : word.word[index],
                                              style: GoogleFonts.comicNeue(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: isMissingLetter
                                                    ? (isFilled
                                                        ? Colors.green
                                                        : Colors.orange)
                                                    : const Color(0xFF6C63FF),
                                              ),
                                            ),
                                          );
                          
                                          if (isMissingLetter &&
                                              isFilled &&
                                              state.allLettersFilled) {
                                            return AnimatedBuilder(
                                              animation: _letterBounceController,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale:
                                                      Curves.elasticOut.transform(
                                                    _letterBounceController.value,
                                                  ),
                                                  child: letterWidget,
                                                );
                                              },
                                            );
                                          }
                          
                                          return letterWidget;
                                        }),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .slideY(begin: 0.2, end: 0),
                        ),
                        const SizedBox(height: 60),

                        // Letter options
                        Directionality(
                          textDirection: isArabic ? TextDirection.ltr : TextDirection.ltr,
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: word.options.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final String option = entry.value;
                          
                              return AnimatedOpacity(
                                opacity: state.isCorrect ? 0.5 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: GestureDetector(
                                  onTap: state.isCorrect
                                      ? null
                                      : () => gameCubit.selectOption(option),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF9800),
                                          Color(0xFFFF5722),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange
                                              .withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        option,
                                        style: GoogleFonts.daiBannaSil(
                                          fontSize: 36,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 100 * index),
                                    duration: const Duration(milliseconds: 400),
                                  )
                                  .slideY(
                                    begin: 0.5,
                                    end: 0,
                                    delay: Duration(milliseconds: 100 * index),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutQuad,
                                  );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Next/Complete button
                        if (state.allLettersFilled)
                          GestureDetector(
                            onTap: () {
                              final cubit = context.read<MissingLetterCubit>();
                              if (state.isGameComplete) {
                                // Show completion dialog
                                _showCompletionDialog(context, state);
                              } else {
                                cubit.nextWord();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF8BC34A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    state.currentWordIndex >=
                                            state.totalWords - 1
                                        ? l10n.complete
                                        : l10n.nextWord,
                                    style: GoogleFonts.nunito(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                delay: const Duration(milliseconds: 800),
                                duration: const Duration(milliseconds: 400),
                              )
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                delay: const Duration(milliseconds: 800),
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                              ),
                      ],
                    ),
                  ),
                ),

                // Feedback indicators
                if (state.allLettersFilled)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    right: 20,
                    child: RotationTransition(
                      turns: Tween(begin: -0.05, end: 0.05)
                          .animate(_celebrationController),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              l10n.correct,
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideX(
                          begin: 1.0,
                          end: 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                        ),
                  ),
                if (state.isIncorrect)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            l10n.tryAgain,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideX(
                          begin: 1.0,
                          end: 0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                        ),
                  ),
              ],
            ),
          ),
        );
      },
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
            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.congratulations,
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.finalScore,
                        style: GoogleFonts.nunito(fontSize: 16),
                      ),
                      Text(
                        '${state.score}',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
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
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text(
              l10n.done,
              style: GoogleFonts.nunito(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<MissingLetterCubit>().resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.playAgain,
              style: GoogleFonts.nunito(fontSize: 16),
            ),
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
            const Icon(Icons.pause_circle_outline,
                color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Text(
              l10n.pauseGame,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.doYouWantToExit,
              style: GoogleFonts.nunito(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.currentScore,
                        style: GoogleFonts.nunito(fontSize: 14),
                      ),
                      Text(
                        '${state.score}',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.progress,
                        style: GoogleFonts.nunito(fontSize: 14),
                      ),
                      Text(
                        '${state.completedWords}/${state.totalWords}',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.yourProgressWillBeSaved,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.resume,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Exit to home
            },
            icon: const Icon(Icons.exit_to_app),
            label: Text(
              l10n.exitAndSave,
              style: GoogleFonts.nunito(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
