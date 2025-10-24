import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/base/protected_game_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../bloc/color_memory_bloc.dart';
import '../bloc/color_memory_event.dart';
import '../data/models/color_memory_constants.dart';
import '../data/models/game_state_model.dart';
import 'widgets/color_grid_widget.dart';
import 'widgets/game_header_widget.dart';
import 'widgets/game_over_dialog.dart';
import 'widgets/level_complete_dialog.dart';
import 'widgets/success_dialog.dart';

class ColorMemoryScreen extends ProtectedGameScreen {
  const ColorMemoryScreen({
    required super.level,
    super.key,
  });

  @override
  State<ColorMemoryScreen> createState() => _ColorMemoryScreenState();
}

class _ColorMemoryScreenState
    extends ProtectedGameScreenState<ColorMemoryScreen> {
  late ColorMemoryBloc _bloc;

  @override
  void onGameInit() {
    _bloc = ColorMemoryBloc();
    // Start game with classic mode
    _bloc.add(StartGameEvent(
      mode: ColorMemoryGameMode.classic,
      level: widget.level,
    ));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onColorTap(int colorIndex, ColorMemoryGameState state) {
    if (state.phase == GamePhase.playerTurn) {
      // Haptic feedback
      if (state.settings.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }

      // Play sound (if sound assets are available)
      // if (state.settings.soundEnabled) {
      //   _playSound(colorIndex);
      // }

      _bloc.add(PlayerTapColorEvent(colorIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ColorMemoryBloc, ColorMemoryGameState>(
        listener: (context, state) {
          // Show level complete dialog
          if (state.phase == GamePhase.levelComplete) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => LevelCompleteDialog(
                    level: state.level,
                    score: state.score.currentScore,
                    onContinue: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context)
                          .pop(true); // Exit to level map with success
                    },
                  ),
                );
              }
            });
          }

          // Show success dialog
          if (state.phase == GamePhase.success) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => SuccessDialog(
                    round: state.score.currentRound - 1,
                    score: state.score.currentScore,
                    sequenceLength: state.sequence.length,
                    onContinue: () {
                      Navigator.of(context).pop();
                      // Trigger next round manually
                      _bloc.add(const NextRoundEvent());
                    },
                  ),
                );
              }
            });
          }

          // Show game over dialog
          if (state.phase == GamePhase.failure) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => GameOverDialog(
                    score: state.score.currentScore,
                    bestScore: state.bestScore,
                    round: state.score.currentRound,
                    longestSequence: state.score.longestSequence,
                    onRestart: () {
                      Navigator.of(context).pop();
                      _bloc.add(const RestartGameEvent());
                    },
                    onExit: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Exit to level map
                    },
                  ),
                );
              }
            });
          }
        },
        builder: (context, state) {
          final config = LevelConfig.forLevel(state.level);
          final palette =
              ColorPalettes.all[state.settings.selectedPaletteIndex];

          return Scaffold(
            backgroundColor: ColorMemoryConstants.backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // Header with stats
                  GameHeaderWidget(
                    state: state,
                    onBack: () => Navigator.of(context).pop(),
                    onRestart: () => _bloc.add(const RestartGameEvent()),
                  ),

                  const SizedBox(height: 16),

                  // Status message
                  _buildStatusMessage(state),

                  const SizedBox(height: 24),

                  // Color grid
                  Expanded(
                    child: Center(
                      child: ColorGridWidget(
                        gridSize: config.gridSize,
                        palette: palette,
                        highlightedIndex: state.highlightedColorIndex,
                        onColorTap: (index) => _onColorTap(index, state),
                        isInteractive: state.phase == GamePhase.playerTurn,
                        colorBlindMode: state.settings.colorBlindMode,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress indicator
                  if (state.phase == GamePhase.playerTurn)
                    _buildProgressIndicator(state)
                  else if (state.phase == GamePhase.showingSequence)
                    _buildSequenceProgress(state),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusMessage(ColorMemoryGameState state) {
    final l10n = AppLocalizations.of(context);
    String message = '';
    Color color = Colors.black87;
    IconData icon = Icons.info;

    switch (state.phase) {
      case GamePhase.waiting:
        message = l10n.getReady;
        icon = Icons.hourglass_empty;
        break;
      case GamePhase.showingSequence:
        message = l10n.watchCarefully;
        color = Colors.blue.shade700;
        icon = Icons.visibility;
        break;
      case GamePhase.playerTurn:
        message = l10n.yourTurn;
        color = Colors.green.shade700;
        icon = Icons.touch_app;
        break;
      case GamePhase.checking:
        message = l10n.checking;
        icon = Icons.pending;
        break;
      case GamePhase.success:
        message = l10n.perfect;
        color = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case GamePhase.failure:
        message = state.errorMessage ?? l10n.gameOver;
        color = Colors.red.shade700;
        icon = Icons.error;
        break;
      case GamePhase.gameOver:
        message = l10n.gameOver;
        color = Colors.red.shade700;
        icon = Icons.stop_circle;
        break;
      case GamePhase.levelComplete:
        message = l10n.levelComplete;
        color = Colors.amber.shade700;
        icon = Icons.emoji_events;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: ColorMemoryConstants.cardBackgroundColor,
        borderRadius: BorderRadius.circular(ColorMemoryConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorMemoryGameState state) {
    final l10n = AppLocalizations.of(context);
    final progress = state.playerSequence.length / state.sequence.length;
    final remaining = state.sequence.length - state.playerSequence.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.tapped}: ${state.playerSequence.length}/${state.sequence.length} • $remaining ${l10n.left}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              if (state.mode == ColorMemoryGameMode.timed)
                Text(
                  '${l10n.time}: ${state.remainingTime.toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: state.remainingTime < 3
                        ? Colors.red.shade700
                        : Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green.shade400,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceProgress(ColorMemoryGameState state) {
    final l10n = AppLocalizations.of(context);
    // Count steps the user actually sees: include current highlight if visible
    int shown =
        state.currentSequenceIndex + (state.highlightedColorIndex >= 0 ? 1 : 0);
    shown = shown.clamp(0, state.sequence.length);
    final total = state.sequence.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            '${l10n.showing}: $shown/$total',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: shown / total,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue.shade400,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
