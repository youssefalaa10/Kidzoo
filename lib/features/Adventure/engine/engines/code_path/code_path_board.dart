import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_engine.dart';

/// The board, the instruction tray and the strip of instructions so far.
///
/// The strip is the point. A pre-reader cannot read a program, but they can
/// watch a highlight travel along a row of pictures while the thing each
/// picture describes happens on the board above it — which is how "this list
/// *is* the journey" gets across without a word of explanation.
class CodePathBoard extends StatefulWidget {
  const CodePathBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final CodePathStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<CodePathBoard> createState() => _CodePathBoardState();
}

class _CodePathBoardState extends State<CodePathBoard> {
  /// What the child has built so far.
  final List<PathCommand> _program = <PathCommand>[];

  /// The run being played back, or null when the child is still planning.
  PathRun? _running;
  int _frameIndex = 0;
  Timer? _playback;

  /// True while the correct route is being demonstrated rather than driven.
  bool _isGhosting = false;

  static const Duration _step = Duration(milliseconds: 520);

  @override
  void didUpdateWidget(CodePathBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      _reset();
    }
    // The base cubit raises this at `modelled`: the correct route is shown
    // being driven, and then the child drives it themselves. Watching is not
    // the same as doing, so the demonstration never submits anything.
    if (!oldWidget.state.isDemonstrating && widget.state.isDemonstrating) {
      _demonstrate();
    }
  }

  @override
  void dispose() {
    _playback?.cancel();
    super.dispose();
  }

  void _reset() {
    _playback?.cancel();
    setState(() {
      _program.clear();
      _running = null;
      _frameIndex = 0;
      _isGhosting = false;
    });
  }

  bool get _isBusy => _running != null || widget.state.isBoardLocked;

  void _append(PathCommand command) {
    if (_isBusy || _program.length >= widget.step.content.maxCommands) {
      return;
    }
    KidHaptics.tap();
    setState(() => _program.add(command));
  }

  /// Removes the last instruction.
  ///
  /// Undo, not a reset. A child who put one wrong arrow in the middle of six
  /// correct ones should not have to rebuild all six, and being able to take a
  /// step back is most of what makes trying things feel safe.
  void _undo() {
    if (_isBusy || _program.isEmpty) {
      return;
    }
    KidHaptics.tap();
    setState(_program.removeLast);
  }

  void _clear() {
    if (_isBusy || _program.isEmpty) {
      return;
    }
    KidHaptics.tap();
    setState(_program.clear);
  }

  /// Plays the program, then reports it.
  ///
  /// The animation runs **before** the attempt is submitted, so the child sees
  /// what their plan did and only then hears whether it worked. Judging first
  /// would tell them the answer while the cart was still moving, and the
  /// watching is the part that teaches.
  Future<void> _run() async {
    if (_isBusy || _program.isEmpty) {
      return;
    }
    KidHaptics.tap();
    final PathRun run = PathRun.execute(
      content: widget.step.content,
      route: widget.step.route,
      program: _program,
    );
    await _play(run, isGhost: false);
    if (!mounted) {
      return;
    }
    widget.submit(SequenceAttempt(
      _program.map((PathCommand command) => command.name).toList(),
    ));
    // The vehicle stays where it stopped while the coach speaks, then comes
    // home for the next try. Snapping it back instantly would erase the one
    // piece of evidence the child has about what their plan did.
    if (run.outcome != RunOutcome.arrived) {
      setState(() {
        _running = null;
        _frameIndex = 0;
      });
    }
  }

  Future<void> _demonstrate() async {
    final List<PathCommand> solution = widget.step.solution;
    if (solution.isEmpty) {
      return;
    }
    setState(() {
      _program
        ..clear()
        ..addAll(solution);
    });
    await _play(
      PathRun.execute(
        content: widget.step.content,
        route: widget.step.route,
        program: solution,
      ),
      isGhost: true,
    );
    if (!mounted) {
      return;
    }
    // The strip is left empty so the child builds it rather than pressing Go
    // on someone else's answer.
    setState(() {
      _program.clear();
      _running = null;
      _frameIndex = 0;
      _isGhosting = false;
    });
  }

  Future<void> _play(PathRun run, {required bool isGhost}) async {
    final Completer<void> done = Completer<void>();
    setState(() {
      _running = run;
      _frameIndex = 0;
      _isGhosting = isGhost;
    });
    _playback?.cancel();
    _playback = Timer.periodic(_step, (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_frameIndex >= run.frames.length - 1) {
        timer.cancel();
        if (!done.isCompleted) {
          done.complete();
        }
        return;
      }
      setState(() => _frameIndex++);
    });
    return done.future;
  }

  RunFrame get _currentFrame {
    final PathRun? run = _running;
    if (run == null) {
      return RunFrame(
        cell: widget.step.route.start,
        facing: widget.step.route.startFacing,
        commandIndex: -1,
      );
    }
    return run.frames[_frameIndex.clamp(0, run.frames.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final CodePathContent content = widget.step.content;
    final Color accent = content.accentColorValue == null
        ? KidUi.primary
        : Color(content.accentColorValue!);
    final String? highlighted = widget.state.view?.highlightOptionId;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);
        // The instruction buttons are primary targets, so they keep their size
        // and **wrap** onto a second row rather than shrinking to fit a narrow
        // phone. Five controls in one row at 360dp works out at 62dp each,
        // which is half the young-child guidance and exactly the sort of
        // target a four-year-old misses; the board above is the thing that can
        // afford to give up the height.
        final double idealEdge =
            metrics.size(KidUi.minTouchYoung, min: 68, max: 132);
        final double spacing = idealEdge * 0.14;
        final double trayEdge =
            [idealEdge, (constraints.maxWidth - spacing * 3) / 3]
                .reduce((double a, double b) => a < b ? a : b);
        final double stripHeight = trayEdge * 0.62;

        return Column(
          children: <Widget>[
            Expanded(
              child: _Grid(
                content: content,
                route: widget.step.route,
                frame: _currentFrame,
                accent: accent,
                isGhost: _isGhosting,
              ),
            ),
            SizedBox(height: metrics.gap * 0.5),
            _ProgramStrip(
              program: _program,
              height: stripHeight,
              accent: accent,
              activeIndex: _running == null ? -1 : _currentFrame.commandIndex,
              commandMode: content.commandMode,
              onRemoveLast: _undo,
              onClear: _clear,
              isEnabled: !_isBusy,
            ),
            SizedBox(height: metrics.gap * 0.5),
            _CommandTray(
              commands: content.commands,
              edge: trayEdge,
              spacing: spacing,
              accent: accent,
              highlightedCommand: highlighted,
              isEnabled: !_isBusy &&
                  _program.length < content.maxCommands,
              canRun: !_isBusy && _program.isNotEmpty,
              onCommand: _append,
              onRun: _run,
            ),
          ],
        );
      },
    );
  }
}

/// The squares, the walls, the destination and the vehicle.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.content,
    required this.route,
    required this.frame,
    required this.accent,
    required this.isGhost,
  });

  final CodePathContent content;
  final PathRoute route;
  final RunFrame frame;
  final Color accent;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cell = (constraints.maxWidth / content.columns)
            .clamp(0.0, constraints.maxHeight / content.rows);
        final double boardWidth = cell * content.columns;
        final double boardHeight = cell * content.rows;

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              children: <Widget>[
                for (int row = 0; row < content.rows; row++)
                  for (int column = 0; column < content.columns; column++)
                    Positioned(
                      left: column * cell,
                      top: row * cell,
                      width: cell,
                      height: cell,
                      child: _Square(
                        edge: cell,
                        accent: accent,
                        isBlocked:
                            route.blocked.contains(GridCell(column, row)),
                        isGoal: route.goal == GridCell(column, row),
                        goalImage: route.goalImage,
                      ),
                    ),
                AnimatedPositioned(
                  duration: KidUi.medium,
                  curve: Curves.easeInOut,
                  left: frame.cell.column * cell,
                  top: frame.cell.row * cell,
                  width: cell,
                  height: cell,
                  child: _Vehicle(
                    edge: cell,
                    facing: frame.facing,
                    image: content.vehicleImage,
                    cargo: route.cargo?.imageAsset,
                    accent: accent,
                    isBump: frame.isBump,
                    isGhost: isGhost,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({
    required this.edge,
    required this.accent,
    required this.isBlocked,
    required this.isGoal,
    required this.goalImage,
  });

  final double edge;
  final Color accent;
  final bool isBlocked;
  final bool isGoal;
  final String? goalImage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(edge * 0.04),
      child: Container(
        decoration: BoxDecoration(
          color: isBlocked
              ? KidUi.stone.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: isGoal ? 0.96 : 0.72),
          borderRadius: BorderRadius.circular(edge * 0.18),
          border: isGoal
              ? Border.all(color: accent, width: edge * 0.07)
              : null,
        ),
        alignment: Alignment.center,
        child: isGoal && goalImage != null
            ? Padding(
                padding: EdgeInsets.all(edge * 0.14),
                child: Image.asset(goalImage!, fit: BoxFit.contain),
              )
            : isGoal
                ? Icon(Icons.flag_rounded, size: edge * 0.5, color: accent)
                : null,
      ),
    );
  }
}

class _Vehicle extends StatelessWidget {
  const _Vehicle({
    required this.edge,
    required this.facing,
    required this.image,
    required this.cargo,
    required this.accent,
    required this.isBump,
    required this.isGhost,
  });

  final double edge;
  final GridDirection facing;
  final String? image;
  final String? cargo;
  final Color accent;
  final bool isBump;
  final bool isGhost;

  @override
  Widget build(BuildContext context) {
    final Widget body = image != null
        ? Image.asset(image!, fit: BoxFit.contain)
        : Icon(Icons.local_shipping_rounded, size: edge * 0.62, color: accent);

    return Opacity(
      // The demonstration is visibly *not* the child's own vehicle, so nobody
      // has to work out whether what they are watching is something they did.
      opacity: isGhost ? 0.45 : 1,
      child: AnimatedRotation(
        duration: KidUi.fast,
        // Quarter turns from north, so the nose points the way it is going.
        turns: facing.index / 4,
        child: AnimatedScale(
          duration: KidUi.fast,
          // A small recoil instead of a buzzer. Bumping a wall is information,
          // not a mistake to be told off for.
          scale: isBump ? 0.86 : 1,
          child: Padding(
            padding: EdgeInsets.all(edge * 0.12),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                body,
                if (cargo != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Image.asset(
                      cargo!,
                      width: edge * 0.34,
                      height: edge * 0.34,
                      fit: BoxFit.contain,
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

/// The instructions placed so far, in order.
class _ProgramStrip extends StatelessWidget {
  const _ProgramStrip({
    required this.program,
    required this.height,
    required this.accent,
    required this.activeIndex,
    required this.commandMode,
    required this.onRemoveLast,
    required this.onClear,
    required this.isEnabled,
  });

  final List<PathCommand> program;
  final double height;
  final Color accent;

  /// Which instruction is being carried out right now, or -1 when idle.
  final int activeIndex;

  final CommandMode commandMode;
  final VoidCallback onRemoveLast;
  final VoidCallback onClear;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 0.16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(KidUi.radiusPill),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: program.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: program.length,
                    itemBuilder: (BuildContext context, int index) {
                      final bool isActive = index == activeIndex;
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: height * 0.06,
                            vertical: height * 0.12),
                        child: AnimatedScale(
                          duration: KidUi.fast,
                          scale: isActive ? 1.18 : 1,
                          child: Container(
                            width: height * 0.7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? accent
                                  : accent.withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(height * 0.22),
                            ),
                            child: Icon(
                              _iconFor(program[index]),
                              size: height * 0.42,
                              color: isActive ? Colors.white : accent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _StripButton(
            icon: Icons.backspace_rounded,
            edge: height * 0.72,
            accent: accent,
            label: 'Undo',
            onTap: isEnabled && program.isNotEmpty ? onRemoveLast : null,
          ),
          SizedBox(width: height * 0.1),
          _StripButton(
            icon: Icons.restart_alt_rounded,
            edge: height * 0.72,
            accent: accent,
            label: 'Clear',
            onTap: isEnabled && program.isNotEmpty ? onClear : null,
          ),
        ],
      ),
    );
  }
}

class _StripButton extends StatelessWidget {
  const _StripButton({
    required this.icon,
    required this.edge,
    required this.accent,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final double edge;
  final Color accent;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.3 : 1,
          child: SizedBox(
            width: edge,
            height: edge,
            child: Icon(icon, size: edge * 0.56, color: accent),
          ),
        ),
      ),
    );
  }
}

/// The instructions on offer, plus the control that runs them.
class _CommandTray extends StatelessWidget {
  const _CommandTray({
    required this.commands,
    required this.edge,
    required this.spacing,
    required this.accent,
    required this.highlightedCommand,
    required this.isEnabled,
    required this.canRun,
    required this.onCommand,
    required this.onRun,
  });

  final List<PathCommand> commands;
  final double edge;
  final double spacing;
  final Color accent;

  /// Set when the coach is pointing at the instruction to start with.
  final String? highlightedCommand;

  final bool isEnabled;
  final bool canRun;
  final void Function(PathCommand) onCommand;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: <Widget>[
        for (final PathCommand command in commands)
          _CommandButton(
            command: command,
            edge: edge,
            accent: accent,
            isHighlighted: highlightedCommand == command.name,
            onTap: isEnabled ? () => onCommand(command) : null,
          ),
        Semantics(
          button: true,
          enabled: canRun,
          label: 'Go',
          child: GestureDetector(
            onTap: canRun ? onRun : null,
            child: AnimatedOpacity(
              duration: KidUi.fast,
              opacity: canRun ? 1 : 0.35,
              child: Container(
                width: edge,
                height: edge,
                decoration: BoxDecoration(
                  color: KidUi.correct,
                  shape: BoxShape.circle,
                  boxShadow: KidUi.shadow(KidUi.correct, strength: 0.7),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: edge * 0.56,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.command,
    required this.edge,
    required this.accent,
    required this.isHighlighted,
    required this.onTap,
  });

  final PathCommand command;
  final double edge;
  final Color accent;
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: command.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: KidUi.fast,
          width: edge,
          height: edge,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: onTap == null ? 0.4 : 0.94),
            borderRadius: BorderRadius.circular(edge * 0.26),
            border: Border.all(
              color: isHighlighted ? KidUi.hint : Colors.transparent,
              width: isHighlighted ? edge * 0.08 : 0,
            ),
            boxShadow: KidUi.shadow(accent, strength: 0.5),
          ),
          child: Icon(_iconFor(command), size: edge * 0.52, color: accent),
        ),
      ),
    );
  }
}

/// One glyph per instruction, the same one in the tray and in the strip.
///
/// Spatial, not textual: the arrows say where the vehicle goes, so they are
/// **not** mirrored for a right-to-left locale. Mirroring them would make a
/// board that reads correctly in Arabic drive the wrong way.
IconData _iconFor(PathCommand command) {
  switch (command) {
    case PathCommand.north:
      return Icons.arrow_upward_rounded;
    case PathCommand.south:
      return Icons.arrow_downward_rounded;
    case PathCommand.east:
      return Icons.arrow_forward_rounded;
    case PathCommand.west:
      return Icons.arrow_back_rounded;
    case PathCommand.forward:
      return Icons.arrow_upward_rounded;
    case PathCommand.turnLeft:
      return Icons.turn_left_rounded;
    case PathCommand.turnRight:
      return Icons.turn_right_rounded;
  }
}
