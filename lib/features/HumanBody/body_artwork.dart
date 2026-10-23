import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'body_parts.dart';

/// Original vector character. The tray and board draw the very same paths.
class BodyArtwork {
  BodyArtwork(this.canvas, {this.ghost = false});
  final Canvas canvas;
  final bool ghost;
  final Color skin = const Color(0xFFF9C898);
  final Color outline = const Color(0xFF4A3F60);
  final Color shirt = const Color(0xFFFF8B91);
  final Color trousers = const Color(0xFF77BEEB);

  void shape(Path path, Color color) {
    canvas.drawPath(
        path, Paint()..color = ghost ? const Color(0xFFF3F0F7) : color);
    final Paint stroke = Paint()
      ..color = ghost ? const Color(0xFFC8C0D6) : outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = ghost ? 2.2 : 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (!ghost) {
      canvas.drawPath(path, stroke);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 10) {
        canvas.drawPath(
            metric.extractPath(start, math.min(start + 5, metric.length)),
            stroke);
      }
    }
  }

  void oval(Rect rect, Color color) => shape(Path()..addOval(rect), color);
  void rounded(Rect rect, double radius, Color color) => shape(
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))),
      color);
  void line(Path path, {Color? color, double width = 3}) {
    if (ghost) return;
    canvas.drawPath(
        path,
        Paint()
          ..color = color ?? outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  void draw(BodyPartId id) {
    switch (id) {
      case BodyPartId.head:
        rounded(const Rect.fromLTWH(92, 39, 176, 174), 76, skin);
      case BodyPartId.hair:
        shape(
            Path()
              ..moveTo(92, 85)
              ..cubicTo(76, 35, 110, 12, 147, 24)
              ..cubicTo(170, 2, 211, 12, 224, 26)
              ..cubicTo(262, 23, 277, 51, 266, 84)
              ..lineTo(250, 61)
              ..quadraticBezierTo(214, 82, 191, 47)
              ..quadraticBezierTo(156, 80, 123, 56)
              ..lineTo(108, 83)
              ..close(),
            const Color(0xFF80533F));
        line(
            Path()
              ..moveTo(130, 36)
              ..quadraticBezierTo(160, 22, 176, 32),
            color: const Color(0xFFB9865F),
            width: 5);
      case BodyPartId.leftEye:
      case BodyPartId.rightEye:
        final double x = id == BodyPartId.leftEye ? 216 : 144;
        oval(Rect.fromCenter(center: Offset(x, 112), width: 31, height: 37),
            Colors.white);
        if (!ghost) {
          canvas.drawOval(
              Rect.fromCenter(center: Offset(x, 115), width: 17, height: 25),
              Paint()..color = outline);
          canvas.drawCircle(
              Offset(x - 4, 109), 4, Paint()..color = Colors.white);
        }
      case BodyPartId.nose:
        shape(
            Path()
              ..moveTo(177, 133)
              ..quadraticBezierTo(156, 156, 185, 153)
              ..quadraticBezierTo(197, 149, 185, 143),
            const Color(0xFFEDA875));
      case BodyPartId.mouth:
        shape(
            Path()
              ..moveTo(155, 169)
              ..quadraticBezierTo(180, 180, 205, 169)
              ..quadraticBezierTo(201, 198, 180, 195)
              ..quadraticBezierTo(159, 196, 155, 169)
              ..close(),
            const Color(0xFFBC4D69));
        if (!ghost) {
          shape(
              Path()
                ..moveTo(162, 173)
                ..quadraticBezierTo(180, 180, 198, 173)
                ..lineTo(194, 181)
                ..quadraticBezierTo(180, 185, 167, 180)
                ..close(),
              Colors.white);
        }
      case BodyPartId.leftEar:
      case BodyPartId.rightEar:
        final double x = id == BodyPartId.leftEar ? 275 : 85;
        oval(Rect.fromCenter(center: Offset(x, 123), width: 29, height: 45),
            skin);
        line(
            Path()
              ..moveTo(x - 3, 115)
              ..quadraticBezierTo(x + 9, 111, x + 3, 131),
            color: const Color(0xFFD79270));
      case BodyPartId.neck:
        rounded(const Rect.fromLTWH(158, 205, 44, 44), 15, skin);
      case BodyPartId.shoulders:
        shape(
            Path()
              ..moveTo(158, 243)
              ..quadraticBezierTo(180, 259, 202, 243)
              ..lineTo(232, 249)
              ..lineTo(257, 277)
              ..lineTo(234, 289)
              ..lineTo(126, 289)
              ..lineTo(103, 277)
              ..lineTo(128, 249)
              ..close(),
            shirt);
        line(
            Path()
              ..moveTo(158, 245)
              ..quadraticBezierTo(180, 268, 202, 245),
            color: const Color(0xFFDB657D));
      case BodyPartId.arms:
        for (final bool mirror in [false, true]) {
          canvas.save();
          if (mirror) {
            canvas.translate(360, 0);
            canvas.scale(-1, 1);
          }
          shape(
              Path()
                ..moveTo(108, 277)
                ..lineTo(127, 287)
                ..lineTo(69, 342)
                ..quadraticBezierTo(46, 347, 51, 326)
                ..close(),
              skin);
          canvas.restore();
        }
      case BodyPartId.hands:
        for (final double x in [43.0, 317.0]) {
          rounded(
              Rect.fromCenter(center: Offset(x, 352), width: 37, height: 43),
              15,
              skin);
        }
      case BodyPartId.fingers:
        for (final bool mirror in [false, true]) {
          canvas.save();
          if (mirror) {
            canvas.translate(360, 0);
            canvas.scale(-1, 1);
          }
          for (int finger = 0; finger < 4; finger++) {
            final double x = 18 + finger * 10;
            rounded(
                Rect.fromLTWH(x, 367, 10,
                    27 + (finger == 1 ? 10 : (finger == 2 ? 7 : 0))),
                5,
                skin);
          }
          rounded(const Rect.fromLTWH(52, 354, 12, 27), 6, skin);
          canvas.restore();
        }
      case BodyPartId.stomach:
        shape(
            Path()
              ..moveTo(126, 284)
              ..lineTo(234, 284)
              ..lineTo(241, 369)
              ..quadraticBezierTo(180, 382, 119, 369)
              ..close(),
            shirt);
        if (!ghost) {
          canvas.drawCircle(const Offset(180, 327), 21,
              Paint()..color = const Color(0xFFFFDC89));
          line(
              Path()
                ..moveTo(169, 328)
                ..quadraticBezierTo(180, 340, 191, 328),
              width: 2.5);
          canvas.drawCircle(
              const Offset(173, 321), 2, Paint()..color = outline);
          canvas.drawCircle(
              const Offset(187, 321), 2, Paint()..color = outline);
        }
      case BodyPartId.legs:
        for (final double x in [145.0, 215.0]) {
          rounded(Rect.fromLTWH(x - 23, 369, 46, 133), 18, skin);
          rounded(Rect.fromLTWH(x - 23, 369, 46, 64), 10, trousers);
          line(
              Path()
                ..moveTo(x - 16, 424)
                ..lineTo(x + 16, 424),
              color: const Color(0xFF3E93C3));
        }
      case BodyPartId.knees:
        for (final double x in [145.0, 215.0]) {
          oval(Rect.fromCenter(center: Offset(x, 460), width: 36, height: 29),
              skin);
          line(
              Path()
                ..moveTo(x - 9, 462)
                ..quadraticBezierTo(x, 455, x + 9, 462),
              color: const Color(0xFFD79270),
              width: 2);
        }
      case BodyPartId.feet:
        shape(
            Path()
              ..moveTo(123, 495)
              ..lineTo(165, 495)
              ..lineTo(162, 520)
              ..quadraticBezierTo(136, 536, 104, 526)
              ..quadraticBezierTo(97, 508, 123, 505)
              ..close(),
            skin);
        canvas.save();
        canvas.translate(360, 0);
        canvas.scale(-1, 1);
        shape(
            Path()
              ..moveTo(123, 495)
              ..lineTo(165, 495)
              ..lineTo(162, 520)
              ..quadraticBezierTo(136, 536, 104, 526)
              ..quadraticBezierTo(97, 508, 123, 505)
              ..close(),
            skin);
        canvas.restore();
      case BodyPartId.toes:
        for (final bool mirror in [false, true]) {
          canvas.save();
          if (mirror) {
            canvas.translate(360, 0);
            canvas.scale(-1, 1);
          }
          for (int toe = 0; toe < 5; toe++) {
            oval(
                Rect.fromLTWH(
                    100 + toe * 9, 529 - toe * 0.5, 12, 15 + toe * 0.7),
                skin);
          }
          canvas.restore();
        }
    }
  }
}

class BodyCharacterPainter extends CustomPainter {
  BodyCharacterPainter(
      {required this.placed,
      required this.stage,
      required this.viewport,
      this.highlight,
      this.lastPlaced,
      this.animation = 1,
      this.complete = false});
  final Set<BodyPartId> placed;
  final int stage;
  final BodyViewport viewport;
  final BodyPartId? highlight;
  final BodyPartId? lastPlaced;
  final double animation;
  final bool complete;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(viewport.origin.dx, viewport.origin.dy);
    canvas.scale(viewport.scale);
    canvas.drawOval(const Rect.fromLTWH(93, 550, 174, 9),
        Paint()..color = const Color(0xFFE0D8EE));
    final BodyArtwork solid = BodyArtwork(canvas);
    final BodyArtwork ghost = BodyArtwork(canvas, ghost: true);
    // Explicit depth order prevents a head or torso placed later from hiding
    // the facial features or knees that the child has already learned.
    const List<BodyPartId> depth = [
      BodyPartId.neck,
      BodyPartId.legs,
      BodyPartId.arms,
      BodyPartId.hands,
      BodyPartId.fingers,
      BodyPartId.shoulders,
      BodyPartId.stomach,
      BodyPartId.leftEar,
      BodyPartId.rightEar,
      BodyPartId.head,
      BodyPartId.hair,
      BodyPartId.leftEye,
      BodyPartId.rightEye,
      BodyPartId.nose,
      BodyPartId.mouth,
      BodyPartId.knees,
      BodyPartId.feet,
      BodyPartId.toes
    ];
    final bool headPresent = stage == 0 || placed.contains(BodyPartId.head);
    for (final BodyPartId id in depth) {
      final BodyPart part = const BodyParts().find(id);
      final bool visible =
          placed.contains(id) || (id == BodyPartId.head && stage == 0);
      // In stage two the face is carried by the head piece, never floating.
      if (part.stage == 0 && !headPresent) continue;
      canvas.save();
      if (id == lastPlaced && animation < 1) {
        final Offset center = part.artBounds.center;
        final double pulse = 1 + math.sin(animation * math.pi) * 0.12;
        canvas.translate(center.dx, center.dy);
        canvas.scale(pulse);
        canvas.translate(-center.dx, -center.dy);
      }
      (visible ? solid : ghost).draw(id);
      canvas.restore();
    }
    if (headPresent &&
        [
          BodyPartId.leftEye,
          BodyPartId.rightEye,
          BodyPartId.nose,
          BodyPartId.mouth
        ].every(placed.contains)) {
      for (final double x in [117.0, 243.0]) {
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 153), width: 24, height: 12),
            Paint()..color = const Color(0xFFFFA5A0).withValues(alpha: .6));
      }
    }
    if (highlight != null) {
      for (final Offset point in const BodyParts().find(highlight!).anchors) {
        canvas.drawCircle(
            point, 30, Paint()..color = KidUi.correct.withValues(alpha: .18));
        canvas.drawCircle(
            point,
            30,
            Paint()
              ..color = KidUi.correct
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
    }
    if (lastPlaced != null && animation < 1) {
      final Offset center = const BodyParts().find(lastPlaced!).anchors.first;
      for (int i = 0; i < 8; i++) {
        final double angle = i * math.pi / 4;
        final Offset position = center +
            Offset(math.cos(angle), math.sin(angle)) * (20 + animation * 57);
        canvas.drawCircle(position, 4 * (1 - animation),
            Paint()..color = KidUi.confettiColors[i % 5]);
      }
    }
    canvas.restore();
    if (complete && animation < 1) {
      for (int i = 0; i < 34; i++) {
        final double x = ((i * 67) % 100) / 100 * size.width;
        final double y = ((i * 31) % 100) / 100 * size.height * animation;
        canvas.drawCircle(
            Offset(x, y),
            3 + (i % 3).toDouble(),
            Paint()
              ..color =
                  KidUi.confettiColors[i % 5].withValues(alpha: 1 - animation));
      }
    }
  }

  @override
  bool shouldRepaint(BodyCharacterPainter old) => true;
}

class BodyPartIllustration extends StatelessWidget {
  const BodyPartIllustration({required this.part, super.key});
  final BodyPartId part;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BodyPiecePainter(part));
}

class _BodyPiecePainter extends CustomPainter {
  _BodyPiecePainter(this.id);
  final BodyPartId id;
  @override
  void paint(Canvas canvas, Size size) {
    // Paired pieces use a single representative at a readable tray size.
    final Rect bounds = switch (id) {
      BodyPartId.arms => const Rect.fromLTWH(45, 272, 86, 76),
      BodyPartId.hands => const Rect.fromLTWH(22, 328, 42, 48),
      BodyPartId.fingers => const Rect.fromLTWH(12, 350, 55, 62),
      BodyPartId.legs => const Rect.fromLTWH(119, 366, 52, 139),
      BodyPartId.knees => const Rect.fromLTWH(124, 442, 42, 35),
      BodyPartId.feet => const Rect.fromLTWH(97, 491, 72, 43),
      BodyPartId.toes => const Rect.fromLTWH(97, 526, 54, 25),
      _ => const BodyParts().find(id).artBounds,
    };
    final double scale = math.min(
        size.width / (bounds.width + 10), size.height / (bounds.height + 10));
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    canvas.clipRect(bounds.inflate(4));
    BodyArtwork(canvas).draw(id);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPiecePainter old) => id != old.id;
}
