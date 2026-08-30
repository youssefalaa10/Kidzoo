import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/helpers/tts_service.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/mixins/background_music_mixin.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'package:kidzo/core/services/background_resolver.dart';
import 'package:kidzo/core/utils/assets.dart';

import '../../../core/shared/widgets/fluid_container.dart';
import '../data/model/animal_name_model.dart';
import 'widgets/animal_name_success_overlay.dart';

class AnimalNameGameScreen extends StatefulWidget {
  const AnimalNameGameScreen({super.key});

  @override
  State<AnimalNameGameScreen> createState() => _AnimalNameGameScreenState();
}

class _AnimalNameGameScreenState extends State<AnimalNameGameScreen>
    with TTSMusicMixin {
  // How many animals per round
  static const int _roundSize = 6;

  List<AnimalNameModel> _getAnimals(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      AnimalNameModel(name: l10n.cat, imagePath: Assets.genImagesAnimalCat),
      AnimalNameModel(name: l10n.dog, imagePath: Assets.genImagesAnimalDog),
      AnimalNameModel(name: l10n.cow, imagePath: Assets.genImagesAnimalCow),
      AnimalNameModel(name: l10n.hen, imagePath: Assets.genImagesAnimalHen),
      AnimalNameModel(name: l10n.bird, imagePath: Assets.genImagesAnimalBird),
      AnimalNameModel(name: l10n.lion, imagePath: Assets.genImagesAnimalLion),
      AnimalNameModel(name: l10n.sheep, imagePath: Assets.genImagesAnimalSheep),
      AnimalNameModel(name: l10n.horse, imagePath: Assets.genImagesAnimalHorse),
      AnimalNameModel(
          name: l10n.elephant, imagePath: Assets.genImagesAnimalElephant),
      AnimalNameModel(
          name: l10n.giraffe, imagePath: Assets.genImagesAnimalGiraffe),
      AnimalNameModel(name: l10n.panda, imagePath: Assets.genImagesAnimalPanda),
    ];
  }

  // Current round animals in board order (drop targets)
  List<AnimalNameModel>? _boardAnimals;

  // Which board slots are filled (matched)
  List<bool> _isFilled = [];

  // Which draggable items have been placed (hide them from the tray)
  List<bool> _isPlaced = [];

  // Shuffled draggable order (same set, different order)
  List<AnimalNameModel>? _trayAnimals;

  bool _isComplete = false;
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final lang = Localizations.localeOf(context).languageCode;
        if (lang == 'ar') {
          // Check if Arabic voice is installed, and request if not
          TtsService.checkAndRequestArabicVoice(context);
        }
        _ttsService.init(languageCode: lang);
        _ttsService.setCompletionHandler(() {
          if (mounted) context.read<MusicCubit>().resumeMusic();
        });
        _ttsService.setErrorHandler((msg) {
          if (mounted) context.read<MusicCubit>().resumeMusic();
          print('TTS Error: $msg');
        });
        _startNewRound();
      }
    });
  }

  void _startNewRound() {
    final Random rng = Random();
    final List<AnimalNameModel> pool =
        List<AnimalNameModel>.of(_getAnimals(context))..shuffle(rng);
    final List<AnimalNameModel> round = pool.take(_roundSize).toList();

    setState(() {
      _isComplete = false;
      _boardAnimals = List<AnimalNameModel>.from(round);
      _isFilled = List<bool>.filled(_roundSize, false);
      // Tray order is shuffled so images don't align 1-to-1 with board
      _trayAnimals = List<AnimalNameModel>.from(round)..shuffle(rng);
      _isPlaced = List<bool>.filled(_roundSize, false);
    });
  }

  Future<void> _speakAnimalName(String name) async {
    final musicCubit = context.read<MusicCubit>();
    await musicCubit.stopMusic();

    final languageCode = Localizations.localeOf(context).languageCode;
    await _ttsService.setLanguage(languageCode);
    await _ttsService.speak(name);
  }

  void _onCorrectMatch(AnimalNameModel animal) {
    _speakAnimalName(animal.name);
    final int boardIdx = _boardAnimals!.indexOf(animal);
    final int trayIdx = _trayAnimals!.indexOf(animal);
    setState(() {
      _isFilled[boardIdx] = true;
      _isPlaced[trayIdx] = true;
      if (_isFilled.every((v) => v)) {
        _isComplete = true;
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          if (_boardAnimals == null)
            const Center(child: CircularProgressIndicator())
          else
            SafeArea(
              child: FluidContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildGameArea()),
                  ],
                ),
              ),
            ),
          if (_isComplete)
            AnimalNameSuccessOverlay(onPlayAgain: _startNewRound),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Background
  // ──────────────────────────────────────────────
  Widget _buildBackground() {
    final bgPath = BackgroundResolver(context, BackgroundType.game).resolveBackground();
    if (bgPath == null) return const SizedBox();
    
    return Positioned.fill(
      child: Image.asset(
        bgPath,
        fit: BoxFit.cover,
      ),
    );
  }

  // ──────────────────────────────────────────────
  // AppBar
  // ──────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            '${AppLocalizations.of(context).animalNames} 🐾',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildCircleButton(
            icon: Icons.refresh_rounded,
            onTap: _startNewRound,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.green.shade800),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Game area: chalkboard on top, tray on bottom
  // ──────────────────────────────────────────────
  Widget _buildGameArea() {
    return Column(
      children: [
        Expanded(child: _buildChalkboard()),
        const SizedBox(height: 8),
        Expanded(child: _buildTray()),
        const SizedBox(height: 8),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Top chalkboard panel — DragTargets
  // ──────────────────────────────────────────────
  Widget _buildChalkboard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/gen/images/backgrounds/board_mob.jpg'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_roundSize, (i) {
              return _BoardSlot(
                animal: _boardAnimals![i],
                isFilled: _isFilled[i],
                onCorrectDrop: () => _onCorrectMatch(_boardAnimals![i]),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Bottom tray panel — Draggables
  // ──────────────────────────────────────────────
  Widget _buildTray() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black87.withValues(alpha: 0.75),
        border: Border.all(
          color: Colors.black54.withValues(alpha: 0.8),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_roundSize, (i) {
              return _TrayItem(
                animal: _trayAnimals![i],
                isPlaced: _isPlaced[i],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Board slot (DragTarget): shows silhouette → filled image on match
// ════════════════════════════════════════════════
class _BoardSlot extends StatefulWidget {
  const _BoardSlot({
    required this.animal,
    required this.isFilled,
    required this.onCorrectDrop,
  });

  final AnimalNameModel animal;
  final bool isFilled;
  final VoidCallback onCorrectDrop;

  @override
  State<_BoardSlot> createState() => _BoardSlotState();
}

class _BoardSlotState extends State<_BoardSlot>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isWrong = false;
  late AnimationController _popController;
  late Animation<double> _popAnimation;

  static const double _slotSize = 90.0;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _popAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(_BoardSlot old) {
    super.didUpdateWidget(old);
    // Trigger pop animation when slot becomes filled
    if (!old.isFilled && widget.isFilled) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _triggerWrong() {
    setState(() => _isWrong = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isWrong = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<AnimalNameModel>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        if (details.data.name == widget.animal.name) {
          widget.onCorrectDrop();
        } else {
          _triggerWrong();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _slotSize,
          height: _slotSize,
          decoration: BoxDecoration(
            color: _isWrong
                ? Colors.red.withValues(alpha: 0.25)
                : _isHovering
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isWrong
                  ? Colors.redAccent
                  : _isHovering
                      ? Colors.white70
                      : Colors.transparent,
              width: 2,
            ),
          ),
          child: widget.isFilled ? _buildFilledIcon() : _buildSilhouette(),
        );
      },
    );
  }

  Widget _buildSilhouette() {
    return Opacity(
      opacity: 0.35,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        child: Image.asset(
          widget.animal.imagePath,
          width: _slotSize,
          height: _slotSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFilledIcon() {
    return ScaleTransition(
      scale: _popAnimation,
      child: Image.asset(
        widget.animal.imagePath,
        width: _slotSize,
        height: _slotSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ════════════════════════════════════════════════
// Tray item (Draggable)
// ════════════════════════════════════════════════
class _TrayItem extends StatelessWidget {
  const _TrayItem({
    required this.animal,
    required this.isPlaced,
  });

  final AnimalNameModel animal;
  final bool isPlaced;

  static const double _itemSize = 75.0;
  static const double _feedbackSize = 90.0;

  @override
  Widget build(BuildContext context) {
    if (isPlaced) {
      // Empty ghost placeholder keeps layout stable
      return const SizedBox(width: _itemSize, height: _itemSize);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Draggable<AnimalNameModel>(
        data: animal,
        childWhenDragging: const SizedBox(
          width: _itemSize,
          height: _itemSize,
        ),
        feedback: Material(
          color: Colors.transparent,
          child: Image.asset(
            animal.imagePath,
            width: _feedbackSize,
            height: _feedbackSize,
            fit: BoxFit.contain,
          ),
        ),
        child: Image.asset(
          animal.imagePath,
          width: _itemSize,
          height: _itemSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
