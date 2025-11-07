import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/localization/language_provider.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';

import '../data/logic/color_learn_cubit.dart';
import '../data/logic/color_learn_state.dart';
import '../data/model/color_model.dart';
import 'widgets/color_ball.dart';
import 'widgets/color_container.dart';
import 'widgets/game_complete_dialog.dart';

class ColorLearnScreen extends StatefulWidget {
  const ColorLearnScreen({super.key});

  @override
  State<ColorLearnScreen> createState() => _ColorLearnScreenState();
}

class _ColorLearnScreenState extends State<ColorLearnScreen>
    with TTSMusicMixin, TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _sparkleController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late FlutterTts _flutterTts;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _flutterTts = FlutterTts();
    _initTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCubit = context.read<LanguageCubit>();
    _currentLanguage = languageCubit.state.languageCode;

    // Initialize game with level 1
    if (context.read<ColorLearnCubit>().state.availableColors.isEmpty) {
      context.read<ColorLearnCubit>().initializeGame(1, _currentLanguage);
    }
  }

  Future<void> _initTts() async {
    try {
      if (_currentLanguage == 'ar') {
        // Try multiple Arabic language codes for better compatibility
        final arabicCodes = ['ar-SA', 'ar', 'ar-EG', 'ar-AE'];
        bool languageSet = false;
        for (final code in arabicCodes) {
          final result = await _flutterTts.setLanguage(code);
          if (result == 1) {
            languageSet = true;
            break;
          }
        }
        if (!languageSet) {
          // Fallback to English if Arabic is not available
          await _flutterTts.setLanguage('en-US');
        }
      } else {
        await _flutterTts.setLanguage('en-US');
      }
      await _flutterTts.setPitch(1.2);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _speakColor(ColorModel color) async {
    try {
      final colorName = color.getColorName(_currentLanguage);
      await _initTts();
      await _flutterTts.speak(colorName);
      // Wait for TTS to complete before resuming
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      // Handle error silently
    }
  }

  void _onColorMatched(ColorModel color) {
    context.read<ColorLearnCubit>().matchColor(color);
    _speakColor(color);
    _sparkleController.forward(from: 0);
    _confettiController.play();

    // Reset sparkle animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _sparkleController.reset();
      }
    });
  }

  void _onWrongMatch() {
    context.read<ColorLearnCubit>().showWrongFeedback();
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _shakeController.reset();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _sparkleController.dispose();
    _shakeController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            ImageManager.homeBackground,
            width: screenSize.width,
            height: screenSize.height,
            fit: BoxFit.cover,
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
          SafeArea(
            child: BlocConsumer<ColorLearnCubit, ColorLearnState>(
              listener: (context, state) {
                if (state.isGameComplete) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => GameCompleteDialog(
                          score: state.score,
                          onPlayAgain: () {
                            context.read<ColorLearnCubit>().resetGame();
                            context.read<ColorLearnCubit>().initializeGame(
                                  state.level,
                                  _currentLanguage,
                                );
                            Navigator.of(context).pop();
                          },
                          onExit: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    }
                  });
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    // App Bar
                    _buildAppBar(context, l10n, state),
                    // Game Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Left side: Color containers (buckets)
                            Expanded(
                              flex: 2,
                              child: _buildContainersArea(context, state),
                            ),
                            const SizedBox(width: 16),
                            // Right side: Color balls
                            Expanded(
                              child: _buildBallsArea(context, state),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, AppLocalizations l10n, ColorLearnState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.green),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              l10n.colorLearn,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${l10n.score}: ${state.score}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainersArea(BuildContext context, ColorLearnState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: state.availableColors.length,
        itemBuilder: (context, index) {
          final color = state.availableColors[index];
          final isMatched = state.matchedColors.contains(color);
          final isShaking = state.showWrongFeedback && !isMatched;

          return AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: isShaking
                    ? Offset(
                        _shakeAnimation.value *
                            math.sin(_shakeAnimation.value * 10),
                        0,
                      )
                    : Offset.zero,
                child: ColorContainer(
                  color: color,
                  isMatched: isMatched,
                  languageCode: _currentLanguage,
                  onMatched: () => _onColorMatched(color),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBallsArea(BuildContext context, ColorLearnState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.remainingColors.length,
        itemBuilder: (context, index) {
          final color = state.remainingColors[index];
          return ColorBall(
            color: color,
            onMatched: _onColorMatched,
            onWrongMatch: _onWrongMatch,
            availableColors: state.availableColors,
          );
        },
      ),
    );
  }
}
