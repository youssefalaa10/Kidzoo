import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_engine.dart';

/// The board, the instruction strip and the D-Pad controller.
///
/// The D-Pad replaces the old grid of command buttons. In absolute mode the
/// four arrow keys map directly to north/south/east/west; in relative mode
/// they map to forward/turnLeft/turnRight (the down button is unused in
/// relative mode and shown disabled). The strip shows the growing program and
/// offers undo and clear; the Go button runs it.
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
    final bool canAdd =
        !_isBusy && _program.length < content.maxCommands;
    final bool canRun = !_isBusy && _program.isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final KidMetrics metrics = KidMetrics.of(constraints);

        // D-Pad button size scales with height so the control section never
        // crowds the grid in landscape. Each button is at most 11% of the
        // available height, capped at KidUi.minTouchYoung / 2 so it stays
        // large enough to hit comfortably.
        final double dpadBtnSize = (constraints.maxHeight.isFinite
                ? constraints.maxHeight * 0.11
                : 44.0)
            .clamp(32.0, KidUi.minTouchYoung * 0.52);

        final double runBtnSize = dpadBtnSize * 1.1;
        final double stripHeight = dpadBtnSize * 0.7;

        // In landscape the D-Pad and Go button sit side by side, saving the
        // row a stacked layout would cost. In portrait they stack.
        final bool landscape = constraints.maxWidth > constraints.maxHeight;

        final Widget dpad = _CodeDPad(
          buttonSize: dpadBtnSize,
          accent: accent,
          commandMode: content.commandMode,
          enabled: canAdd,
          highlightedCommand: highlighted,
          onCommand: _append,
        );

        final Widget goBtn = _GoButton(
          size: runBtnSize,
          accent: accent,
          canRun: canRun,
          onRun: _run,
        );

        final Widget controls = landscape
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  dpad,
                  SizedBox(width: metrics.gap),
                  goBtn,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  dpad,
                  SizedBox(height: metrics.gap * 0.5),
                  goBtn,
                ],
              );

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
            controls,
            SizedBox(height: metrics.gap * 0.5),
          ],
        );
      },
    );
  }
}

// ── grid ──────────────────────────────────────────────────────────────────────

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
      opacity: isGhost ? 0.45 : 1,
      child: AnimatedRotation(
        duration: KidUi.fast,
        turns: facing.index / 4,
        child: AnimatedScale(
          duration: KidUi.fast,
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

// ── program strip ─────────────────────────────────────────────────────────────

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

// ── D-Pad ─────────────────────────────────────────────────────────────────────

/// Directional pad that appends commands to the program.
///
/// In **absolute** mode four buttons map to north / south / west / east — the
/// same physical directions as the arrows on the board. In **relative** mode
/// three buttons map to forward / turn-left / turn-right, laid out as a
/// T-shape (forward on top, turns below it). The down button is not shown in
/// relative mode because there is no "back" command.
///
/// Buttons are placed with explicit pixel offsets so [TextDirection] never
/// mirrors them. Spatial controls must match the board, not the text flow.
class _CodeDPad extends StatelessWidget {
  const _CodeDPad({
    required this.buttonSize,
    required this.accent,
    required this.commandMode,
    required this.enabled,
    required this.highlightedCommand,
    required this.onCommand,
  });

  final double buttonSize;
  final Color accent;
  final CommandMode commandMode;
  final bool enabled;
  final String? highlightedCommand;
  final void Function(PathCommand) onCommand;

  @override
  Widget build(BuildContext context) {
    Widget btn(PathCommand command, IconData icon, String label) {
      final bool isHighlighted = highlightedCommand == command.name;
      return _DPadButton(
        size: buttonSize,
        icon: icon,
        accent: accent,
        enabled: enabled,
        isHighlighted: isHighlighted,
        onTap: enabled ? () => onCommand(command) : null,
        semanticLabel: label,
      );
    }

    if (commandMode == CommandMode.relative) {
      // T-shape: forward on top row centre, turns on bottom row sides.
      return SizedBox(
        width: buttonSize * 3,
        height: buttonSize * 2 + 8,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: buttonSize,
              top: 0,
              child: btn(
                PathCommand.forward,
                Icons.arrow_upward_rounded,
                'forward',
              ),
            ),
            Positioned(
              left: 0,
              top: buttonSize + 8,
              child: btn(
                PathCommand.turnLeft,
                Icons.turn_left_rounded,
                'turn left',
              ),
            ),
            Positioned(
              left: buttonSize * 2,
              top: buttonSize + 8,
              child: btn(
                PathCommand.turnRight,
                Icons.turn_right_rounded,
                'turn right',
              ),
            ),
          ],
        ),
      );
    }

    // Absolute mode: 4-button cross.
    return SizedBox(
      width: buttonSize * 3,
      height: buttonSize * 3,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: buttonSize,
            top: 0,
            child: btn(
              PathCommand.north,
              Icons.keyboard_arrow_up_rounded,
              'up',
            ),
          ),
          Positioned(
            left: 0,
            top: buttonSize,
            child: btn(
              PathCommand.west,
              Icons.keyboard_arrow_left_rounded,
              'left',
            ),
          ),
          Positioned(
            left: buttonSize * 2,
            top: buttonSize,
            child: btn(
              PathCommand.east,
              Icons.keyboard_arrow_right_rounded,
              'right',
            ),
          ),
          Positioned(
            left: buttonSize,
            top: buttonSize * 2,
            child: btn(
              PathCommand.south,
              Icons.keyboard_arrow_down_rounded,
              'down',
            ),
          ),
        ],
      ),
    );
  }
}

/// One button on a D-Pad. Stateful so it can animate a pressed scale.
class _DPadButton extends StatefulWidget {
  const _DPadButton({
    required this.size,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.isHighlighted,
    required this.onTap,
    required this.semanticLabel,
  });

  final double size;
  final IconData icon;
  final Color accent;
  final bool enabled;

  /// True when the scaffold coach is pointing at this command.
  final bool isHighlighted;

  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool live = widget.enabled && widget.onTap != null;

    return Semantics(
      button: true,
      enabled: live,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: live ? (_) => setState(() => _pressed = true) : null,
        onTapUp: live
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap!();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.84 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: KidUi.fast,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: live ? 0.94 : 0.30),
              borderRadius: BorderRadius.circular(widget.size * 0.28),
              border: widget.isHighlighted
                  ? Border.all(
                      color: KidUi.hint,
                      width: widget.size * 0.08,
                    )
                  : Border.all(
                      color: Colors.white.withValues(alpha: live ? 0.55 : 0.20),
                      width: 1.5,
                    ),
              boxShadow: live
                  ? KidUi.shadow(
                      widget.isHighlighted ? KidUi.hint : Colors.black,
                      strength: widget.isHighlighted ? 0.7 : 0.4,
                    )
                  : null,
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.55,
              color: widget.accent.withValues(alpha: live ? 1.0 : 0.30),
            ),
          ),
        ),
      ),
    );
  }
}

/// The run button — a circle distinct from the D-Pad so the child cannot
/// accidentally press it while building the program.
class _GoButton extends StatelessWidget {
  const _GoButton({
    required this.size,
    required this.accent,
    required this.canRun,
    required this.onRun,
  });

  final double size;
  final Color accent;
  final bool canRun;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: canRun,
      label: 'Go',
      child: GestureDetector(
        onTap: canRun ? onRun : null,
        child: AnimatedOpacity(
          duration: KidUi.fast,
          opacity: canRun ? 1 : 0.35,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: KidUi.correct,
              shape: BoxShape.circle,
              boxShadow: KidUi.shadow(KidUi.correct, strength: 0.7),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: size * 0.56,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── icon helpers ──────────────────────────────────────────────────────────────

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
