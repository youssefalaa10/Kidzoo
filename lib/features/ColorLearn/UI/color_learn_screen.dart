import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/localization/language_provider.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';

import '../data/logic/color_learn_cubit.dart';
import '../data/logic/color_learn_state.dart';
import '../data/model/color_model.dart';
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
  late AnimationController _rainbowController;
  late AnimationController _bounceController;
  late Animation<double> _rainbowAnimation;
  late Animation<double> _bounceAnimation;
  late FlutterTts _flutterTts;
  String _currentLanguage = 'en';
  ColorModel? _selectedColor;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _rainbowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rainbowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rainbowController, curve: Curves.easeInOut),
    );
    _bounceAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _flutterTts = FlutterTts();
    _initTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCubit = context.read<LanguageCubit>();
    _currentLanguage = languageCubit.state.languageCode;

    if (context.read<ColorLearnCubit>().state.availableColors.isEmpty) {
      context.read<ColorLearnCubit>().initializeGame(1, _currentLanguage);
    }
  }

  Future<void> _initTts() async {
    try {
      if (_currentLanguage == 'ar') {
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
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      // Handle error silently
    }
  }

  void _onColorSelected(ColorModel color) {
    setState(() {
      _selectedColor = color;
    });
    _speakColor(color);
  }

  void _onRainbowSegmentTapped(ColorModel targetColor) {
    if (_selectedColor == null) return;

    if (_selectedColor!.colorValue == targetColor.colorValue) {
      // Correct match!
      context.read<ColorLearnCubit>().matchColor(targetColor);
      _confettiController.play();
      setState(() {
        _selectedColor = null;
      });
    } else {
      // Wrong match
      context.read<ColorLearnCubit>().showWrongFeedback();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _sparkleController.dispose();
    _rainbowController.dispose();
    _bounceController.dispose();
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
          // Sky gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.lightBlue.shade100,
                  Colors.blue.shade50,
                  Colors.green.shade50,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Animated clouds
          ...List.generate(5, (index) {
            return Positioned(
              left: (index * 200.0) % screenSize.width,
              top: 50 + (index % 3) * 80.0,
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        _bounceAnimation.value * (index % 2 == 0 ? 1 : -1), 0),
                    child: Opacity(
                      opacity: 0.3,
                      child: Text(
                        '☁️',
                        style: TextStyle(fontSize: 60 + (index % 3) * 20),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          // Sun
          Positioned(
            top: 30,
            right: 30,
            child: AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _sparkleController.value * 2 * math.pi * 0.1,
                  child: const Text(
                    '☀️',
                    style: TextStyle(fontSize: 50),
                  ),
                );
              },
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 8,
              minBlastForce: 3,
              emissionFrequency: 0.03,
              numberOfParticles: 30,
              gravity: 0.1,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
                Colors.pink,
              ],
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
                final progress =
                    state.matchedColors.length / state.availableColors.length;
                return Column(
                  children: [
                    // Fun Header
                    _buildFunHeader(context, l10n, state, progress),
                    // Rainbow Coloring Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildRainbowArea(context, state),
                      ),
                    ),
                    // Color Palette
                    _buildColorPalette(context, state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunHeader(BuildContext context, AppLocalizations l10n,
      ColorLearnState state, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade300,
            Colors.pink.shade300,
            Colors.purple.shade300,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              // Character
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value * 0.3),
                    child: const Text(
                      '🎨',
                      style: TextStyle(fontSize: 40),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.colorLearn,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                    ),
                    Text(
                      'Color the Rainbow! 🌈',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Score badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade400,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '${state.score}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 2, color: Colors.black26),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  width: MediaQuery.of(context).size.width * progress * 0.85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.lightGreen.shade400,
                        Colors.green.shade300,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}% Complete! 🎉',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 2, color: Colors.black26),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainbowArea(BuildContext context, ColorLearnState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.blue.shade50.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.2),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Instruction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade200,
                  Colors.pink.shade200,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👆', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _selectedColor == null
                        ? 'Choose a color, then tap the rainbow! 🌈'
                        : 'Now tap the matching rainbow segment!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('👆', style: TextStyle(fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Rainbow
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rainbowSize =
                      math.min(constraints.maxWidth, constraints.maxHeight) *
                          0.8;
                  return AnimatedBuilder(
                    animation: _rainbowAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_rainbowAnimation.value * 0.05),
                        child: GestureDetector(
                          onTapDown: (details) {
                            final localPosition = details.localPosition;
                            final center =
                                Offset(rainbowSize / 2, rainbowSize / 2);
                            final radius = rainbowSize * 0.35;
                            final distance = (localPosition - center).distance;

                            // Check if tap is on rainbow
                            if (distance >= radius - 40 &&
                                distance <= radius + 40) {
                              final angle = math.atan2(
                                localPosition.dy - center.dy,
                                localPosition.dx - center.dx,
                              );
                              final normalizedAngle =
                                  (angle + math.pi / 2 + 2 * math.pi) %
                                      (2 * math.pi);
                              final segmentAngle =
                                  (2 * math.pi) / state.availableColors.length;
                              final segmentIndex =
                                  (normalizedAngle / segmentAngle).floor();

                              if (segmentIndex >= 0 &&
                                  segmentIndex < state.availableColors.length) {
                                _onRainbowSegmentTapped(
                                    state.availableColors[segmentIndex]);
                              }
                            }
                          },
                          child: CustomPaint(
                            size: Size(rainbowSize, rainbowSize),
                            painter: RainbowPainter(
                              colors: state.availableColors,
                              matchedColors: state.matchedColors,
                              selectedColor: _selectedColor,
                              showWrongFeedback: state.showWrongFeedback,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context, ColorLearnState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.pink.shade50.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎨 Color Palette - لوحة الألوان',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: state.remainingColors.map((color) {
              final isSelected = _selectedColor?.colorValue == color.colorValue;
              return AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? 1.2 : 1.0,
                    child: GestureDetector(
                      onTap: () => _onColorSelected(color),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Color(color.colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade300,
                            width: isSelected ? 4 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(color.colorValue)
                                  .withValues(alpha: isSelected ? 0.6 : 0.4),
                              blurRadius: isSelected ? 15 : 10,
                              spreadRadius: isSelected ? 3 : 2,
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class RainbowPainter extends CustomPainter {
  RainbowPainter({
    required this.colors,
    required this.matchedColors,
    this.selectedColor,
    this.showWrongFeedback = false,
  });

  final List<ColorModel> colors;
  final List<ColorModel> matchedColors;
  final ColorModel? selectedColor;
  final bool showWrongFeedback;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final segmentAngle = (2 * math.pi) / colors.length;
    final segmentWidth = radius * 0.15;

    for (int i = 0; i < colors.length; i++) {
      final color = colors[i];
      final isMatched = matchedColors.contains(color);
      final isSelected = selectedColor?.colorValue == color.colorValue;
      final startAngle = (i * segmentAngle) - (math.pi / 2);
      final sweepAngle = segmentAngle * 0.9;

      // Draw rainbow segment
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = segmentWidth
        ..strokeCap = StrokeCap.round;

      if (isMatched) {
        // Filled with color
        paint.color = Color(color.colorValue);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = segmentWidth;
      } else {
        // Empty segment with outline
        paint.color = Colors.grey.shade300;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = segmentWidth * 0.5;
      }

      // Draw arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Draw color name
      final textAngle = startAngle + (sweepAngle / 2);
      final textRadius = radius + segmentWidth;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: color.colorNameEn,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isMatched ? Color(color.colorValue) : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );

      // Highlight if selected
      if (isSelected && !isMatched) {
        final highlightPaint = Paint()
          ..color = Color(color.colorValue).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = segmentWidth * 1.5;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant RainbowPainter oldDelegate) {
    return oldDelegate.matchedColors.length != matchedColors.length ||
        oldDelegate.selectedColor?.colorValue != selectedColor?.colorValue ||
        oldDelegate.showWrongFeedback != showWrongFeedback;
  }
}
