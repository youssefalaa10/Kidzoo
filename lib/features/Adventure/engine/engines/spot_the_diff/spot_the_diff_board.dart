import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_cubit.dart';

/// Two square panels of one scene, side by side or stacked — whichever makes
/// them bigger in the box the host gives.
///
/// **Nothing marks an unfound difference until the child has asked for
/// help.** The first version drew a pulsing ring over every one from the
/// first frame, which turned "find what changed" into "tap the rings".
///
/// A tap that finds nothing is not submitted. It gets a small local ripple
/// and nothing else: a child scanning a picture by touching it is looking,
/// not answering, and counting every look as wrong would walk them up the
/// no-fail ladder to a free answer. The help button and the idle nudge are
/// the route to hints.
class SpotDiffBoard extends StatefulWidget {
  const SpotDiffBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final SpotDiffStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<SpotDiffBoard> createState() => _SpotDiffBoardState();
}

class _SpotDiffBoardState extends State<SpotDiffBoard>
    with TickerProviderStateMixin {
  /// Runs only while a hint is showing. A scene with nothing to point at has
  /// nothing to animate, so there is no controller ticking behind it.
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// The "nothing here" ripple, played once per missed tap.
  late final AnimationController _miss = AnimationController(
    vsync: this,
    duration: KidUi.medium,
  );
  Offset? _missAt;
  bool _missOnLeft = true;

  @override
  void initState() {
    super.initState();
    _syncHint();
  }

  @override
  void didUpdateWidget(SpotDiffBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncHint();
  }

  @override
  void dispose() {
    _hint.dispose();
    _miss.dispose();
    super.dispose();
  }

  void _syncHint() {
    if (_highlighted != null) {
      if (!_hint.isAnimating) {
        _hint.repeat();
      }
    } else if (_hint.isAnimating) {
      _hint
        ..stop()
        ..value = 0;
    }
  }

  SpotDiffContent get _content => widget.step.content;

  Color get _accent => _content.accentColorValue == null
      ? KidUi.primary
      : Color(_content.accentColorValue!);

  String? get _highlighted => widget.state.view?.highlightOptionId;

  Set<String> get _found =>
      (widget.state.view?.dimmedOptionIds ?? const <String>[]).toSet();

  void _tapAt(Offset fraction, {required bool left}) {
    if (widget.state.isBoardLocked) {
      return;
    }
    final Set<String> found = _found;
    final List<String> live =
        widget.state.view?.liveOptionIds ?? const <String>[];
    DiffSpot? closest;
    double best = double.infinity;
    for (final DiffSpot spot in _content.spots) {
      if (found.contains(spot.id) || !live.contains(spot.id)) {
        continue;
      }
      final double distance =
          (fraction - (left ? spot.fractionLeft : spot.fractionRight)).distance;
      if (distance < best) {
        best = distance;
        closest = spot;
      }
    }
    if (closest != null && best <= closest.hitRadius) {
      widget.submit(ChoiceAttempt(closest.id));
      return;
    }
    setState(() {
      _missAt = fraction;
      _missOnLeft = left;
    });
    _miss.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360;
        final double height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 480;
        final double gap = math.max(6, math.min(width, height) * 0.03);
        final double sideBySide =
            math.min((width - gap) / 2, height).clamp(0, double.infinity);
        final double stacked =
            math.min(width, (height - gap) / 2).clamp(0, double.infinity);
        final bool horizontal = sideBySide >= stacked;
        final double side = horizontal ? sideBySide : stacked;

        final List<Widget> panels = <Widget>[
          _panel(side, left: true),
          SizedBox(width: gap, height: gap),
          _panel(side, left: false),
        ];
        return Center(
          child: horizontal
              ? Row(mainAxisSize: MainAxisSize.min, children: panels)
              : Column(mainAxisSize: MainAxisSize.min, children: panels),
        );
      },
    );
  }

  Widget _panel(double side, {required bool left}) {
    final Set<String> found = _found;
    final String? highlighted = _highlighted;
    final ScaffoldLevel level = widget.state.scaffoldLevel;
    return Semantics(
      label: left ? 'the first picture' : 'the second picture',
      hint: 'tap what is different',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) => _tapAt(
          Offset(details.localPosition.dx / side,
              details.localPosition.dy / side),
          left: left,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KidUi.radiusCard * 0.6),
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  left ? _content.imageLeft : _content.imageRight,
                  fit: BoxFit.fill,
                  // Decoded at the size it is drawn, not at the file's size.
                  cacheWidth: (side * 2).round(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(KidUi.radiusCard * 0.6),
                    border: Border.all(
                        color: _accent.withValues(alpha: 0.7), width: 3),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _MarksPainter(
                      spots: _content.spots,
                      found: found,
                      highlighted: highlighted,
                      tight: level == ScaffoldLevel.modelled,
                      left: left,
                      accent: _accent,
                      hint: _hint,
                      miss: _missOnLeft == left ? _missAt : null,
                      missProgress: _miss,
                    ),
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

/// Found marks, the hint, and the miss ripple, in one painter so a panel is
/// one layer however many spots it has.
class _MarksPainter extends CustomPainter {
  _MarksPainter({
    required this.spots,
    required this.found,
    required this.highlighted,
    required this.tight,
    required this.left,
    required this.accent,
    required this.hint,
    required this.miss,
    required this.missProgress,
  }) : super(repaint: Listenable.merge(<Listenable>[hint, missProgress]));

  final List<DiffSpot> spots;
  final Set<String> found;
  final String? highlighted;

  /// Modelled: a ring on the spot itself. Before that, a wide halo that says
  /// "around here" and still leaves the finding to the child.
  final bool tight;
  final bool left;
  final Color accent;
  final Animation<double> hint;
  final Offset? miss;
  final Animation<double> missProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.shortestSide;
    for (final DiffSpot spot in spots) {
      final Offset at = _at(spot, size);
      final double radius = spot.hitRadius * side;
      if (found.contains(spot.id)) {
        canvas.drawCircle(
          at,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(3, side * 0.014)
            ..color = KidUi.correct,
        );
        continue;
      }
      if (spot.id == highlighted) {
        final double wave = math.sin(hint.value * 2 * math.pi) * 0.5 + 0.5;
        final double reach = radius * (tight ? 1 + wave * 0.25 : 2.4);
        canvas.drawCircle(
          at,
          reach,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2, side * (tight ? 0.014 : 0.008))
            ..color = KidUi.hint.withValues(alpha: tight ? 0.95 : 0.35 + wave * 0.4),
        );
      }
    }
    final Offset? missAt = miss;
    if (missAt != null && missProgress.value > 0 && missProgress.value < 1) {
      final double t = missProgress.value;
      canvas.drawCircle(
        Offset(missAt.dx * size.width, missAt.dy * size.height),
        side * (0.03 + t * 0.06),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: (1 - t) * 0.8),
      );
    }
  }

  Offset _at(DiffSpot spot, Size size) {
    final Offset fraction = left ? spot.fractionLeft : spot.fractionRight;
    return Offset(fraction.dx * size.width, fraction.dy * size.height);
  }

  @override
  bool shouldRepaint(_MarksPainter old) =>
      old.found.length != found.length ||
      old.highlighted != highlighted ||
      old.tight != tight ||
      old.miss != miss ||
      old.accent != accent;
}
