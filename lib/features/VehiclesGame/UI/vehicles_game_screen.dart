import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/helpers/tts_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../QuizEngine/bloc/quiz_cubit.dart';
import '../../QuizEngine/bloc/quiz_state.dart';
import '../data/environment_vehicle_question.dart';

class VehiclesGameScreen extends StatefulWidget {
  const VehiclesGameScreen({super.key});

  @override
  State<VehiclesGameScreen> createState() => _VehiclesGameScreenState();
}

class _VehiclesGameScreenState extends State<VehiclesGameScreen> {
  Key _gameKey = UniqueKey();
  bool _assetsPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsPrecached) {
      _precacheAssets();
      _applyTtsLanguage();
      _assetsPrecached = true;
    }
  }

  void _applyTtsLanguage() {
    final languageCode = Localizations.localeOf(context).languageCode;
    TtsService.applyLanguageTo(context.read<FlutterTts>(), languageCode);
  }

  void _precacheAssets() {
    for (var env in EnvironmentType.values) {
      precacheImage(AssetImage(env.assetPath), context);
    }
    for (var veh in VehicleType.values) {
      precacheImage(AssetImage(veh.assetPath), context);
    }
  }

  void _restartGame() {
    setState(() {
      _gameKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundPath =
        BackgroundResolver(context, BackgroundType.game).resolveBackground();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xfffaf5f1),
          image: backgroundPath != null
              ? DecorationImage(
                  image: AssetImage(backgroundPath),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: SafeArea(
          child: VehiclesGameContent(
            key: _gameKey,
            onReplay: _restartGame,
          ),
        ),
      ),
    );
  }
}

class VehiclesGameContent extends StatelessWidget {

  const VehiclesGameContent({super.key, required this.onReplay});
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawQuestions = generateVehicleQuestions();

    final questions = rawQuestions.asMap().entries.map((entry) {
      return entry.value.toQuizQuestion(l10n, 'vehicle_q_${entry.key}');
    }).toList();

    return BlocProvider(
      create: (context) => QuizCubit(
        gameScoresDao: context.read<GameScoresDao>(),
        profileDao: context.read<ProfileDao>(),
        flutterTts: context.read<FlutterTts>(),
        audioPlayer: context.read<AudioPlayer>(),
        questions: questions,
        gameKey: 'vehicles_game',
        allowRetries: true,
        tryAgainText: l10n.tryAgain,
        transitionDuration: const Duration(milliseconds: 800),
        wrongFeedbackDuration: const Duration(milliseconds: 300),
      ),
      child: _VehiclesGameLayout(onReplay: onReplay),
    );
  }
}

class _VehiclesGameLayout extends StatefulWidget {

  const _VehiclesGameLayout({required this.onReplay});
  final VoidCallback onReplay;

  @override
  State<_VehiclesGameLayout> createState() => _VehiclesGameLayoutState();
}

class _VehiclesGameLayoutState extends State<_VehiclesGameLayout> {
  String? _wrongOptionId;
  String? _correctOptionId;
  final _random = Random();

  Widget _buildProgressBar(int current, int total) {
    return Text(
      '$current / $total',
      style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<QuizCubit, QuizState>(
      listener: (context, state) async {
        if (state is QuizFeedback) {
          if (state.isCorrect) {
            setState(() {
              _correctOptionId =
                  state.question.options.firstWhere((o) => o.isCorrect).id;
              _wrongOptionId = null;
            });
            final tts = context.read<FlutterTts>();
            // Fallback for some properties if missing
            final phrases = [
              l10n.greatJob,
              l10n.excellent,
              l10n.fantastic,
              l10n.perfect,
              'Amazing!',
              'Wonderful!',
              'You got it!',
              'Brilliant!'
            ];
            final phrase = phrases[_random.nextInt(phrases.length)];

            Future.delayed(const Duration(milliseconds: 700), () {
              tts.speak(phrase);
            });

            final audioPlayer = context.read<AudioPlayer>();
            try {
              await audioPlayer.play(AssetSource('audio/success.mp3'));
            } catch (_) {}
          } else {
            // Nothing needed here, state handles shaking
          }
        } else if (state is QuizActive) {
          setState(() {
            _wrongOptionId = null;
            _correctOptionId = null;
          });
        } else if (state is QuizCompleted) {
          final audioPlayer = context.read<AudioPlayer>();
          try {
            await audioPlayer.play(AssetSource('audio/success.mp3'));
          } catch (_) {}
        }
      },
      builder: (context, state) {
        if (state is QuizLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is QuizCompleted) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.greatJob,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 3)),
                        ],
                      ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onReplay,
                      icon: const Icon(Icons.replay, size: 32),
                      label:
                          const Text('Replay', style: TextStyle(fontSize: 24)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.5),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.exit_to_app, size: 32),
                      label:
                          Text(l10n.exit, style: const TextStyle(fontSize: 24)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.5),
                  ],
                ),
              ],
            ),
          );
        }

        if (state is QuizActive || state is QuizFeedback) {
          final question = state is QuizActive
              ? state.question
              : (state as QuizFeedback).question;
          final currentIndex = state is QuizActive
              ? state.questionIndex
              : (state as QuizFeedback).questionIndex;
          final isFeedback = state is QuizFeedback;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar: Back Button, Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white, size: 32),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: _buildProgressBar(currentIndex + 1, 10),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up,
                              color: Colors.white, size: 32),
                          onPressed: () =>
                              context.read<FlutterTts>().speak(question.prompt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Question Text
                    Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isLandscape ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

                    const SizedBox(height: 20),

                    // Main Content
                    Expanded(
                      child: Flex(
                        direction:
                            isLandscape ? Axis.horizontal : Axis.vertical,
                        children: [
                          // Environment Image (60% landscape width)
                          Expanded(
                            flex: isLandscape ? 6 : 4,
                            child: Hero(
                              tag: 'env_image_$currentIndex',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border:
                                      Border.all(color: Colors.white, width: 6),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 15,
                                        offset: Offset(0, 8)),
                                  ],
                                  image: DecorationImage(
                                    image:
                                        AssetImage(question.imageOrScenePath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .scale(begin: const Offset(0.95, 0.95)),
                            ),
                          ),

                          SizedBox(
                            height: isLandscape ? 0 : 20,
                            width: isLandscape ? 20 : 0,
                          ),

                          // Vehicles Options (40% landscape width)
                          Expanded(
                            flex: isLandscape ? 4 : 5,
                            child: LayoutBuilder(
                                builder: (context, cardConstraints) {
                              return Flex(
                                direction: isLandscape
                                    ? Axis.vertical
                                    : Axis.horizontal,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: question.options.map((option) {
                                  final isCorrectOption = option.isCorrect;
                                  final isSelectedWrong =
                                      _wrongOptionId == option.id;
                                  final isSelectedCorrect =
                                      _correctOptionId == option.id;

                                  Widget card = GestureDetector(
                                    onTap: (isFeedback && state.isCorrect)
                                        ? null
                                        : () {
                                            if (!isCorrectOption) {
                                              setState(() =>
                                                  _wrongOptionId = option.id);
                                              final audioPlayer =
                                                  context.read<AudioPlayer>();
                                              try {
                                                audioPlayer.play(AssetSource(
                                                    'audio/wrong.mp3'));
                                              } catch (_) {}
                                            }
                                            context
                                                .read<QuizCubit>()
                                                .submitAnswer(option);
                                          },
                                    child: Container(
                                      margin:
                                          EdgeInsets.all(isLandscape ? 8 : 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isSelectedCorrect
                                              ? Colors.green
                                              : (isSelectedWrong
                                                  ? Colors.red
                                                  : Colors.transparent),
                                          width: isSelectedCorrect ||
                                                  isSelectedWrong
                                              ? 6
                                              : 0,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 6)),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Image.asset(
                                          option.imagePath ?? '',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );

                                  if (isSelectedCorrect) {
                                    card = card
                                        .animate()
                                        .scale(
                                            duration: 400.ms,
                                            curve: Curves.elasticOut,
                                            end: const Offset(1.1, 1.1))
                                        .shimmer(
                                            duration: 400.ms,
                                            color: Colors.green
                                                .withValues(alpha: 0.3));
                                  } else if (isSelectedWrong) {
                                    card = card
                                        .animate()
                                        .shakeX(hz: 4, duration: 300.ms)
                                        .tint(
                                            color: Colors.red,
                                            duration: 300.ms);
                                  } else if (!isFeedback) {
                                    card = card
                                        .animate()
                                        .fadeIn(duration: 400.ms)
                                        .slideY(begin: 0.2);
                                  }

                                  return Expanded(child: card);
                                }).toList(),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
