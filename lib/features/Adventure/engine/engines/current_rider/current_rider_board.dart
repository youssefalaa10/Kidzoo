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

  /// Which gate the D-Pad currently controls. Resets on every new step so the
  /// child always starts on the first gate rather than a stale selection.
  int _activeGateIndex = 0;

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
      setState(() {
        _setting = Map<String, Drift>.of(widget.step.round.initialSetting);
        _running = null;
        _activeGateIndex = 0;
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

  /// Sets the active gate to [direction] directly. Called by the D-Pad.
  ///
  /// If [direction] is not in the active gate's choices the press is a no-op —
  /// rather than an error — so a disabled button can still register a tap
  /// without breaking anything.
  void _setDirection(Drift direction) {
    if (!_isLive || _round.gates.isEmpty) return;
    final int safeIndex = _activeGateIndex.clamp(0, _round.gates.length - 1);
    final CurrentGate gate = _round.gates[safeIndex];
    if (!gate.choices.contains(direction)) return;
    setState(() => _setting[gate.id] = direction);
    ActivityFeedbackScope.maybeOf(context)?.soundboard.play(ActivitySound.tap);
  }

  /// Selects which gate the D-Pad controls. Only relevant when there are
  /// multiple gates — the child taps one on the board to focus the pad on it.
  void _selectGate(int index) {
    if (!_isLive || index == _activeGateIndex) return;
    KidHaptics.tap();
    setState(() => _activeGateIndex = index);
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
    final bool multiGate = _round.gates.length > 1;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;

        // Controls are measured first; the grid gets what is left. This is the
        // ordering that makes everything fit at 780×390.
        //
        // D-Pad: 3 rows of buttons plus 2 internal gaps.
        final double dpadBtnSize =
            math.min(52.0, (height * 0.30 - 16.0) / 3).clamp(28.0, 52.0);
        final double dpadHeight = dpadBtnSize * 3 + 16.0;
        final double runHeight =
            math.min(KidUi.minTouch * 0.75, height * 0.10).clamp(40.0, 56.0);
        const double gapTotal = 8.0 * 3;
        final double gridHeight =
            (height - dpadHeight - runHeight - gapTotal).clamp(60.0, height);

        final double cell = math.max(
          24,
          math.min(gridHeight / _round.rows, width / _round.columns),
        );
        final double boardWidth = cell * _round.columns;
        final double boardHeight = cell * _round.rows;

        final int safeIndex =
            _activeGateIndex.clamp(0, _round.gates.length - 1);
        final CurrentGate? activeGate =
            _round.gates.isEmpty ? null : _round.gates[safeIndex];
        final Set<Drift> validDrifts =
            activeGate?.choices.toSet() ?? <Drift>{};
        final Drift currentDrift = activeGate == null
            ? Drift.up
            : _setting[activeGate.id] ?? activeGate.initial;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ── board ──────────────────────────────────────────────────────
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
                        cell: Offset(
                            rock.column.toDouble(), rock.row.toDouble()),
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
                    // Gates are visualised as direction arrows. Tapping one
                    // *selects* it for the D-Pad (when there are several) rather
                    // than cycling its direction — that is the D-Pad's job now.
                    for (int i = 0; i < _round.gates.length; i++)
                      _AtCell(
                        cell: Offset(
                          _round.gates[i].cell.column.toDouble(),
                          _round.gates[i].cell.row.toDouble(),
                        ),
                        size: cell,
                        child: _GateArrow(
                          size: cell,
                          flow: _setting[_round.gates[i].id] ??
                              _round.gates[i].initial,
                          accent: _accent,
                          enabled: _isLive,
                          glowing: glowing == _round.gates[i].id,
                          selected: i == safeIndex,
                          label: _round.gates[i].label.resolve(language),
                          // Only wire the tap when there is something to choose
                          // between; a single-gate board has nothing to select.
                          onTap: multiGate && _isLive
                              ? () => _selectGate(i)
                              : null,
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
            // ── D-Pad ──────────────────────────────────────────────────────
            const SizedBox(height: 8),
            _DirectionPad(
              buttonSize: dpadBtnSize,
              accent: _accent,
              enabled: _isLive,
              validDrifts: validDrifts,
              currentDrift: currentDrift,
              onDirection: _setDirection,
            ),
            // ── release ────────────────────────────────────────────────────
            const SizedBox(height: 8),
            _ReleaseButton(
              height: runHeight,
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

// ── grid helpers ──────────────────────────────────────────────────────────────

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
      canvas.drawLine(
          Offset(c * cell, 0), Offset(c * cell, size.height), line);
    }
    for (int r = 1; r < rows; r++) {
      canvas.drawLine(
          Offset(0, r * cell), Offset(size.width, r * cell), line);
    }

    final List<Cell>? path = wake;
    if (path == null || path.length < 2) {
      return;
    }
    final double reached = wakeProgress * (path.length - 1);
    final Path trail = Path()
      ..moveTo(
          (path.first.column + 0.5) * cell, (path.first.row + 0.5) * cell);
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

// ── gate visualisation ────────────────────────────────────────────────────────

/// A current gate, shown on the board as a direction arrow.
///
/// This widget is now **visualisation only**: it shows which way the current is
/// set and, when there are multiple gates, lets the child tap to *select* it
/// for the D-Pad. The D-Pad below the board is what changes the direction.
/// Separating the two removes the small tap-to-cycle target from inside the
/// grid and replaces it with the large, touch-friendly D-Pad buttons.
class _GateArrow extends StatelessWidget {
  const _GateArrow({
    required this.size,
    required this.flow,
    required this.accent,
    required this.enabled,
    required this.glowing,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final double size;
  final Drift flow;
  final Color accent;
  final bool enabled;
  final bool glowing;

  /// True when this gate is the one the D-Pad is currently controlling.
  final bool selected;

  final String label;

  /// Null when tapping does nothing (single-gate boards).
  final VoidCallback? onTap;

  // Icons.arrow_forward_rounded has matchTextDirection: true, so Flutter
  // mirrors it to point LEFT in RTL. Left/right turns must compensate.
  double _turnsFor(bool isRtl) {
    switch (flow) {
      case Drift.up:
        return -0.25;
      case Drift.down:
        return 0.25;
      case Drift.left:
        return isRtl ? 0 : 0.5;
      case Drift.right:
        return isRtl ? 0.5 : 0;
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
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final bool interactive = onTap != null && enabled;

    return Semantics(
      label: label,
      value: _spokenDirection,
      button: interactive,
      enabled: interactive,
      hint: interactive ? 'tap to select this current' : null,
      child: GestureDetector(
        onTap: interactive ? onTap : null,
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: AnimatedContainer(
            duration: KidUi.fast,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: glowing ? 0.3 : (selected ? 0.22 : 0.14),
              ),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(
                color: glowing
                    ? KidUi.hint
                    : selected
                        ? accent.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.35),
                width: glowing ? 3.5 : (selected ? 2.5 : 2),
              ),
              boxShadow: glowing
                  ? <BoxShadow>[
                      BoxShadow(
                        color: KidUi.hint.withValues(alpha: 0.55),
                        blurRadius: size * 0.4,
                      ),
                    ]
                  : selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: size * 0.3,
                          ),
                        ]
                      : const <BoxShadow>[],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: _turnsFor(isRtl),
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

// ── destination ───────────────────────────────────────────────────────────────

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

// ── D-Pad control ─────────────────────────────────────────────────────────────

/// A 4-button directional pad. Replaces the old tap-on-gate mechanic so the
/// child has one large, reachable control rather than four small arrows
/// scattered across the grid.
///
/// Buttons are positioned with explicit pixel offsets so [TextDirection] never
/// swaps left and right. A water current that flows left always flows left —
/// Arabic readers and English readers share the same physical world.
class _DirectionPad extends StatelessWidget {
  const _DirectionPad({
    required this.buttonSize,
    required this.accent,
    required this.enabled,
    required this.validDrifts,
    required this.currentDrift,
    required this.onDirection,
  });

  final double buttonSize;
  final Color accent;
  final bool enabled;

  /// The directions this gate can be turned to. Buttons outside this set are
  /// shown disabled so the child can see all four axes but knows which ones
  /// actually do something.
  final Set<Drift> validDrifts;

  /// Which direction the active gate is currently pointing.
  final Drift currentDrift;

  final ValueChanged<Drift> onDirection;

  @override
  Widget build(BuildContext context) {
    Widget btn(Drift drift, IconData icon, String label) {
      final bool valid = enabled && validDrifts.contains(drift);
      return _DPadButton(
        size: buttonSize,
        icon: icon,
        accent: accent,
        enabled: valid,
        isActive: currentDrift == drift,
        onTap: valid ? () => onDirection(drift) : null,
        semanticLabel: label,
      );
    }

    return SizedBox(
      width: buttonSize * 3,
      height: buttonSize * 3,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: buttonSize,
            top: 0,
            child: btn(Drift.up, Icons.keyboard_arrow_up_rounded, 'up'),
          ),
          Positioned(
            left: 0,
            top: buttonSize,
            child: btn(Drift.left, Icons.keyboard_arrow_left_rounded, 'left'),
          ),
          Positioned(
            left: buttonSize * 2,
            top: buttonSize,
            child:
                btn(Drift.right, Icons.keyboard_arrow_right_rounded, 'right'),
          ),
          Positioned(
            left: buttonSize,
            top: buttonSize * 2,
            child: btn(Drift.down, Icons.keyboard_arrow_down_rounded, 'down'),
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
    required this.isActive,
    required this.onTap,
    required this.semanticLabel,
  });

  final double size;
  final IconData icon;
  final Color accent;
  final bool enabled;

  /// True when this direction is what the gate is currently set to.
  final bool isActive;

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
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.accent
                  : Colors.white
                      .withValues(alpha: live ? 0.92 : 0.30),
              borderRadius: BorderRadius.circular(widget.size * 0.28),
              boxShadow: live
                  ? KidUi.shadow(
                      widget.isActive ? widget.accent : Colors.black,
                      strength: 0.4,
                    )
                  : null,
              border: widget.isActive
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: live ? 0.55 : 0.20),
                      width: 1.5,
                    ),
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.55,
              color: widget.isActive
                  ? Colors.white
                  : widget.accent
                      .withValues(alpha: live ? 1.0 : 0.30),
            ),
          ),
        ),
      ),
    );
  }
}

// ── release button ────────────────────────────────────────────────────────────

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
