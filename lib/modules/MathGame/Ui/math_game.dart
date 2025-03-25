import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Data/Logic/cubit/math_game_cubit.dart';
import '../Data/Logic/cubit/math_game_state.dart';

class MathGame extends StatefulWidget {
  const MathGame({super.key});

  @override
  _MathGameState createState() => _MathGameState();
}

class _MathGameState extends State<MathGame> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _characterController;
  late Animation<double> _characterAnimation;
  bool _isHappy = true; // For character expression

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Animation for character
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _characterAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _characterController, curve: Curves.bounceOut),
    );
    _characterController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _characterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MathGameCubit(),
      child: BlocConsumer<MathGameCubit, MathGameState>(
        listener: (context, state) {
          if (state.starsEarned > 0 && state.currentQuestionIndex > 0) {
            setState(() {
              _isHappy = true;
            });
            _characterController.forward(from: 0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Super Duper! 🌟'),
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
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.purple[50],
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉 You’re a Math Wizard! 🧙‍♂️',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 10),
                    Text(
                      'You earned ${state.starsEarned} stars! 🌟',
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        state.starsEarned,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<MathGameCubit>().close();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MathGame()),
                      );
                    },
                    child: const Text(
                      'Play Again! 🚀',
                      style: TextStyle(fontSize: 18, color: Colors.purple),
                    ),
                  ),
                ],
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
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B48FF), // Purple
                    Color(0xFF00DDEB), // Cyan
                  ],
                ),
              ),
              child: SafeArea(
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
                                'Math Magic! ',
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                          .map<Widget>((entry) {
                                        final option = entry.value;
                                        final index = entry.key;
                                        return _FunnyOptionButton(
                                          option: option,
                                          index: index,
                                          isCorrect: option ==
                                              currentQuestion['correctAnswer'],
                                          onPressed: () {
                                            context
                                                .read<MathGameCubit>()
                                                .checkAnswer(option);
                                            if (option !=
                                                currentQuestion[
                                                    'correctAnswer']) {
                                              setState(() {
                                                _isHappy = false;
                                              });
                                              _characterController.forward(
                                                  from: 0);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                      'Oopsie! Try Again! 🙈'),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  duration: const Duration(
                                                      seconds: 1),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
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
                        shouldLoop: false,
                        colors: const [
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.pink,
                          Colors.orange,
                        ],
                        numberOfParticles: 50,
                        maxBlastForce: 20,
                        minBlastForce: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom Widget for Funny Animated Option Buttons
class _FunnyOptionButton extends StatefulWidget {
  final int option;
  final int index;
  final bool isCorrect;
  final VoidCallback onPressed;

  const _FunnyOptionButton({
    required this.option,
    required this.index,
    required this.isCorrect,
    required this.onPressed,
  });

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
