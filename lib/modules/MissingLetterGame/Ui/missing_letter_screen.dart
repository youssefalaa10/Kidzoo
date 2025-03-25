import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidzoo/modules/MissingLetterGame/Data/Logic/cubit/missing_letter_cubit.dart';
import 'package:kidzoo/modules/MissingLetterGame/Data/Logic/cubit/missing_letter_state.dart';

import '../Data/Model/word_model.dart';

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
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
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
    final initialWord = Word(
      word: "Apple",
      missingIndex: 0,
      options: ["A", "B", "C", "D"],
      correctLetter: "A",
    );

    return BlocProvider(
      create: (context) => MissingLetterCubit(initialWord),
      child: BlocConsumer<MissingLetterCubit, MissingLetterState>(
        listener: (context, state) {
          if (state.isCorrect) {
            _celebrationController.forward(from: 0);
            _letterBounceController.forward(from: 0);
          } else if (state.isIncorrect) {
            _shakeController.forward(from: 0);
          }
        },
        builder: (context, state) {
          final gameCubit = context.read<MissingLetterCubit>();
          final word = state.currentWord;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
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
                            stops: [0.1, 0.4, 0.7, 1.0],
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
                        color: Colors.white.withOpacity(0.1),
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
                          begin: Offset(0.8, 0.8),
                          end: Offset(1.0, 1.0),
                          duration: Duration(seconds: 4 + index),
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(
                          duration: Duration(seconds: 1),
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
                        SizedBox(height: 30),
                        // Game title
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'Missing Letter',
                            style: GoogleFonts.daiBannaSil(
                              fontSize: 32,
                              color: Colors.white,
                              shadows: [
                                Shadow(
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

                        SizedBox(height: 60),

                        // Word display
                        AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                state.isIncorrect ? _shakeAnimation.value : 0,
                                0,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      List.generate(word.word.length, (index) {
                                    bool isMissingLetter =
                                        index == word.missingIndex;

                                    Widget letterWidget = Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        isMissingLetter
                                            ? (state.isCorrect
                                                ? word.correctLetter
                                                : '_')
                                            : word.word[index],
                                        style: GoogleFonts.comicNeue(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: isMissingLetter
                                              ? Colors.green
                                              : Color(0xFF6C63FF),
                                        ),
                                      ),
                                    );

                                    if (isMissingLetter && state.isCorrect) {
                                      return AnimatedBuilder(
                                        animation: _letterBounceController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: Curves.elasticOut.transform(
                                              _letterBounceController.value,
                                            ),
                                            child: letterWidget,
                                          );
                                        },
                                      );
                                    }

                                    return letterWidget;
                                  }),
                                ),
                              ),
                            );
                          },
                        )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .slideY(begin: 0.2, end: 0),
                        SizedBox(height: 60),

                        // Letter options
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: word.options.asMap().entries.map((entry) {
                            int index = entry.key;
                            String option = entry.value;

                            return AnimatedOpacity(
                              opacity: state.isCorrect ? 0.5 : 1.0,
                              duration: Duration(milliseconds: 300),
                              child: GestureDetector(
                                onTap: state.isCorrect
                                    ? null
                                    : () => gameCubit.selectOption(option),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
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
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
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
                                  duration: Duration(milliseconds: 400),
                                )
                                .slideY(
                                  begin: 0.5,
                                  end: 0,
                                  delay: Duration(milliseconds: 100 * index),
                                  duration: Duration(milliseconds: 400),
                                  curve: Curves.easeOutQuad,
                                );
                          }).toList(),
                        ),

                        SizedBox(height: 50),

                        // Play again button
                        if (state.isCorrect)
                          GestureDetector(
                            onTap: () {
                              //TODO
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
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
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Next Word',
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
                                delay: Duration(milliseconds: 800),
                                duration: Duration(milliseconds: 400),
                              )
                              .scale(
                                begin: Offset(0.8, 0.8),
                                end: Offset(1.0, 1.0),
                                delay: Duration(milliseconds: 800),
                                duration: Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                              ),
                      ],
                    ),
                  ),
                ),

                // Feedback indicators
                if (state.isCorrect)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    right: 20,
                    child: RotationTransition(
                      turns: Tween(begin: -0.05, end: 0.05)
                          .animate(_celebrationController),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Correct!',
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
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                        ),
                  ),
                if (state.isIncorrect)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    right: 20,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Try Again!',
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
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
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
