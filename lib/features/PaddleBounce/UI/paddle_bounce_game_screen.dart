import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/mixins/background_music_mixin.dart';
import '../data/logic/paddle_bounce_cubit.dart';
import '../data/logic/paddle_bounce_state.dart';
import '../data/models/paddle_bounce_models.dart';
import 'widgets/game_over_dialog.dart';

class PaddleBounceGameScreen extends StatefulWidget {
  const PaddleBounceGameScreen({super.key});

  @override
  State<PaddleBounceGameScreen> createState() => _PaddleBounceGameScreenState();
}

class _PaddleBounceGameScreenState extends State<PaddleBounceGameScreen>
    with BackgroundMusicMixin {
  final Map<int, double> _touchStates = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocConsumer<PaddleBounceCubit, PaddleBounceState>(
        listener: (context, state) {
          if (state.isGameOver) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => GameOverDialog(
                    winner: state.winner!,
                    player1Score: state.player1Score,
                    player2Score: state.player2Score,
                    gameMode: state.gameMode,
                    onPlayAgain: () {
                      context.read<PaddleBounceCubit>().resetGame();
                      Navigator.pop(context);
                    },
                    onMainMenu: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                );
              }
            });
          }
        },
        builder: (context, state) {
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (state.status != PaddleBounceGameStatus.playing) return;
              _touchStates[event.pointer] = event.position.dx;
            },
            onPointerMove: (event) {
              if (state.status != PaddleBounceGameStatus.playing) return;

              final screenHeight = MediaQuery.of(context).size.height;
              final screenWidth = MediaQuery.of(context).size.width;
              final touchY = event.position.dy;
              final touchX = event.position.dx;

              // Ignore touches in the center where pause button is (approximately)
              final centerY = screenHeight / 2;
              final centerX = screenWidth / 2;
              if ((touchY - centerY).abs() < 60 &&
                  (touchX - centerX).abs() < 40) {
                return; // Ignore touches in pause button area
              }

              if (!_touchStates.containsKey(event.pointer)) {
                _touchStates[event.pointer] = touchX;
                return;
              }
              final lastX = _touchStates[event.pointer]!;

              // Determine which paddle to move based on touch position
              if (state.gameMode == PaddleBounceGameMode.vsFriend) {
                // Friend mode: top 40% controls top paddle, bottom 40% controls bottom paddle
                // Middle 20% is neutral zone to avoid conflicts
                final topZone = screenHeight * 0.4;
                final bottomZone = screenHeight * 0.6;

                if (touchY < topZone) {
                  // Top paddle - top 40% of screen
                  final deltaX = (touchX - lastX) / screenSize.width;
                  context.read<PaddleBounceCubit>().moveTopPaddle(deltaX);
                } else if (touchY > bottomZone) {
                  // Bottom paddle - bottom 40% of screen
                  final deltaX = (touchX - lastX) / screenSize.width;
                  context.read<PaddleBounceCubit>().moveBottomPaddle(deltaX);
                }
              } else {
                // AI mode: player only controls bottom paddle (bottom 50% of screen)
                if (touchY > screenHeight / 2) {
                  final deltaX = (touchX - lastX) / screenSize.width;
                  context.read<PaddleBounceCubit>().moveBottomPaddle(deltaX);
                }
              }
              _touchStates[event.pointer] = touchX;
            },
            onPointerUp: (event) {
              _touchStates.remove(event.pointer);
            },
            onPointerCancel: (event) {
              _touchStates.remove(event.pointer);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (state.status == PaddleBounceGameStatus.waiting) {
                  context.read<PaddleBounceCubit>().startGame();
                } else if (state.status == PaddleBounceGameStatus.playing) {
                  context.read<PaddleBounceCubit>().pauseGame();
                } else if (state.status == PaddleBounceGameStatus.paused) {
                  context.read<PaddleBounceCubit>().pauseGame();
                }
              },
              child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Center line
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: CustomPaint(
                      painter: _CenterLinePainter(),
                    ),
                  ),
                  // Top paddle
                  Positioned(
                    top: state.gameMode == PaddleBounceGameMode.vsFriend
                        ? 80 // Extra padding for friend mode to avoid appbar
                        : 20, // Normal padding for AI mode
                    left: state.topPaddle.x,
                    child: Container(
                      width: state.topPaddle.width,
                      height: state.topPaddle.height,
                      decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.8),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom paddle
                  Positioned(
                    bottom: 20, // Add padding from bottom
                    left: state.bottomPaddle.x,
                    child: Container(
                      width: state.bottomPaddle.width,
                      height: state.bottomPaddle.height,
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.8),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Ball
                  Positioned(
                    left: state.ball.x - state.ball.radius,
                    top: state.ball.y - state.ball.radius,
                    child: Container(
                      width: state.ball.radius * 2,
                      height: state.ball.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Colors.yellow,
                            Colors.orange,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withOpacity(0.8),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Score display - centered vertically
                  Center(
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top player score (Player 2 or AI)
                          Column(
                            children: [
                              Text(
                                state.gameMode == PaddleBounceGameMode.vsAI
                                    ? 'AI'
                                    : l10n.player2,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.cyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${state.player2Score}',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Pause button - centered
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.read<PaddleBounceCubit>().pauseGame();
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  state.isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Bottom player score (Player 1)
                          Column(
                            children: [
                              Text(
                                l10n.player1,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${state.player1Score}',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Waiting/Paused overlay
                  if (state.status == PaddleBounceGameStatus.waiting ||
                      state.status == PaddleBounceGameStatus.paused)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (state.status == PaddleBounceGameStatus.waiting)
                              Text(
                                l10n.tapToStart,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Text(
                                l10n.pause,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (state.status ==
                                    PaddleBounceGameStatus.waiting) {
                                  context.read<PaddleBounceCubit>().startGame();
                                } else {
                                  context.read<PaddleBounceCubit>().pauseGame();
                                }
                              },
                              icon: Icon(
                                state.status == PaddleBounceGameStatus.waiting
                                    ? Icons.play_arrow
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                state.status == PaddleBounceGameStatus.waiting
                                    ? l10n.tapToStart
                                    : l10n.resume,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
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

class _CenterLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw dashed center line
    const dashWidth = 10;
    const dashSpace = 10;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
