import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/database/config.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/vegetables_game_engine.dart';
import 'widgets/draggable_veggie.dart';
import 'widgets/veggie_target.dart';

class VegetablesGameScreen extends StatefulWidget {
  const VegetablesGameScreen({super.key});

  @override
  State<VegetablesGameScreen> createState() => _VegetablesGameScreenState();
}

class _VegetablesGameScreenState extends State<VegetablesGameScreen> {
  late final VegetablesGameEngine _engine;
  bool _isLoading = true;
  
  bool _isSuccess = false;
  VegetableItem? _shakingVeggie;
  bool _gameComplete = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _engine = VegetablesGameEngine();
    _initGame();
  }

  Future<void> _initGame() async {
    setState(() {
      _isLoading = true;
      _gameComplete = false;
      _score = 0;
    });

    await _engine.initialize();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadNextQuestion();
    }
  }

  void _loadNextQuestion() {
    if (_engine.isComplete) {
      _finishGame();
      return;
    }

    _isSuccess = false;
    _shakingVeggie = null;
    
    _engine.nextQuestion();
    _engine.generatePrompt(AppLocalizations.of(context));
    
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tts = context.read<FlutterTts>();
        tts.speak(_engine.currentPrompt);
      }
    });
  }

  Future<void> _finishGame() async {
    setState(() {
      _gameComplete = true;
    });

    final audioPlayer = context.read<AudioPlayer>();
    final profileDao = context.read<ProfileDao>();
    final gameScoresDao = context.read<GameScoresDao>();

    try {
      await audioPlayer.play(AssetSource('audio/success.mp3'));
    } catch (_) {}

    try {
      final profiles = await profileDao.getAllProfiles();
      if (profiles.isNotEmpty) {
        await gameScoresDao.insertScore(GameScoresCompanion.insert(
          profileId: profiles.first.id,
          gameKey: 'vegetables',
          score: _score,
        ));
      }
    } catch (_) {}
  }

  void _handleCorrect() {
    setState(() {
      _isSuccess = true;
      _score += 10;
    });

    final l10n = AppLocalizations.of(context);
    final tts = context.read<FlutterTts>();
    tts.speak(l10n.greatJob);

    try {
      final audioPlayer = context.read<AudioPlayer>();
      audioPlayer.play(AssetSource('audio/success.mp3'));
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _loadNextQuestion();
      }
    });
  }

  void _handleWrong(VegetableItem data) {
    setState(() {
      _shakingVeggie = data;
    });

    final l10n = AppLocalizations.of(context);
    final tts = context.read<FlutterTts>();
    tts.speak(l10n.tryAgain);

    try {
      final audioPlayer = context.read<AudioPlayer>();
      audioPlayer.play(AssetSource('audio/wrong.mp3'));
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _shakingVeggie == data) {
        setState(() {
          _shakingVeggie = null;
        });
      }
    });
  }

  Widget _buildCompletionScreen(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Celebration Icon
          const Icon(Icons.stars_rounded, size: 100, color: Colors.amber)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms)
              .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms)
              .then()
              .scaleXY(begin: 1.2, end: 0.8, duration: 800.ms),
          const SizedBox(height: 20),
          Text(
            l10n.vegetablesGameComplete,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 10),
          Text(
            l10n.excellent,
            style: const TextStyle(fontSize: 32, color: Colors.orange, fontWeight: FontWeight.w600),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _initGame,
            icon: const Icon(Icons.replay, size: 32),
            label: Text(l10n.playAgain, style: const TextStyle(fontSize: 24)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.5),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backToCategories,
                style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameLayout(AppLocalizations l10n, bool isLandscape) {
    if (_engine.currentTarget == null) return const SizedBox();

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      '${_engine.currentProgress} / ${_engine.totalQuestions}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        
        const SizedBox(height: 10),

        // Question Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _engine.currentPrompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isLandscape ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ).animate(key: ValueKey(_engine.currentPrompt)).fadeIn(duration: 400.ms).slideY(begin: -0.2),
        ),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Target Placeholder
              Expanded(
                flex: 5,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: VeggieTarget(
                      currentTarget: _engine.currentTarget,
                      isSuccess: _isSuccess,
                      onAccept: (data) {
                        if (data.assetPath == _engine.currentTarget!.assetPath) {
                          _handleCorrect();
                        } else {
                          _handleWrong(data);
                        }
                      },
                    ),
                  ),
                ),
              ),

              // Draggable Options
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _engine.currentOptions.map((option) {
                      return Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DraggableVeggie(
                            key: ValueKey(option.assetPath),
                            option: option,
                            isLandscape: isLandscape,
                            isShaking: _shakingVeggie?.assetPath == option.assetPath,
                            isSuccess: _isSuccess,
                            isTarget: _engine.currentTarget?.assetPath == option.assetPath,
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate(key: ValueKey(_engine.currentTarget)).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff5fcf5), // Gentle light green/beige background
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _gameComplete
                ? _buildCompletionScreen(l10n)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape = constraints.maxWidth > constraints.maxHeight;
                      return _buildGameLayout(l10n, isLandscape);
                    },
                  ),
      ),
    );
  }
}
