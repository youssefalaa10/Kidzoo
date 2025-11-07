import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/base/protected_game_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/shared/style/image_manager.dart';
import '../Data/Logic/cubit/math_game_cubit.dart';
import '../Data/Logic/cubit/math_game_state.dart';

class MathGame extends ProtectedGameScreen {
  const MathGame({required super.level, super.key});

  @override
  _MathGameState createState() => _MathGameState();
}

class _MathGameState extends ProtectedGameScreenState<MathGame>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  @override
  void onGameInit() {
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MathGameCubit(level: widget.level),
      child: BlocConsumer<MathGameCubit, MathGameState>(
        listener: (context, state) {
          if (state.starsEarned > 0 && state.currentQuestionIndex > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).superDuper),
                backgroundColor: Colors.greenAccent,
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }
          if (state.isCompleted) {
            _confettiController.play();
            final l10n = AppLocalizations.of(context);
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
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade100,
                        Colors.purple.shade50,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated trophy icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Transform.rotate(
                                angle: (1 - value) * 0.5,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.amber.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events,
                                    size: 60,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          l10n.mathWizard,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Stars earned
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                l10n.youEarned,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmallScreen =
                                      constraints.maxWidth < 300;
                                  final starSize = isSmallScreen ? 30.0 : 40.0;
                                  final starPadding = isSmallScreen ? 2.0 : 4.0;
                                  return Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: starPadding,
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        index < state.starsEarned
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: starSize,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${state.starsEarned} ${l10n.stars}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action buttons
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 300;
                            return isSmallScreen
                                ? Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            Navigator.of(context).pop(true);
                                          },
                                          icon: const Icon(Icons.arrow_forward),
                                          label: Text(l10n.continueToNextLevel),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            context
                                                .read<MathGameCubit>()
                                                .close();
                                            Navigator.pushReplacement<void,
                                                void>(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (context) => MathGame(
                                                    level: widget.level),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.refresh),
                                          label: Text(l10n.playAgain),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.purple,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            side: BorderSide(
                                                color: Colors.purple.shade300,
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            context
                                                .read<MathGameCubit>()
                                                .close();
                                            Navigator.pushReplacement<void,
                                                void>(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (context) => MathGame(
                                                    level: widget.level),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.refresh),
                                          label: Text(l10n.playAgain),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.purple,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            side: BorderSide(
                                                color: Colors.purple.shade300,
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            Navigator.of(context).pop(true);
                                          },
                                          icon: const Icon(Icons.arrow_forward),
                                          label: Text(l10n.continueToNextLevel),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
        },
        builder: (context, state) {
          if (state.questions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentQuestion = state.questions[state.currentQuestionIndex];

          return Scaffold(
            body: Stack(
              children: [
                // Background image
                Image.asset(
                  ImageManager.learningBg,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  fit: BoxFit.cover,
                ),
                SafeArea(
                  child: Stack(
                    children: [
                      // Main Content
                      Column(
                        children: [
                          // Top Bar with Progress
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context).mathMagic,
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${state.currentQuestionIndex + 1}/5',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          //TODO
                          // Character Mascot
                          // AnimatedBuilder(
                          //   animation: _characterAnimation,
                          //   builder: (context, child) {
                          //     return Transform.translate(
                          //       offset: Offset(
                          //           0, 10 * (1 - _characterAnimation.value)),
                          //       child: Image.asset(
                          //         _isHappy
                          //             ? 'assets/images/happy_monkey.png' // Add a happy monkey image
                          //             : 'assets/images/sad_monkey.png', // Add a sad monkey image
                          //         height: 120,
                          //       ),
                          //     );
                          //   },
                          // ),
                          const SizedBox(height: 20),
                          // Question Card
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        currentQuestion['question'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      // Answer Options
                                      GridView.count(
                                        crossAxisCount: 2,
                                        shrinkWrap: true,
                                        childAspectRatio: 1.2,
                                        mainAxisSpacing: 15,
                                        crossAxisSpacing: 15,
                                        children: currentQuestion['options']
                                            .asMap()
                                            .entries
                                            .map<Widget>(
                                                (MapEntry<int, dynamic> entry) {
                                          final option = entry.value;
                                          final index = entry.key;
                                          return _FunnyOptionButton(
                                            option: option,
                                            index: index,
                                            isCorrect: option ==
                                                currentQuestion[
                                                    'correctAnswer'],
                                            onPressed: () {
                                              context
                                                  .read<MathGameCubit>()
                                                  .checkAnswer(option);
                                              if (option !=
                                                  currentQuestion[
                                                      'correctAnswer']) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        AppLocalizations.of(
                                                                context)
                                                            .oopsieTryAgain),
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    duration: const Duration(
                                                        seconds: 1),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Stars Display
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (index) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: index < state.starsEarned
                                        ? const Icon(
                                            Icons.star,
                                            key: ValueKey('filled'),
                                            color: Colors.yellow,
                                            size: 35,
                                          )
                                        : const Icon(
                                            Icons.star_border,
                                            key: ValueKey('empty'),
                                            color: Colors.white70,
                                            size: 35,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Confetti
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          colors: const [
                            Colors.red,
                            Colors.blue,
                            Colors.green,
                            Colors.yellow,
                            Colors.pink,
                            Colors.orange,
                          ],
                          numberOfParticles: 50,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom Widget for Funny Animated Option Buttons
class _FunnyOptionButton extends StatefulWidget {
  const _FunnyOptionButton({
    required this.option,
    required this.index,
    required this.isCorrect,
    required this.onPressed,
  });
  final int option;
  final int index;
  final bool isCorrect;
  final VoidCallback onPressed;

  @override
  __FunnyOptionButtonState createState() => __FunnyOptionButtonState();
}

class __FunnyOptionButtonState extends State<_FunnyOptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut,
      ),
    );
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.primaries[widget.index % Colors.primaries.length],
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          shadowColor: Colors.black26,
        ),
        child: Text(
          '${widget.option}',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
