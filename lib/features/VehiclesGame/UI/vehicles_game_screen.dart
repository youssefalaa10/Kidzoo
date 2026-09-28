import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/helpers/speech.dart';
import '../../../core/helpers/tts_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/style/kid_ui.dart';
import '../../../core/shared/widgets/kid_game_shell.dart';
import '../../../core/shared/widgets/kid_pick_card.dart';
import '../../../core/shared/widgets/kid_result_view.dart';
import '../../QuizEngine/bloc/quiz_cubit.dart';
import '../../QuizEngine/bloc/quiz_state.dart';
import '../../QuizEngine/data/quiz_models.dart';
import '../data/environment_vehicle_question.dart';

const int _kPointsPerQuestion = 10;

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
    for (final env in EnvironmentType.values) {
      precacheImage(AssetImage(env.assetPath), context);
    }
    for (final veh in VehicleType.values) {
      precacheImage(AssetImage(veh.assetPath), context);
    }
  }

  void _restartGame() {
    setState(() => _gameKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final backgroundPath =
        BackgroundResolver(context, BackgroundType.game).resolveBackground();

    return KidGameShell(
      backgroundAsset: backgroundPath,
      builder: (context, metrics) => _VehiclesGameContent(
        key: _gameKey,
        metrics: metrics,
        onReplay: _restartGame,
      ),
    );
  }
}

class _VehiclesGameContent extends StatefulWidget {
  const _VehiclesGameContent({
    required this.metrics,
    required this.onReplay,
    super.key,
  });

  final KidMetrics metrics;
  final VoidCallback onReplay;

  @override
  State<_VehiclesGameContent> createState() => _VehiclesGameContentState();
}

class _VehiclesGameContentState extends State<_VehiclesGameContent> {
  List<QuizQuestion>? _questions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Built once per game, not once per frame: the previous version rebuilt the
    // whole question set (and re-rolled every prompt) on any rebuild.
    _questions ??= _buildQuestions(AppLocalizations.of(context));
  }

  List<QuizQuestion> _buildQuestions(AppLocalizations l10n) {
    final raw = generateVehicleQuestions();
    return raw
        .asMap()
        .entries
        .map((entry) =>
            entry.value.toQuizQuestion(l10n, 'vehicle_q_${entry.key}'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final questions = _questions!;

    return BlocProvider<QuizCubit>(
      create: (context) {
        try {
          return QuizCubit(
            gameScoresDao: context.read<GameScoresDao>(),
            profileDao: context.read<ProfileDao>(),
            flutterTts: context.read<FlutterTts>(),
            audioPlayer: context.read<AudioPlayer>(),
            questions: questions,
            gameKey: 'vehicles_game',
            allowRetries: true,
            tryAgainText: l10n.tryAgain,
            transitionDuration: const Duration(milliseconds: 1200),
            wrongFeedbackDuration: const Duration(milliseconds: 600),
          );
        } catch (e) {
          debugPrint('Error creating QuizCubit for vehicles: $e');
          rethrow;
        }
      },
      child: _VehiclesGameLayout(
        metrics: widget.metrics,
        totalQuestions: questions.length,
        onReplay: widget.onReplay,
      ),
    );
  }
}

class _VehiclesGameLayout extends StatefulWidget {
  const _VehiclesGameLayout({
    required this.metrics,
    required this.totalQuestions,
    required this.onReplay,
  });

  final KidMetrics metrics;
  final int totalQuestions;
  final VoidCallback onReplay;

  @override
  State<_VehiclesGameLayout> createState() => _VehiclesGameLayoutState();
}

class _VehiclesGameLayoutState extends State<_VehiclesGameLayout> {
  /// The option the child last tapped, so only that card turns red.
  String? _tappedOptionId;
  final _random = Random();

  void _onOptionTapped(QuizOption option, bool locked) {
    if (locked) return;
    setState(() => _tappedOptionId = option.id);

    if (option.isCorrect) {
      KidHaptics.success();
    } else {
      KidHaptics.error();
      _play('audio/wrong.mp3');
    }
    context.read<QuizCubit>().submitAnswer(option);
  }

  void _play(String asset) {
    try {
      context.read<AudioPlayer>().play(AssetSource(asset));
    } catch (_) {}
  }

  void _celebrate(AppLocalizations l10n) {
    _play('audio/success.mp3');
    final phrases = <String>[
      l10n.greatJob,
      l10n.excellent,
      l10n.fantastic,
      l10n.perfect,
      ...l10n.positiveFeedbackMessages,
    ];
    final phrase = phrases[_random.nextInt(phrases.length)];
    Future.delayed(const Duration(milliseconds: 550), () async {
      if (!mounted) return;
      try {
        await Speech.stop();
        final spoke = await Speech.speak(phrase);
        if (spoke && mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = widget.metrics;
    final maxScore = widget.totalQuestions * _kPointsPerQuestion;

    return BlocConsumer<QuizCubit, QuizState>(
      listener: (context, state) {
        if (state is QuizFeedback && state.isCorrect) {
          _celebrate(l10n);
        } else if (state is QuizActive) {
          if (_tappedOptionId != null) {
            setState(() => _tappedOptionId = null);
          }
        } else if (state is QuizCompleted) {
          _play('audio/success.mp3');
          KidHaptics.success();
        }
      },
      builder: (context, state) {
        if (state is QuizLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is QuizCompleted) {
          return KidResultView(
            metrics: m,
            score: state.finalScore,
            maxScore: maxScore,
            onPlayAgain: widget.onReplay,
          );
        }

        if (state is! QuizActive && state is! QuizFeedback) {
          return const SizedBox.shrink();
        }

        final question = state is QuizActive
            ? state.question
            : (state as QuizFeedback).question;
        final index = state is QuizActive
            ? state.questionIndex
            : (state as QuizFeedback).questionIndex;
        final score =
            state is QuizActive ? state.score : (state as QuizFeedback).score;
        final answeredCorrectly = state is QuizFeedback && state.isCorrect;

        return Padding(
          padding: EdgeInsets.all(m.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KidTopBar(
                metrics: m,
                current: index + 1,
                total: widget.totalQuestions,
                score: score,
                onReplayPrompt: () =>
                    context.read<FlutterTts>().speak(question.prompt),
              ),
              SizedBox(height: m.gap * 0.75),
              KidPromptBanner(
                metrics: m,
                text: question.prompt,
                hint: l10n.tapOrDragHint,
                onSpeak: () =>
                    context.read<FlutterTts>().speak(question.prompt),
              ),
              SizedBox(height: m.gap * 0.75),
              Expanded(
                child: Flex(
                  direction: m.isLandscape ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      flex: m.isLandscape ? 6 : 5,
                      child: _SceneCard(
                        key: ValueKey(question.imageOrScenePath),
                        assetPath: question.imageOrScenePath,
                        metrics: m,
                      ),
                    ),
                    SizedBox(
                      width: m.isLandscape ? m.gap : 0,
                      height: m.isLandscape ? 0 : m.gap,
                    ),
                    Expanded(
                      flex: 4,
                      child: _OptionsBoard(
                        metrics: m,
                        question: question,
                        tappedOptionId: _tappedOptionId,
                        onTap: (option) =>
                            _onOptionTapped(option, answeredCorrectly),
                      ),
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
}

/// The environment the child has to reason about.
class _SceneCard extends StatelessWidget {
  const _SceneCard({
    required this.assetPath,
    required this.metrics,
    super.key,
  });

  final String assetPath;
  final KidMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
        border: Border.all(
            color: Colors.white, width: metrics.size(6, min: 4, max: 8)),
        boxShadow: KidUi.shadow(Colors.black, strength: 1.2),
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.cover,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOut);
  }
}

/// The answer cards, sized from the space they were actually handed.
class _OptionsBoard extends StatelessWidget {
  const _OptionsBoard({
    required this.metrics,
    required this.question,
    required this.tappedOptionId,
    required this.onTap,
  });

  final KidMetrics metrics;
  final QuizQuestion question;
  final String? tappedOptionId;
  final void Function(QuizOption) onTap;

  @override
  Widget build(BuildContext context) {
    final options = question.options;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = metrics.gap * 0.6;
        // Wrapping with a fitted card size means the answers can never run off
        // the edge: on a narrow phone four options fall into two rows instead
        // of clipping, which the old fixed Flex row did.
        final cardSize = kidFitCardSize(
          count: options.length,
          box: Size(constraints.maxWidth, constraints.maxHeight),
          spacing: spacing,
          maxSize: 190,
        );

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final option in options) _optionCard(option, cardSize),
            ],
          ),
        );
      },
    );
  }

  Widget _optionCard(QuizOption option, double size) {
    final tapped = tappedOptionId == option.id;
    final state = tapped
        ? (option.isCorrect ? KidCardState.correct : KidCardState.wrong)
        : KidCardState.idle;

    return KidPickCard<String>(
      key: ValueKey('${question.id}_${option.id}'),
      imageAsset: option.imagePath ?? '',
      label: option.text,
      size: size,
      state: state,
      onTap: () => onTap(option),
    )
        .animate(key: ValueKey('${question.id}_${option.id}_in'))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.2, curve: Curves.easeOut);
  }
}
