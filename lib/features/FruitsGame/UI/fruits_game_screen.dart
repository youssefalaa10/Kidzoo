import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/daos/game_scores_dao.dart';
import '../../../core/database/daos/profile_dao.dart';
import '../../../core/database/config.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/fruits_game_engine.dart';
import 'widgets/conveyor_belt.dart';

class FruitsGameScreen extends StatefulWidget {
  const FruitsGameScreen({super.key});

  @override
  State<FruitsGameScreen> createState() => _FruitsGameScreenState();
}

class _FruitsGameScreenState extends State<FruitsGameScreen> {
  late final FruitsGameEngine _engine;
  bool _isLoading = true;
  
  bool _isFrozen = false;
  FruitItem? _successFruit;
  FruitItem? _shakingFruit;
  bool _gameComplete = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _engine = FruitsGameEngine();
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

    _isFrozen = false;
    _successFruit = null;
    _shakingFruit = null;
    
    _engine.nextQuestion();
    _engine.generatePrompt(AppLocalizations.of(context));
    
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakPrompt();
    });
  }

  void _speakPrompt() {
    if (mounted) {
      final tts = context.read<FlutterTts>();
      tts.speak(_engine.currentPrompt);
    }
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
          gameKey: 'fruits',
          score: _score,
        ));
      }
    } catch (_) {}
  }

  void _handleCorrect(FruitItem data) {
    setState(() {
      _isFrozen = true;
      _successFruit = data;
      _score += 10;
    });

    final l10n = AppLocalizations.of(context);
    final tts = context.read<FlutterTts>();
    tts.speak(l10n.excellent);

    try {
      final audioPlayer = context.read<AudioPlayer>();
      audioPlayer.play(AssetSource('audio/success.mp3'));
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _loadNextQuestion();
      }
    });
  }

  void _handleWrong(FruitItem data) {
    setState(() {
      _shakingFruit = data;
    });

    final l10n = AppLocalizations.of(context);
    final tts = context.read<FlutterTts>();
    tts.speak(l10n.tryAgain);

    try {
      final audioPlayer = context.read<AudioPlayer>();
      audioPlayer.play(AssetSource('audio/wrong.mp3'));
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _shakingFruit == data) {
        setState(() {
          _shakingFruit = null;
        });
      }
    });
  }

  void _handleBeltFinished() {
    setState(() {
      _isFrozen = true;
    });

    try {
      final audioPlayer = context.read<AudioPlayer>();
      audioPlayer.play(AssetSource('audio/wrong.mp3'));
    } catch (_) {}
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isFrozen = false;
          _engine.currentOptions = List.from(_engine.currentOptions)..shuffle(_engine.random);
        });
        _speakPrompt();
      }
    });
  }

  Widget _buildCompletionScreen(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration, size: 100, color: Colors.orange)
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1200.ms, color: Colors.yellow)
              .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms)
              .then()
              .scaleXY(begin: 1.2, end: 0.8, duration: 800.ms),
          const SizedBox(height: 20),
          Text(
            l10n.fruitsGameComplete,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 10),
          Text(
            l10n.excellent,
            style: const TextStyle(fontSize: 32, color: Colors.green, fontWeight: FontWeight.w600),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _initGame,
            icon: const Icon(Icons.replay, size: 32),
            label: Text(l10n.playAgain, style: const TextStyle(fontSize: 24)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.5),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.backToCategories,
                style: TextStyle(fontSize: 20, color: Colors.orange[700], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameLayout(AppLocalizations l10n, bool isLandscape) {
    if (_engine.currentTarget == null) return const SizedBox();

    return Column(
      children: [
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32), // Balance the back button without pushing too hard
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Text(
              _engine.currentPrompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isLandscape ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ).animate(key: ValueKey(_engine.currentPrompt)).fadeIn(duration: 400.ms).scale(curve: Curves.easeOutBack),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: ConveyorBelt(
            fruits: _engine.currentOptions,
            currentTarget: _engine.currentTarget!,
            isFrozen: _isFrozen,
            successFruit: _successFruit,
            shakingFruit: _shakingFruit,
            onFruitTapped: (fruit) {
              if (fruit.assetPath == _engine.currentTarget!.assetPath) {
                _handleCorrect(fruit);
              } else {
                _handleWrong(fruit);
              }
            },
            onBeltFinished: _handleBeltFinished,
          ),
        ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfffff8e1),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
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
