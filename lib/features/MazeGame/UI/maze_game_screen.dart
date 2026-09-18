import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kidzo/core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';
import '../../../core/shared/style/kid_ui.dart';
import '../../../core/shared/widgets/kid_game_shell.dart';
import '../data/logic/maze_cubit.dart';
import '../data/models/maze_models.dart';
import '../data/models/maze_state.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/interactive_maze.dart';

class MazeGameScreen extends StatelessWidget {
  const MazeGameScreen({super.key, this.level = 1});

  final int level;

  @override
  Widget build(BuildContext context) {
    final difficulty = level == 1
        ? MazeDifficulty.easy
        : level == 2
            ? MazeDifficulty.medium
            : MazeDifficulty.hard;

    return BlocProvider(
      create: (context) => MazeCubit(difficulty: difficulty),
      child: const _MazeGameContent(),
    );
  }
}

class _MazeGameContent extends StatefulWidget {
  const _MazeGameContent();

  @override
  State<_MazeGameContent> createState() => _MazeGameContentState();
}

class _MazeGameContentState extends State<_MazeGameContent> {
  bool _hasShownInstructions = false;
  bool _isFullScreen = false;

  /// Guards the results dialog. The listener can fire more than once for the
  /// same finished game (the timer keeps emitting), which used to stack two
  /// identical dialogs on top of each other.
  bool _resultDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // The game no longer opens straight into immersive mode. It used to, which
    // meant a child arrived to a bare maze with the whole HUD hidden and a
    // how-to-play dialog on top of it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasShownInstructions) {
        _hasShownInstructions = true;
        _showInstructionsDialog();
      }
    });
  }

  void _setFullScreen(bool enabled) {
    SystemChrome.setEnabledSystemUIMode(
      enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    if (mounted) setState(() => _isFullScreen = enabled);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _showInstructionsDialog() {
    final cubit = context.read<MazeCubit>();
    showMazeInstructionsDialog(
      context,
      cubit.state.difficulty,
      onStart: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background =
        BackgroundResolver(context, BackgroundType.game).resolveBackground();

    return BlocConsumer<MazeCubit, MazeState>(
      // Only a change of status opens a dialog, never a plain timer tick.
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == MazeGameStatus.won) {
          _showResultDialog(state, true);
        } else if (state.status == MazeGameStatus.lost) {
          _showResultDialog(state, false);
        }
      },
      builder: (context, state) {
        return KidGameShell(
          backgroundAsset: _isFullScreen ? null : background,
          maxContentWidth: 720,
          builder: (context, metrics) => Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _isFullScreen ? 4 : metrics.pagePadding,
                  vertical: _isFullScreen ? 4 : metrics.pagePadding * 0.6,
                ),
                child: Column(
                  children: [
                    if (!_isFullScreen) ...[
                      _MazeHud(
                        metrics: metrics,
                        state: state,
                        onBack: () => _showExitConfirmation(context),
                        onHelp: _showInstructionsDialog,
                        onFullScreen: () => _setFullScreen(true),
                      ),
                      SizedBox(height: metrics.gap * 0.75),
                      _MazeCoach(metrics: metrics, state: state),
                      SizedBox(height: metrics.gap * 0.75),
                    ],
                    Expanded(
                      child: _MazeBoard(
                        metrics: metrics,
                        flat: _isFullScreen,
                        child: InteractiveMaze(
                          state: state,
                          onStartDrawing: (pos) =>
                              context.read<MazeCubit>().startDrawing(pos),
                          onContinueDrawing: (pos) =>
                              context.read<MazeCubit>().continueDrawing(pos),
                          onEndDrawing: () =>
                              context.read<MazeCubit>().endDrawing(),
                        ),
                      ),
                    ),
                    if (!_isFullScreen) ...[
                      SizedBox(height: metrics.gap * 0.75),
                      _NewMazeButton(
                        metrics: metrics,
                        onTap: () {
                          KidHaptics.tap();
                          context.read<MazeCubit>().resetGame();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              if (_isFullScreen)
                Positioned(
                  top: 12,
                  right: 12,
                  child: SafeArea(
                    child: _RoundButton(
                      icon: Icons.fullscreen_exit_rounded,
                      size: metrics.size(48, min: 42, max: 56),
                      onTap: () => _setFullScreen(false),
                      tooltip: AppLocalizations.of(context).exitFullscreen,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          l10n.exitGame,
          style: const TextStyle(fontWeight: FontWeight.w900, color: KidUi.ink),
        ),
        content: Text(l10n.exitGameConfirm),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KidUi.wrong,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KidUi.radiusPill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
  }

  Future<void> _showResultDialog(MazeState state, bool won) async {
    if (_resultDialogOpen) return;
    _resultDialogOpen = true;

    if (won) {
      KidHaptics.success();
      // The old campaign's progress store used to be notified here. It is gone
      // with the level map: the maze is now reached from the Games grid, where
      // nothing is locked and so nothing needs unlocking. Story progress is
      // recorded by the Adventure runner, not by the game itself.
    } else {
      KidHaptics.error();
    }

    showMazeResultDialog(
      context,
      won: won,
      difficulty: state.difficulty,
      starsCollected: state.starsCollected,
      requiredStars: state.requiredStars,
      timeElapsed: state.timeElapsed,
      touchedWall: state.touchedWall,
      onPlayAgain: () {
        Navigator.pop(context);
        _resultDialogOpen = false;
        context.read<MazeCubit>().resetGame();
      },
      onExit: () {
        Navigator.pop(context);
        _resultDialogOpen = false;
        Navigator.pop(context, won);
      },
    );
  }

}

/// Back, difficulty, stars, timer and the two utility buttons, on one line.
///
/// Replaces the old app-bar-plus-chip-row-plus-overflow-menu stack: a
/// three-dot menu is not something a five-year-old opens, so the two actions
/// it hid (how to play, fullscreen) are now buttons in their own right.
class _MazeHud extends StatelessWidget {
  const _MazeHud({
    required this.metrics,
    required this.state,
    required this.onBack,
    required this.onHelp,
    required this.onFullScreen,
  });

  final KidMetrics metrics;
  final MazeState state;
  final VoidCallback onBack;
  final VoidCallback onHelp;
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttonSize = metrics.size(48, min: 42, max: 58);
    final remaining = state.timeRemaining;

    return Row(
      children: [
        _RoundButton(
          icon: Icons.arrow_back_rounded,
          size: buttonSize,
          onTap: onBack,
          tooltip: l10n.goBack,
        ),
        SizedBox(width: metrics.gap * 0.5),
        Expanded(
          child: Wrap(
            spacing: metrics.gap * 0.5,
            runSpacing: metrics.gap * 0.4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Pill(
                metrics: metrics,
                label: state.difficulty.displayName,
                color: state.difficulty.color,
              ),
              if (state.requiredStars > 0)
                _Pill(
                  metrics: metrics,
                  icon: Icons.star_rounded,
                  label: '${state.starsCollected}/${state.requiredStars}',
                  color: KidUi.hint,
                  complete: state.hasCollectedAllStars,
                ),
              if (remaining != null)
                _Pill(
                  metrics: metrics,
                  icon: Icons.timer_rounded,
                  label: _formatTime(remaining),
                  color: remaining < 30
                      ? KidUi.wrong
                      : (remaining < 60 ? KidUi.fruit : KidUi.primary),
                ),
            ],
          ),
        ),
        SizedBox(width: metrics.gap * 0.5),
        _RoundButton(
          icon: Icons.help_outline_rounded,
          size: buttonSize,
          onTap: onHelp,
          tooltip: l10n.howToPlay,
        ),
        SizedBox(width: metrics.gap * 0.4),
        _RoundButton(
          icon: Icons.fullscreen_rounded,
          size: buttonSize,
          onTap: onFullScreen,
          tooltip: l10n.fullscreen,
        ),
      ],
    );
  }

  static String _formatTime(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    return '${safe ~/ 60}:${(safe % 60).toString().padLeft(2, '0')}';
  }
}

/// The one line of guidance a child needs right now.
class _MazeCoach extends StatelessWidget {
  const _MazeCoach({required this.metrics, required this.state});

  final KidMetrics metrics;
  final MazeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    late final String message;
    late final Color color;
    late final IconData icon;

    if (state.currentPosition == null) {
      message = l10n.mazeInstruction1;
      color = KidUi.correct;
      icon = Icons.touch_app_rounded;
    } else if (state.currentPosition == state.endPosition) {
      message = l10n.reachedEnd;
      color = KidUi.correct;
      icon = Icons.emoji_events_rounded;
    } else {
      message = l10n.keepDragging;
      color = KidUi.primary;
      icon = Icons.swipe_rounded;
    }

    return AnimatedContainer(
      duration: KidUi.medium,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.size(16, min: 12, max: 22),
        vertical: metrics.size(12, min: 9, max: 16),
      ),
      decoration: BoxDecoration(
        color: KidUi.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
        boxShadow: KidUi.shadow(color, strength: 0.9),
      ),
      child: Row(
        children: [
          Container(
            width: metrics.size(36, min: 30, max: 44),
            height: metrics.size(36, min: 30, max: 44),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              icon,
              color: Colors.white,
              size: metrics.size(20, min: 16, max: 24),
            ),
          ),
          SizedBox(width: metrics.gap * 0.6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: KidUi.ink,
                fontSize: metrics.size(16, min: 13, max: 20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The maze itself, lifted onto a card so it reads as a physical board.
class _MazeBoard extends StatelessWidget {
  const _MazeBoard({
    required this.metrics,
    required this.child,
    required this.flat,
  });

  final KidMetrics metrics;
  final Widget child;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    if (flat) return child;

    return Container(
      padding: EdgeInsets.all(metrics.size(12, min: 8, max: 18)),
      decoration: BoxDecoration(
        color: KidUi.surface,
        borderRadius: BorderRadius.circular(KidUi.radiusCard),
        boxShadow: KidUi.shadow(Colors.black, strength: 1.1),
      ),
      child: child,
    );
  }
}

class _NewMazeButton extends StatelessWidget {
  const _NewMazeButton({required this.metrics, required this.onTap});

  final KidMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fontSize = metrics.size(20, min: 15, max: 24);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: KidUi.primary,
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
        elevation: 6,
        shadowColor: Colors.black38,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KidUi.radiusPill),
          child: Container(
            height: metrics.size(58, min: 48, max: 68),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded,
                    color: Colors.white, size: fontSize * 1.3),
                SizedBox(width: fontSize * 0.5),
                Text(
                  l10n.newMaze,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: KidUi.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () {
          KidHaptics.tap();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: KidUi.ink, size: size * 0.5),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.metrics,
    required this.label,
    required this.color,
    this.icon,
    this.complete = false,
  });

  final KidMetrics metrics;
  final String label;
  final Color color;
  final IconData? icon;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final fontSize = metrics.size(15, min: 12, max: 18);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.size(12, min: 9, max: 16),
        vertical: metrics.size(7, min: 5, max: 10),
      ),
      decoration: BoxDecoration(
        color: KidUi.surface,
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
        border: Border.all(color: color, width: complete ? 2.5 : 1.5),
        boxShadow: KidUi.shadow(color, strength: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize * 1.2, color: color),
            SizedBox(width: fontSize * 0.3),
          ],
          Text(
            label,
            style: TextStyle(
              color: KidUi.ink,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (complete) ...[
            SizedBox(width: fontSize * 0.25),
            Icon(Icons.check_circle_rounded, size: fontSize, color: color),
          ],
        ],
      ),
    );
  }
}
