import 'dart:math';
import 'package:flutter/material.dart';
import 'balloon_cubit.dart';

/// Resolution independent illustrations; no textures or per-frame asset decoding.
class BalloonPainter extends CustomPainter {
  const BalloonPainter({required this.color, this.face = true});
  final Color color;
  final bool face;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 145);
    final body = const Rect.fromLTWH(5, 3, 90, 103);
    final string = Path()
      ..moveTo(50, 112)
      ..cubicTo(72, 124, 30, 129, 48, 145);
    canvas.drawPath(
        string,
        Paint()
          ..color = const Color(0xFF769D94)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    canvas.drawOval(body.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: .08));
    canvas.drawOval(
        body,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.45, -.55),
            radius: 1.25,
            colors: [
              Color.lerp(color, Colors.white, .32)!,
              color,
              Color.lerp(color, const Color(0xFF653D87), .22)!
            ],
          ).createShader(body));
    canvas.drawOval(
        body,
        Paint()
          ..color = Colors.white.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6);
    canvas.save();
    canvas.translate(26, 27);
    canvas.rotate(.4);
    canvas.drawOval(const Rect.fromLTWH(-6, -13, 12, 27),
        Paint()..color = Colors.white.withValues(alpha: .48));
    canvas.restore();
    canvas.drawCircle(const Offset(36, 12), 3,
        Paint()..color = Colors.white.withValues(alpha: .65));
    canvas.drawPath(
        Path()
          ..moveTo(50, 103)
          ..lineTo(43, 114)
          ..quadraticBezierTo(50, 117, 57, 114)
          ..close(),
        Paint()..color = color);
    if (face) {
      for (final x in [35.0, 64.0]) {
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 52), width: 19, height: 24),
            Paint()..color = Colors.white);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x + 2, 54), width: 8, height: 12),
            Paint()..color = const Color(0xFF3B3350));
        canvas.drawCircle(
            Offset(x + 3, 51), 2.2, Paint()..color = Colors.white);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(x == 35 ? 22 : 78, 69), width: 13, height: 7),
            Paint()..color = const Color(0xFFFFD3CA).withValues(alpha: .6));
      }
      canvas.drawPath(
          Path()
            ..moveTo(36, 73)
            ..quadraticBezierTo(50, 88, 65, 72),
          Paint()
            ..color = const Color(0xFF65435E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BalloonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.face != face;
}

class BalloonParkPainter extends CustomPainter {
  const BalloonParkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sky = Offset.zero & size;
    canvas.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC6F1FA), Color(0xFFE9FCED)],
          ).createShader(sky));
    // Sunny, round shapes and a quiet central sky keep the moving targets legible.
    canvas.drawCircle(
        Offset(w * .82, h * .12), 35, Paint()..color = const Color(0xFFFFE695));
    for (final cloud in [
      Offset(w * .18, h * .18),
      Offset(w * .62, h * .28),
      Offset(w * .94, h * .34)
    ]) {
      final p = Paint()..color = Colors.white.withValues(alpha: .8);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: cloud, width: 115, height: 27),
              const Radius.circular(20)),
          p);
      canvas.drawCircle(cloud.translate(-20, -15), 22, p);
      canvas.drawCircle(cloud.translate(12, -18), 28, p);
    }
    final hill = Path()
      ..moveTo(0, h * .65)
      ..quadraticBezierTo(w * .24, h * .46, w * .56, h * .65)
      ..quadraticBezierTo(w * .84, h * .51, w, h * .61)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFFBADD88));
    final front = Path()
      ..moveTo(0, h * .73)
      ..quadraticBezierTo(w * .5, h * .57, w, h * .74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF92C96A));
    canvas.drawOval(Rect.fromLTWH(-w * .15, h * .81, w * 1.3, h * .45),
        Paint()..color = const Color(0xFF65CFD9));
    canvas.drawOval(Rect.fromLTWH(-w * .15, h * .83, w * 1.3, h * .45),
        Paint()..color = const Color(0xFF82DEE2));
    // Trees frame the play area rather than competing with the balloons.
    for (final x in [-8.0, w + 8]) {
      final trunk = Path()
        ..moveTo(x - 17, h * .70)
        ..lineTo(x - 8, h * .27)
        ..lineTo(x + 7, h * .27)
        ..lineTo(x + 25, h * .70)
        ..quadraticBezierTo(x, h * .72, x - 17, h * .70);
      canvas.drawPath(trunk, Paint()..color = const Color(0xFFBD8A63));
      for (final o in [
        Offset(x - 30, h * .27),
        Offset(x + 30, h * .24),
        Offset(x, h * .19)
      ]) {
        canvas.drawCircle(
            o, w < 500 ? 65 : 100, Paint()..color = const Color(0xFF65AF78));
        canvas.drawCircle(o.translate(-10, -9), w < 500 ? 47 : 78,
            Paint()..color = const Color(0xFF82C687));
      }
    }
    // Bunting across the canopy.
    final rope = Path()
      ..moveTo(w * .1, 0)
      ..quadraticBezierTo(w * .5, h * .15, w * .9, 0);
    canvas.drawPath(
        rope,
        Paint()
          ..color = const Color(0xFF6C9B89)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 9; i++) {
      final t = (i + 1) / 10,
          x = w * (.1 + .8 * t),
          y = 2 * (1 - t) * t * h * .15;
      canvas.drawPath(
          Path()
            ..moveTo(x - 10, y)
            ..lineTo(x + 10, y + 1)
            ..lineTo(x + 1, y + 23)
            ..close(),
          Paint()..color = balloonColors[i % 6].withValues(alpha: .8));
    }
    // Tiny shore flowers and water ripples.
    for (var i = 0; i < 13; i++) {
      final x = w * (i + .4) / 13, y = h * (.77 + (i % 3) * .009);
      canvas.drawCircle(Offset(x, y), 3,
          Paint()..color = i.isEven ? const Color(0xFFFFF4C4) : Colors.white);
      canvas.drawLine(
          Offset(x - 10, h * .92 + (i % 3) * 7),
          Offset(x + 13, h * .92 + (i % 3) * 7),
          Paint()
            ..color = Colors.white.withValues(alpha: .3)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
    _duck(canvas, Offset(w * .18, h * .9), .65);
    _duck(canvas, Offset(w * .83, h * .94), .48);
  }

  void _duck(Canvas c, Offset p, double scale) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(scale);
    final yellow = Paint()..color = const Color(0xFFFFDA5B);
    c.drawOval(const Rect.fromLTWH(-28, -8, 56, 29), yellow);
    c.drawCircle(const Offset(13, -17), 17, yellow);
    c.drawOval(const Rect.fromLTWH(23, -17, 20, 8),
        Paint()..color = const Color(0xFFEF9861));
    c.drawCircle(
        const Offset(19, -22), 2.7, Paint()..color = const Color(0xFF3B3350));
    c.drawOval(const Rect.fromLTWH(-17, -1, 27, 13),
        Paint()..color = const Color(0xFFF2C546));
    c.restore();
  }

  @override
  bool shouldRepaint(BalloonParkPainter oldDelegate) => false;
}

class BalloonBurstPainter extends CustomPainter {
  const BalloonBurstPainter(this.bursts, this.balloonWidth);
  final List<BalloonBurst> bursts;
  final double balloonWidth;
  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      final t = (burst.age / .55).clamp(0.0, 1.0);
      final center = Offset(
          burst.x * size.width,
          size.height +
              12 -
              burst.y * (size.height + balloonWidth * 1.6) +
              balloonWidth * .5);
      final alpha = 1 - t;
      canvas.drawCircle(
          center,
          12 + t * 48,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 * (1 - t));
      for (var i = 0; i < 10; i++) {
        final angle = i * pi / 5 + burst.id, distance = 12 + t * 65;
        final point = center +
            Offset(cos(angle) * distance, sin(angle) * distance + t * t * 35);
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + t * 3);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero,
                    width: 7 * (1 - t * .4),
                    height: 11 * (1 - t * .4)),
                const Radius.circular(2)),
            Paint()
              ..color = balloonColors[(i + burst.color) % 6]
                  .withValues(alpha: alpha));
        canvas.restore();
      }
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final angle = -pi / 2 + i * pi / 5,
            r = (i.isEven ? 18.0 : 8.0) * (1 + t * .5);
        final p = center + Offset(cos(angle) * r, sin(angle) * r - t * 22);
        if (i == 0) {
          star.moveTo(p.dx, p.dy);
        } else {
          star.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(star..close(),
          Paint()..color = const Color(0xFFFFD75C).withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(BalloonBurstPainter oldDelegate) => true;
}
