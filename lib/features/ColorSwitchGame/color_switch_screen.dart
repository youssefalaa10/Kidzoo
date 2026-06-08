import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/helpers/tts_helper.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';
import 'color_switch_game.dart';

class ColorSwitchScreen extends StatefulWidget {
  const ColorSwitchScreen({super.key});

  @override
  State<ColorSwitchScreen> createState() => _ColorSwitchScreenState();
}

class _ColorSwitchScreenState extends State<ColorSwitchScreen> {
  late ColorSwitchGame _game;
  bool _showStartOverlay = true;
  TtsHelper? _ttsHelper;

  @override
  void initState() {
    super.initState();
    _game = ColorSwitchGame();
    _game.onGameStarted = () {
      if (mounted) {
        setState(() {
          _showStartOverlay = false;
        });
      }
    };
    _game.onPlayerColorChanged = _speakColorName;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ttsHelper == null) {
      _ttsHelper = TtsHelper(
        musicCubit: context.read<MusicCubit>(),
        languageCode: Localizations.localeOf(context).languageCode,
      );
    }
  }

  @override
  void dispose() {
    _ttsHelper?.stop();
    super.dispose();
  }

  void _speakColorName(String colorName) {
    _ttsHelper?.speak(colorName);
  }

  void _showSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => BlocBuilder<MusicCubit, MusicState>(
        builder: (context, state) {
          return AlertDialog(
            title: Text(l10n.soundSettings),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(l10n.enableSoundToggle),
                  value: state.isSoundEnabled,
                  onChanged: (value) {
                    context.read<MusicCubit>().setSoundEnabled(value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),

          // ─── START OVERLAY ─────────────────────────────────────────
          if (_showStartOverlay)
            GestureDetector(
              onTap: () {
                setState(() => _showStartOverlay = false);
                _game.startGame();
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 72)),
                      const SizedBox(height: 20),
                      Text(
                        l10n.tapToPlayKeepTapping,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: const Text(
                          '👆 Tap!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── TOP BAR ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings,
                          color: Colors.white, size: 28),
                      onPressed: () => _showSettings(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
