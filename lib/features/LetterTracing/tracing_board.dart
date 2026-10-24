import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'tracing_cubit.dart';
import 'tracing_letter.dart';

class TracingBoard extends StatelessWidget {
  const TracingBoard(
      {required this.cubit,
      required this.state,
      required this.onBegin,
      required this.demonstration,
      required this.label,
      super.key});
  final TracingCubit cubit;
  final TracingState state;
  final VoidCallback onBegin;
  final double? demonstration;
  final String label;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        final scale = side / 320;
        final origin = Offset((box.maxWidth - 300 * scale) / 2,
            (box.maxHeight - 300 * scale) / 2);
        Offset local(Offset point) => (point - origin) / scale;
        return Semantics(
            label: label,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: demonstration != null
                  ? null
                  : (event) {
                      onBegin();
                      cubit.down(local(event.localPosition), event.pointer);
                    },
              onPointerMove: demonstration != null
                  ? null
                  : (event) =>
                      cubit.move(local(event.localPosition), event.pointer),
              onPointerUp: (event) => cubit.up(event.pointer),
              onPointerCancel: (event) => cubit.cancel(event.pointer),
              child: RepaintBoundary(
                  child: CustomPaint(
                size: Size(box.maxWidth, box.maxHeight),
                painter: TracingPainter(
                    strokes: cubit.strokes,
                    state: state,
                    origin: origin,
                    scale: scale,
                    demonstration: demonstration),
              )),
            ));
      });
}

class TracingPainter extends CustomPainter {
  TracingPainter(
      {required this.strokes,
      required this.state,
      required this.origin,
      required this.scale,
      this.demonstration});
  final List<TraceStroke> strokes;
  final TracingState state;
  final Offset origin;
  final double scale;
  final double? demonstration;
  static const ink = Color(0xff147d94);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final rule = Paint()
      ..color = const Color(0xffe5edf3)
      ..strokeWidth = 1;
    for (final y in [50.0, 115.0, 225.0, 280.0]) {
      for (var x = 20.0; x < 290; x += 12) {
        canvas.drawLine(Offset(x, y), Offset(x + 5, y), rule);
      }
    }
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 31
      ..color = ink;
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 26
      ..color = const Color(0xfff5fbff);
    // Draw all outlines first, so joins look like one hollow letter.
    for (final s in strokes) {
      canvas.drawPath(s.path, outer);
    }
    for (final s in strokes) {
      canvas.drawPath(s.path, inner);
    }
    final guide = Paint()
      ..color = ink.withValues(alpha: .48)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final trace = Paint()
      ..color = const Color(0xff37bdc1)
      ..strokeWidth = 19
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final metric = stroke.path.computeMetrics().single;
      for (var d = 0.0; d < stroke.length; d += 13) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + 4, stroke.length)), guide);
      }
      double covered = state.complete || i < state.stroke
          ? 1
          : i == state.stroke
              ? state.sample / (stroke.samples.length - 1)
              : 0;
      if (demonstration != null && i == state.stroke) covered = demonstration!;
      if (covered > 0) {
        canvas.drawPath(metric.extractPath(0, stroke.length * covered), trace);
      }
      if (!state.complete && i >= state.stroke) {
        final active = i == state.stroke;
        final start =
            active ? stroke.samples[state.sample] : stroke.samples.first;
        // A and B have strokes sharing a start. Never let a future number
        // cover the active yellow start marker.
        if (!active &&
            (start - strokes[state.stroke].samples[state.sample]).distance <
                28) {
          continue;
        }
        canvas.drawCircle(
            start,
            active ? 13 : 10,
            Paint()
              ..color =
                  active ? const Color(0xffffd34d) : const Color(0xffe3eaf4));
        final number = TextPainter(
            text: TextSpan(
                text: '${i + 1}',
                style: TextStyle(
                    color: ink,
                    fontSize: active ? 15 : 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'TracingNaskh')),
            textDirection: TextDirection.ltr)
          ..layout();
        number.paint(
            canvas, start - Offset(number.width / 2, number.height / 2));
        if (active && stroke.length > 30) {
          final at = math.min(
              stroke.length - 5, math.max(20.0, stroke.length * covered + 30));
          final tangent = metric.getTangentForOffset(at)!;
          final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
          final p = tangent.position;
          final arrow = Path()
            ..moveTo(p.dx - 8 * math.cos(angle - .65),
                p.dy - 8 * math.sin(angle - .65))
            ..lineTo(p.dx, p.dy)
            ..lineTo(p.dx - 8 * math.cos(angle + .65),
                p.dy - 8 * math.sin(angle + .65));
          canvas.drawPath(
              arrow,
              Paint()
                ..color = ink
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke);
        }
        if (active && demonstration != null) {
          canvas.drawCircle(
              metric.getTangentForOffset(stroke.length * covered)!.position,
              11,
              Paint()..color = const Color(0xfffa6680));
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TracingPainter old) => true;
}
