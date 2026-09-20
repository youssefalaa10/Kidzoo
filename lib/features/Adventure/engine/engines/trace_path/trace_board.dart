import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';
import 'package:kidzo/features/Adventure/engine/host/widgets/activity_glyph_text.dart';

/// The figure, and the child's line across it.
///
/// Two ways in, both first-class. A finger dragged across the points fills the
/// line in as it goes; a finger that taps them one at a time does exactly the
/// same thing. Drag succeeds as little as a third of the time for some
/// children this age, so the tap route is not an accessibility afterthought —
/// for a good number of children it is the only one that works.
class TraceBoard extends StatefulWidget {
  const TraceBoard({
    required this.step,
    required this.state,
    required this.submit,
    super.key,
  });

  final TraceStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  @override
  State<TraceBoard> createState() => _TraceBoardState();
}

class _TraceBoardState extends State<TraceBoard>
    with SingleTickerProviderStateMixin {
  /// The last anchor reached, as an index into the figure's walk. -1 before
  /// the child has touched the first point.
  int _reached = -1;

  /// The line being drawn right now, in normalized coordinates.
  final List<Offset> _stroke = <Offset>[];

  bool _isDragging = false;

  /// Runs the demonstration: the line draws itself along the figure.
  late final AnimationController _ghost = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  Size _box = Size.zero;

  List<TraceAnchor> get _walk => widget.step.figure.walk;

  @override
  void didUpdateWidget(TraceBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.stepId != widget.step.stepId) {
      setState(() {
        _reached = -1;
        _stroke.clear();
        _isDragging = false;
      });
      _ghost.reset();
    }
    if (!oldWidget.state.isDemonstrating && widget.state.isDemonstrating) {
      // Shown, then cleared, so the child draws it rather than watching it be
      // drawn and being told they have done it.
      setState(() {
        _reached = -1;
        _stroke.clear();
      });
      _ghost.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ghost.dispose();
    super.dispose();
  }

  Offset _normalize(Offset local) {
    if (_box.isEmpty) {
      return Offset.zero;
    }
    return Offset(local.dx / _box.width, local.dy / _box.height);
  }

  /// Advances the line if [point] has landed on the next anchor.
  ///
  /// Returns true when that anchor was the last one, which is the only moment
  /// the board reports anything on a correct path.
  bool _advanceThrough(Offset point) {
    final int next = _reached + 1;
    if (next >= _walk.length) {
      return false;
    }
    if ((point - _walk[next].position).distance > widget.step.tolerance) {
      return false;
    }
    setState(() => _reached = next);
    KidHaptics.tap();
    return next == _walk.length - 1;
  }

  void _handleTap(Offset local) {
    if (widget.state.isBoardLocked) {
      return;
    }
    final Offset point = _normalize(local);
    if (_advanceThrough(point)) {
      widget.submit(ChoiceAttempt(widget.step.figure.lastAnchor.id));
      return;
    }

    // A tap that hit some *other* anchor is the child having read the figure
    // in the wrong order, and that is the one thing worth answering. A tap on
    // empty space is not an answer at all — it is a four-year-old resting a
    // finger on the screen — so it is ignored rather than counted against
    // them.
    for (int index = 0; index < _walk.length; index++) {
      if (index == _reached + 1) {
        continue;
      }
      if ((point - _walk[index].position).distance <= widget.step.tolerance) {
        widget.submit(ChoiceAttempt(_walk[index].id));
        return;
      }
    }
  }

  void _handleDragStart(Offset local) {
    if (widget.state.isBoardLocked) {
      return;
    }
    setState(() {
      _isDragging = true;
      _stroke
        ..clear()
        ..add(_normalize(local));
    });
    _advanceThrough(_normalize(local));
  }

  void _handleDragUpdate(Offset local) {
    if (!_isDragging || widget.state.isBoardLocked) {
      return;
    }
    final Offset point = _normalize(local);
    setState(() => _stroke.add(point));
    _advanceThrough(point);
  }

  void _handleDragEnd() {
    if (!_isDragging) {
      return;
    }
    setState(() => _isDragging = false);
    if (_stroke.length < 2) {
      return;
    }
    // Reported whole, on the lift. Sending it point by point would spend the
    // no-fail ladder inside a single gesture.
    widget.submit(StrokeAttempt(
      points: List<Offset>.of(_stroke),
      strokeIndex: 0,
    ));
    if (_reached < _walk.length - 1) {
      // The line did not make it. Clear it so the next try starts from a clean
      // figure instead of on top of an abandoned one.
      setState(() {
        _stroke.clear();
        _reached = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.step.accentColorValue == null
        ? KidUi.primary
        : Color(widget.step.accentColorValue!);
    final bool isHinting = widget.state.view?.highlightOptionId != null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // A square box, so a figure authored as percentages keeps its
        // proportions instead of being stretched into a different shape by the
        // screen it lands on.
        final double edge = constraints.biggest.shortestSide;
        _box = Size(edge, edge);

        return Center(
          child: SizedBox(
            width: edge,
            height: edge,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails details) =>
                  _handleTap(details.localPosition),
              onPanStart: (DragStartDetails details) =>
                  _handleDragStart(details.localPosition),
              onPanUpdate: (DragUpdateDetails details) =>
                  _handleDragUpdate(details.localPosition),
              onPanEnd: (DragEndDetails _) => _handleDragEnd(),
              child: Stack(
                children: <Widget>[
                  if (widget.step.figure.underlayImage != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.35,
                        child: Image.asset(
                          widget.step.figure.underlayImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _ghost,
                      builder: (BuildContext context, Widget? _) {
                        return CustomPaint(
                          painter: _FigurePainter(
                            walk: _walk,
                            reached: _reached,
                            stroke: _stroke,
                            accent: accent,
                            showGuide: widget.step.figure.showGuide,
                            isHintingNext: isHinting,
                            ghostProgress:
                                _ghost.isAnimating ? _ghost.value : 0,
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.step.figure.showNumbers)
                    for (int index = 0;
                        index < widget.step.figure.anchors.length;
                        index++)
                      _AnchorNumber(
                        anchor: widget.step.figure.anchors[index],
                        number: index + 1,
                        box: _box,
                        accent: accent,
                        isDone: index <= _reached,
                        languageCode: widget.state.languageCode,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The number on a dot, for the dot-to-dot reading of a figure.
class _AnchorNumber extends StatelessWidget {
  const _AnchorNumber({
    required this.anchor,
    required this.number,
    required this.box,
    required this.accent,
    required this.isDone,
    required this.languageCode,
  });

  final TraceAnchor anchor;
  final int number;
  final Size box;
  final Color accent;
  final bool isDone;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final double size = box.shortestSide * 0.09;
    return Positioned(
      left: anchor.position.dx * box.width - size,
      top: anchor.position.dy * box.height - size * 2.1,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: KidUi.fast,
          opacity: isDone ? 0.35 : 1,
          child: ActivityGlyphText(
            '$number',
            languageCode: languageCode,
            fontSize: size,
            color: accent,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// Draws the road, the dots and the line so far.
class _FigurePainter extends CustomPainter {
  const _FigurePainter({
    required this.walk,
    required this.reached,
    required this.stroke,
    required this.accent,
    required this.showGuide,
    required this.isHintingNext,
    required this.ghostProgress,
  });

  final List<TraceAnchor> walk;
  final int reached;
  final List<Offset> stroke;
  final Color accent;
  final bool showGuide;
  final bool isHintingNext;

  /// 0 when idle, otherwise how far through the demonstration.
  final double ghostProgress;

  Offset _at(TraceAnchor anchor, Size size) =>
      Offset(anchor.position.dx * size.width, anchor.position.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.shortestSide;

    if (showGuide) {
      _paintGuide(canvas, size, unit);
    }
    _paintCompleted(canvas, size, unit);
    if (ghostProgress > 0) {
      _paintGhost(canvas, size, unit);
    }
    _paintFreeStroke(canvas, size, unit);
    _paintAnchors(canvas, size, unit);
  }

  /// The dotted road between the points.
  void _paintGuide(Canvas canvas, Size size, double unit) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit * 0.035
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.2);

    for (int index = 1; index < walk.length; index++) {
      _dashed(canvas, _at(walk[index - 1], size), _at(walk[index], size), paint,
          unit);
    }
  }

  void _dashed(Canvas canvas, Offset from, Offset to, Paint paint, double unit) {
    final double length = (to - from).distance;
    if (length == 0) {
      return;
    }
    final double dash = unit * 0.035;
    final Offset direction = (to - from) / length;
    for (double travelled = 0; travelled < length; travelled += dash * 2) {
      final Offset start = from + direction * travelled;
      final Offset end =
          from + direction * (travelled + dash).clamp(0.0, length);
      canvas.drawLine(start, end, paint);
    }
  }

  /// The part of the figure the child has already drawn.
  void _paintCompleted(Canvas canvas, Size size, double unit) {
    if (reached < 1) {
      return;
    }
    final Path path = Path()..moveTo(_at(walk.first, size).dx, _at(walk.first, size).dy);
    for (int index = 1; index <= reached && index < walk.length; index++) {
      final Offset point = _at(walk[index], size);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
  }

  /// The demonstration drawing itself.
  void _paintGhost(Canvas canvas, Size size, double unit) {
    final double target = ghostProgress * (walk.length - 1);
    final int whole = target.floor();
    final Path path = Path()
      ..moveTo(_at(walk.first, size).dx, _at(walk.first, size).dy);
    for (int index = 1; index <= whole && index < walk.length; index++) {
      final Offset point = _at(walk[index], size);
      path.lineTo(point.dx, point.dy);
    }
    if (whole + 1 < walk.length) {
      final Offset from = _at(walk[whole], size);
      final Offset to = _at(walk[whole + 1], size);
      final Offset partial = from + (to - from) * (target - whole);
      path.lineTo(partial.dx, partial.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.05
        ..strokeCap = StrokeCap.round
        ..color = KidUi.hint,
    );
  }

  /// The raw line under the child's finger, so the drawing feels like drawing
  /// rather than like a series of snaps.
  void _paintFreeStroke(Canvas canvas, Size size, double unit) {
    if (stroke.length < 2) {
      return;
    }
    final Path path = Path()
      ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
    for (final Offset point in stroke.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * 0.03
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.4),
    );
  }

  void _paintAnchors(Canvas canvas, Size size, double unit) {
    for (int index = 0; index < walk.length; index++) {
      final bool isDone = index <= reached;
      final bool isNext = index == reached + 1;
      // A corner is where a hand has to stop and turn, so it gets a bigger
      // target than a point the line merely passes through.
      final double radius =
          unit * (walk[index].isCorner ? 0.055 : 0.042) * (isNext ? 1.25 : 1);
      canvas.drawCircle(
        _at(walk[index], size),
        radius,
        Paint()
          ..color = isDone
              ? accent
              : isNext && isHintingNext
                  ? KidUi.hint
                  : accent.withValues(alpha: 0.35),
      );
      if (isNext) {
        canvas.drawCircle(
          _at(walk[index], size),
          radius * 1.6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit * 0.012
            ..color = (isHintingNext ? KidUi.hint : accent)
                .withValues(alpha: 0.55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.reached != reached ||
      old.stroke.length != stroke.length ||
      old.ghostProgress != ghostProgress ||
      old.isHintingNext != isHintingNext ||
      old.walk != walk;
}
