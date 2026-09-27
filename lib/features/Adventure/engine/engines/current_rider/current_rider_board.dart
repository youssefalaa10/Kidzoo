import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_cubit.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_feedback_scope.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

/// Set the currents, then let go and watch.
///
/// The two halves are deliberately separate in time. While the gates are being
/// turned nothing moves, so the child can point at each arrow and say where it
/// will send her; once the current is released nothing can be turned, so what
/// they watch is the consequence of a prediction they already made. Letting
/// them steer mid-run would turn planning into reacting, which is the skill
/// this is not for.
class CurrentRiderBoard extends StatefulWidget {
  const CurrentRiderBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final CurrentRiderStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<CurrentRiderBoard> createState() => _CurrentRiderBoardState();
}

class _CurrentRiderBoardState extends State<CurrentRiderBoard>
    with SingleTickerProviderStateMixin {
  /// How the child has the gates set right now. The only mutable thing on the
  /// board, which is what makes the rest of it predictable.
  late Map<String, Drift> _setting;

  late final AnimationController _run;

  /// The ride being played out, or null when the board is at rest.
  Ride? _running;

  /// Cells already ticked, so the drift sounds once per cell.
  int _ticked = 0;

  @override
  void initState() {
    super.initState();
    _setting = Map<String, Drift>.of(widget.step.round.initialSetting);
    _run = AnimationController(vsync: this)..addListener(_onRunTick);
  }

  @override
  void dispose() {
    _run
      ..removeListener(_onRunTick)
      ..dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CurrentRiderBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      // A new board is a new set of gates. Carrying the old setting over would
      // silently pre-answer part of the next round.
      setState(() {
        _setting = Map<String, Drift>.of(widget.step.round.initialSetting);
        _running = null;
      });
      _run.stop();
    }
  }

  CurrentRound get _round => widget.step.round;

  Color get _accent => widget.step.accentColorValue == null
      ? KidUi.primary
      : Color(widget.step.accentColorValue!);

  bool get _isLive => !widget.state.isBoardLocked && !_run.isAnimating;

  /// The gate the modelled rung is pointing at, or null when it is not.
  String? get _gateToGlow =>
      widget.state.scaffoldLevel == ScaffoldLevel.modelled
          ? _round.gateToTurn(_setting)
          : null;

  void _turn(CurrentGate gate) {
    if (!_isLive) {
      return;
    }
    final Drift now = _setting[gate.id] ?? gate.initial;
    final int next = (gate.choices.indexOf(now) + 1) % gate.choices.length;
    setState(() => _setting[gate.id] = gate.choices[next]);
    ActivityFeedbackScope.maybeOf(context)?.soundboard.play(ActivitySound.tap);
  }

  /// Runs the current, then reports the configuration that produced it.
  ///
  /// The board animates first and submits afterwards, so the child sees what
  /// happened before they are told about it. The path it animates is the same
  /// pure [CurrentRound.ride] the cubit will judge, so the two can never
  /// disagree about where she went.
  Future<void> _release() async {
    if (!_isLive) {
      return;
    }
    final Ride ride = _round.ride(_setting);
    setState(() {
      _running = ride;
      _ticked = 0;
    });
    _run.duration = _driftPerCell * ride.path.length + _settle;
    // `orCancel` rejects if the board is disposed mid-run — a child backing
    // out of the activity while she is still drifting, which is ordinary.
    await _run.forward(from: 0).orCancel.catchError((Object _) {});
    if (!mounted) {
      return;
    }
    setState(() => _running = null);
    widget.submit(
      SequenceAttempt(CurrentRiderStep.tokensFor(_round, _setting)),
    );
  }

  /// Slow enough to be followed cell by cell. A child who cannot see which way
  /// she turned has learned nothing from the run.
  static const Duration _driftPerCell = Duration(milliseconds: 420);
  static const Duration _settle = Duration(milliseconds: 260);

  void _onRunTick() {
    final Ride? ride = _running;
    if (ride == null) {
      return;
    }
    final int reached =
        (_run.value * ride.path.length).floor().clamp(0, ride.path.length);
    if (reached <= _ticked) {
      return;
    }
    _ticked = reached;
    ActivityFeedbackScope.maybeOf(context)?.soundboard.play(ActivitySound.tap);
  }

  /// Where the rider is, in fractional cell coordinates.
  ///
  /// Between cells while the run is playing, and on the last safe cell once it
  /// is over — which is the gentle return the round needs. Nothing is ever
  /// removed from the board and there is no failure state to land in.
  Offset get _riderAt {
    final Ride? ride = _running;
    if (ride == null) {
      return Offset(
          _round.start.column.toDouble(), _round.start.row.toDouble());
    }
    final double travelled =
        (_run.value * (ride.path.length - 1) * _totalOverTravel)
            .clamp(0.0, (ride.path.length - 1).toDouble());
    final int index = travelled.floor();
    final double fraction = travelled - index;
    final Cell from = ride.path[index];
    final Cell to = ride.path[math.min(index + 1, ride.path.length - 1)];
    return Offset(
      from.column + (to.column - from.column) * fraction,
      from.row + (to.row - from.row) * fraction,
    );
  }

  /// The run occupies the drift portion of the controller; the settle at the
  /// end is time for the child to see where she stopped.
  double get _totalOverTravel {
    final Ride? ride = _running;
    if (ride == null || ride.path.length < 2) {
      return 1;
    }
    final double drift =
        (_driftPerCell.inMilliseconds * ride.path.length).toDouble();
    return (drift + _settle.inMilliseconds) / drift;
  }

  @override
  Widget build(BuildContext context) {
    final String language = widget.state.languageCode;
    final String? glowing = _gateToGlow;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;

        // The button is measured first and the grid gets what is left, rather
        // than the grid taking what it wants and the button overflowing. That
        // ordering is the whole reason this fits at 780x390, where the height
        // left for a 4-row grid is under a hundred pixels per row.
        final double buttonHeight = math.min(KidUi.minTouch, height * 0.2);
        final double gridHeight = height - buttonHeight - 16;
        final double cell = math.max(
          24,
          math.min(gridHeight / _round.rows, width / _round.columns),
        );
        final double boardWidth = cell * _round.columns;
        final double boardHeight = cell * _round.rows;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: boardWidth,
              height: boardHeight,
              child: AnimatedBuilder(
                animation: _run,
                builder: (BuildContext context, Widget? _) => Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _WaterPainter(
                          columns: _round.columns,
                          rows: _round.rows,
                          accent: _accent,
                          depth: widget.step.depth,
                          wake: _running?.path,
                          wakeProgress: _running == null ? 0 : _run.value,
                        ),
                      ),
                    ),
                    for (final Cell rock in _round.rocks)
                      _AtCell(
                        cell:
                            Offset(rock.column.toDouble(), rock.row.toDouble()),
                        size: cell,
                        child: Padding(
                          padding: EdgeInsets.all(cell * 0.1),
                          child: Image.asset(widget.step.rockImage,
                              fit: BoxFit.contain),
                        ),
                      ),
                    _AtCell(
                      cell: Offset(_round.goal.column.toDouble(),
                          _round.goal.row.toDouble()),
                      size: cell,
                      child: _Goal(
                        size: cell,
                        image: widget.step.goalImage,
                        accent: _accent,
                      ),
                    ),
                    for (final CurrentGate gate in _round.gates)
                      _AtCell(
                        cell: Offset(gate.cell.column.toDouble(),
                            gate.cell.row.toDouble()),
                        size: cell,
                        child: _GateArrow(
                          size: cell,
                          flow: _setting[gate.id] ?? gate.initial,
                          accent: _accent,
                          enabled: _isLive,
                          glowing: glowing == gate.id,
                          label: gate.label.resolve(language),
                          onTap: () => _turn(gate),
                        ),
                      ),
                    _AtCell(
                      cell: _riderAt,
                      size: cell,
                      child: Padding(
                        padding: EdgeInsets.all(cell * 0.08),
                        child: Image.asset(widget.step.riderImage,
                            fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ReleaseButton(
              height: buttonHeight,
              width: math.min(boardWidth, width),
              accent: _accent,
              enabled: _isLive,
              running: _run.isAnimating,
              onPressed: _release,
            ),
          ],
        );
      },
    );
  }
}

/// Places a child on the grid, at fractional cell coordinates so the rider can
/// sit between two cells while it drifts.
class _AtCell extends StatelessWidget {
  const _AtCell({required this.cell, required this.size, required this.child});

  final Offset cell;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: cell.dx * size,
      top: cell.dy * size,
      width: size,
      height: size,
      child: child,
    );
  }
}

/// The water, its grid, and the wake behind the rider.
class _WaterPainter extends CustomPainter {
  const _WaterPainter({
    required this.columns,
    required this.rows,
    required this.accent,
    required this.depth,
    required this.wake,
    required this.wakeProgress,
  });

  final int columns;
  final int rows;
  final Color accent;

  /// 0 at the top of the descent, 1 at the bottom. The water darkens with it,
  /// so a child who has got through two boards is visibly deeper than one who
  /// has got through none — progress told by the world rather than by a bar.
  final double depth;

  final List<Cell>? wake;
  final double wakeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / columns;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(accent, Colors.black, 0.25 + depth * 0.35) ?? accent,
            Color.lerp(accent, Colors.black, 0.45 + depth * 0.4) ?? accent,
          ],
        ).createShader(Offset.zero & size),
    );

    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10);
    for (int c = 1; c < columns; c++) {
      canvas.drawLine(Offset(c * cell, 0), Offset(c * cell, size.height), line);
    }
    for (int r = 1; r < rows; r++) {
      canvas.drawLine(Offset(0, r * cell), Offset(size.width, r * cell), line);
    }

    final List<Cell>? path = wake;
    if (path == null || path.length < 2) {
      return;
    }
    // The wake is the record of the run, drawn behind her as she goes, so a
    // child who got it wrong can see the whole route that did not work rather
    // than only the rock she stopped at.
    final double reached = wakeProgress * (path.length - 1);
    final Path trail = Path()
      ..moveTo((path.first.column + 0.5) * cell, (path.first.row + 0.5) * cell);
    for (int index = 1; index < path.length; index++) {
      if (index > reached) {
        break;
      }
      trail.lineTo(
          (path[index].column + 0.5) * cell, (path[index].row + 0.5) * cell);
    }
    canvas.drawPath(
      trail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = KidUi.hint.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_WaterPainter old) =>
      old.depth != depth ||
      old.wake != wake ||
      old.wakeProgress != wakeProgress ||
      old.accent != accent;
}

/// A current the child can turn. Tapped, never dragged: a drag on a cell this
/// small is a gesture a lot of four-year-olds cannot land, and there is nothing
/// a rotation drag expresses that a cycle of two or three taps does not.
class _GateArrow extends StatelessWidget {
  const _GateArrow({
    required this.size,
    required this.flow,
    required this.accent,
    required this.enabled,
    required this.glowing,
    required this.label,
    required this.onTap,
  });

  final double size;
  final Drift flow;
  final Color accent;
  final bool enabled;
  final bool glowing;
  final String label;
  final VoidCallback onTap;

  double get _turns {
    switch (flow) {
      case Drift.up:
        return -0.25;
      case Drift.down:
        return 0.25;
      case Drift.left:
        return 0.5;
      case Drift.right:
        return 0;
    }
  }

  String get _spokenDirection {
    switch (flow) {
      case Drift.up:
        return 'pointing up';
      case Drift.down:
        return 'pointing down';
      case Drift.left:
        return 'pointing left';
      case Drift.right:
        return 'pointing right';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: _spokenDirection,
      button: true,
      enabled: enabled,
      hint: 'tap to turn the current',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: AnimatedContainer(
            duration: KidUi.fast,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: glowing ? 0.3 : 0.14),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(
                color:
                    glowing ? KidUi.hint : Colors.white.withValues(alpha: 0.35),
                width: glowing ? 3.5 : 2,
              ),
              boxShadow: glowing
                  ? <BoxShadow>[
                      BoxShadow(
                        color: KidUi.hint.withValues(alpha: 0.55),
                        blurRadius: size * 0.4,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: _turns,
                duration: KidUi.fast,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: size * 0.5,
                  color: KidUi.hint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where she is going: the art, with the water glowing behind it so the target
/// reads as a destination rather than as one more object on the board.
class _Goal extends StatelessWidget {
  const _Goal({required this.size, required this.image, required this.accent});

  final double size;
  final String image;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'the way down',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: KidUi.hint.withValues(alpha: 0.4),
              blurRadius: size * 0.4,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: Image.asset(image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// "Let's go". One button, and the only thing on the board that is an answer.
class _ReleaseButton extends StatelessWidget {
  const _ReleaseButton({
    required this.height,
    required this.width,
    required this.accent,
    required this.enabled,
    required this.running,
    required this.onPressed,
  });

  final double height;
  final double width;
  final Color accent;
  final bool enabled;
  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'let the current go',
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: KidUi.fast,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(KidUi.radiusPill),
              boxShadow: KidUi.shadow(accent),
            ),
            child: Center(
              child: Icon(
                running ? Icons.waves_rounded : Icons.play_arrow_rounded,
                // Sized off the button rather than fixed, so it shrinks with
                // the button on a short landscape board instead of pushing it.
                size: height * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
