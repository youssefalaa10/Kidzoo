import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';

/// The shapes a scene can be furnished with.
///
/// Referenced from content by name, so an author lays out a jungle floor
/// without touching Dart. Each one is drawn rather than loaded, which is a
/// **stand-in**: [SceneProp.image] is the intended path and takes priority
/// wherever it is set, so replacing a drawn shape with real art is a one-line
/// content edit and no code change at all.
enum ScenePropShape {
  leaf,
  frond,
  bush,
  rock,
  grass,
  log,
  flower,

  // Built furniture. Added for the second Adventure and named for what they
  // are rather than where they came from: a crate is a crate in a shop, a
  // workshop, a harbour and a cargo bay. An enum of one Adventure's scenery
  // would have to be extended again for every Adventure after it, which is the
  // shape of a mechanic that is not really reusable.
  crate,
  basket,
  awning,
  barrel,
  sign,

  /// A soft band across the bottom of the scene, so objects have a floor to
  /// sit on instead of hanging in the middle of a photograph.
  ground,
}

/// How a movable cover gets out of the child's way.
enum CoverMove { slideLeft, slideRight, slideUp, slideDown, lift }

/// One thing standing in the scene.
@immutable
class SceneProp {
  const SceneProp({
    required this.position,
    this.shape,
    this.image,
    this.scale = 1.0,
    this.turns = 0,
    this.flip = false,
    this.id,
    this.move,
    this.offsetFromClue,
  });

  /// Normalized 0..1 within the scene box, like every other authored position
  /// in this engine, so one layout works on a phone, a tablet and in landscape.
  ///
  /// Ignored when [offsetFromClue] is set.
  final Offset position;

  /// Where a cover sits **relative to the clue**, in multiples of the clue's
  /// own size.
  ///
  /// Covers cannot use [position]. Scene percentages are a fraction of the box
  /// per axis, while every object is sized from the box's *short* side — so on
  /// a wide landscape board two things a few percent apart drift far apart in
  /// pixels, and a frond authored to lie across the page on a phone sits well
  /// clear of it in landscape. Anchoring to the clue makes the overlap the
  /// author drew the same overlap on every screen, which matters here because
  /// that overlap is the entire mechanic.
  final Offset? offsetFromClue;

  /// Drawn when [image] is null.
  final ScenePropShape? shape;

  /// Real art. Wins over [shape] whenever it is present.
  final String? image;

  final double scale;

  /// Rotation in turns. Small values only — a leaf lying at a slight angle
  /// reads as dropped; a leaf at forty-five degrees reads as a mistake.
  final double turns;

  final bool flip;

  /// Set only on a cover, which the child can move.
  final String? id;
  final CoverMove? move;

  bool get isMovable => move != null;
}

/// Renders a prop as real art when it has any, and as a drawn shape otherwise.
class ScenePropView extends StatelessWidget {
  const ScenePropView({
    required this.prop,
    required this.size,
    required this.accent,
    super.key,
  });

  final SceneProp prop;
  final double size;

  /// The Adventure's colour. Shapes are nudged toward it so a jungle prop and
  /// a market prop are recognisably from the same scene as everything else in
  /// their Adventure, without either of them turning purple.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final String? image = prop.image;
    final Widget body = image != null
        ? Image.asset(image, width: size, height: size, fit: BoxFit.contain)
        : CustomPaint(
            size: Size(size, size),
            painter: ScenePropPainter(
              shape: prop.shape ?? ScenePropShape.bush,
              accent: accent,
            ),
          );

    return IgnorePointer(
      ignoring: !prop.isMovable,
      child: Transform.flip(
        flipX: prop.flip,
        child: Transform.rotate(angle: prop.turns * 2 * pi, child: body),
      ),
    );
  }
}

/// Draws a scene prop into a square box.
///
/// Flat shapes with one darker accent each, to sit beside the app's existing
/// illustration rather than compete with it. Everything is expressed as a
/// fraction of the box so a prop is crisp at any size.
class ScenePropPainter extends CustomPainter {
  const ScenePropPainter({required this.shape, required this.accent});

  final ScenePropShape shape;
  final Color accent;

  /// Natural colour first, then pulled a quarter of the way toward the
  /// Adventure's accent. A rock stays grey and a log stays brown; they just
  /// belong to this scene rather than to no scene in particular.
  Color _tint(Color natural, {double amount = 0.25}) =>
      Color.lerp(natural, accent, amount) ?? natural;

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case ScenePropShape.leaf:
        _paintLeaf(canvas, size);
      case ScenePropShape.frond:
        _paintFrond(canvas, size);
      case ScenePropShape.bush:
        _paintBush(canvas, size);
      case ScenePropShape.rock:
        _paintRock(canvas, size);
      case ScenePropShape.grass:
        _paintGrass(canvas, size);
      case ScenePropShape.log:
        _paintLog(canvas, size);
      case ScenePropShape.flower:
        _paintFlower(canvas, size);
      case ScenePropShape.crate:
        _paintCrate(canvas, size);
      case ScenePropShape.basket:
        _paintBasket(canvas, size);
      case ScenePropShape.awning:
        _paintAwning(canvas, size);
      case ScenePropShape.barrel:
        _paintBarrel(canvas, size);
      case ScenePropShape.sign:
        _paintSign(canvas, size);
      case ScenePropShape.ground:
        _paintGround(canvas, size);
    }
  }

  void _paintLeaf(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path blade = Path()
      ..moveTo(w * 0.5, h * 0.06)
      ..cubicTo(w * 0.95, h * 0.3, w * 0.9, h * 0.78, w * 0.5, h * 0.96)
      ..cubicTo(w * 0.1, h * 0.78, w * 0.05, h * 0.3, w * 0.5, h * 0.06)
      ..close();
    canvas.drawPath(blade, Paint()..color = _tint(KidUi.foliage));

    // One midrib. Two would be fussy at the size these are drawn.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.12)
        ..lineTo(w * 0.5, h * 0.92),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round
        ..color = _tint(KidUi.foliageDeep).withValues(alpha: 0.65),
    );
  }

  void _paintFrond(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint leaflet = Paint()..color = _tint(KidUi.foliage);
    final Paint shade = Paint()..color = _tint(KidUi.foliageDeep);

    // Six pairs of leaflets, shortening toward the tip.
    for (int i = 0; i < 6; i++) {
      final double t = i / 5;
      final double y = h * (0.18 + t * 0.66);
      final double reach = w * (0.46 - t * 0.28);
      final double thickness = h * (0.1 - t * 0.04);
      for (final int side in <int>[-1, 1]) {
        final Path lobe = Path()
          ..moveTo(w * 0.5, y)
          ..quadraticBezierTo(
            w * 0.5 + side * reach * 0.7,
            y - thickness,
            w * 0.5 + side * reach,
            y + thickness * 0.35,
          )
          ..quadraticBezierTo(
            w * 0.5 + side * reach * 0.6,
            y + thickness * 0.9,
            w * 0.5,
            y,
          )
          ..close();
        canvas.drawPath(lobe, side == -1 ? shade : leaflet);
      }
    }

    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.94)
        ..lineTo(w * 0.5, h * 0.14),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round
        ..color = _tint(KidUi.foliageDeep),
    );
  }

  void _paintBush(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint back = Paint()..color = _tint(KidUi.foliageDeep);
    final Paint front = Paint()..color = _tint(KidUi.foliage);

    canvas.drawCircle(Offset(w * 0.3, h * 0.6), w * 0.26, back);
    canvas.drawCircle(Offset(w * 0.72, h * 0.62), w * 0.24, back);
    canvas.drawCircle(Offset(w * 0.5, h * 0.46), w * 0.3, front);
    canvas.drawOval(
      Rect.fromLTRB(w * 0.06, h * 0.62, w * 0.94, h * 0.9),
      front,
    );
  }

  void _paintRock(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path body = Path()
      ..moveTo(w * 0.08, h * 0.84)
      ..lineTo(w * 0.26, h * 0.42)
      ..lineTo(w * 0.56, h * 0.28)
      ..lineTo(w * 0.86, h * 0.52)
      ..lineTo(w * 0.94, h * 0.84)
      ..close();
    canvas.drawPath(body, Paint()..color = _tint(KidUi.stone, amount: 0.12));

    // A lighter top facet, which is the whole difference between a rock and a
    // grey blob.
    final Path facet = Path()
      ..moveTo(w * 0.26, h * 0.42)
      ..lineTo(w * 0.56, h * 0.28)
      ..lineTo(w * 0.7, h * 0.46)
      ..lineTo(w * 0.4, h * 0.56)
      ..close();
    canvas.drawPath(
      facet,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _paintGrass(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    const List<double> roots = <double>[0.18, 0.34, 0.5, 0.66, 0.82];
    for (int i = 0; i < roots.length; i++) {
      final double lean = (i - 2) * 0.09;
      final double top = h * (0.28 + (i.isEven ? 0.0 : 0.12));
      canvas.drawPath(
        Path()
          ..moveTo(w * roots[i], h * 0.92)
          ..quadraticBezierTo(
            w * (roots[i] + lean * 0.6),
            (h * 0.92 + top) / 2,
            w * (roots[i] + lean),
            top,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.055
          ..strokeCap = StrokeCap.round
          ..color = i.isEven ? _tint(KidUi.foliage) : _tint(KidUi.foliageDeep),
      );
    }
  }

  void _paintLog(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final RRect barrel = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.06, h * 0.36, w * 0.9, h * 0.74),
      Radius.circular(h * 0.19),
    );
    canvas.drawRRect(barrel, Paint()..color = _tint(KidUi.bark, amount: 0.15));

    // The cut end, so it reads as a log rather than a sausage.
    final Rect end = Rect.fromLTWH(w * 0.72, h * 0.36, w * 0.22, h * 0.38);
    canvas.drawOval(
      end,
      Paint()..color = _tint(KidUi.barkCut, amount: 0.1),
    );
    canvas.drawOval(
      end.deflate(w * 0.05),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018
        ..color = _tint(KidUi.bark).withValues(alpha: 0.6),
    );
  }

  void _paintFlower(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset heart = Offset(w * 0.5, h * 0.42);
    final Paint petal = Paint()..color = _tint(KidUi.blossom, amount: 0.12);

    for (int i = 0; i < 5; i++) {
      final double angle = i * 2 * pi / 5 - pi / 2;
      canvas.drawOval(
        Rect.fromCenter(
          center: heart + Offset(cos(angle), sin(angle)) * w * 0.2,
          width: w * 0.26,
          height: w * 0.26,
        ),
        petal,
      );
    }
    canvas.drawCircle(heart, w * 0.12, Paint()..color = KidUi.hint);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.56)
        ..lineTo(w * 0.5, h * 0.94),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round
        ..color = _tint(KidUi.foliageDeep),
    );
  }

  void _paintGround(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // A soft mound rather than a straight edge: a hard horizontal line across
    // a painted background looks like a rendering fault.
    final Path band = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.42)
      ..quadraticBezierTo(w * 0.25, h * 0.2, w * 0.52, h * 0.36)
      ..quadraticBezierTo(w * 0.8, h * 0.52, w, h * 0.3)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      band,
      Paint()..color = _tint(KidUi.foliageDeep, amount: 0.3).withValues(alpha: 0.5),
    );
  }

  void _paintCrate(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final RRect box = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.1, h * 0.34, w * 0.9, h * 0.88),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(box, Paint()..color = _tint(KidUi.barkCut, amount: 0.12));

    // Slats. Three, because two reads as a box and four as a fence.
    final Paint slat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..color = _tint(KidUi.bark).withValues(alpha: 0.75);
    for (final double t in <double>[0.48, 0.62, 0.76]) {
      canvas.drawLine(Offset(w * 0.12, h * t), Offset(w * 0.88, h * t), slat);
    }
    canvas.drawRRect(
      box,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..color = _tint(KidUi.bark),
    );
  }

  void _paintBasket(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path bowl = Path()
      ..moveTo(w * 0.14, h * 0.46)
      ..lineTo(w * 0.86, h * 0.46)
      ..quadraticBezierTo(w * 0.78, h * 0.92, w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.22, h * 0.92, w * 0.14, h * 0.46)
      ..close();
    canvas.drawPath(bowl, Paint()..color = _tint(KidUi.barkCut, amount: 0.14));

    // The weave, as two crossing sets rather than a texture: at the size these
    // are drawn, anything finer turns into noise.
    final Paint weave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..color = _tint(KidUi.bark).withValues(alpha: 0.6);
    for (final double t in <double>[0.58, 0.72]) {
      canvas.drawLine(Offset(w * 0.18, h * t), Offset(w * 0.82, h * t), weave);
    }
    canvas.drawArc(
      Rect.fromLTRB(w * 0.24, h * 0.16, w * 0.76, h * 0.62),
      pi,
      pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..color = _tint(KidUi.bark),
    );
  }

  void _paintAwning(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path canopy = Path()
      ..moveTo(w * 0.04, h * 0.3)
      ..lineTo(w * 0.96, h * 0.3)
      ..lineTo(w * 0.9, h * 0.62)
      ..lineTo(w * 0.1, h * 0.62)
      ..close();
    canvas.drawPath(canopy, Paint()..color = accent.withValues(alpha: 0.85));

    // Scalloped hem, in alternating stripes. One stripe colour plus the accent
    // is enough to say "stall" without inventing a second palette.
    final Paint stripe = Paint()..color = Colors.white.withValues(alpha: 0.85);
    const int bands = 5;
    for (int i = 0; i < bands; i += 2) {
      final double left = w * (0.1 + 0.8 * i / bands);
      final double right = w * (0.1 + 0.8 * (i + 1) / bands);
      canvas.drawPath(
        Path()
          ..moveTo(left, h * 0.3)
          ..lineTo(right, h * 0.3)
          ..lineTo(right - w * 0.02, h * 0.62)
          ..lineTo(left + w * 0.02, h * 0.62)
          ..close(),
        stripe,
      );
    }
    for (int i = 0; i < bands; i++) {
      final double centre = w * (0.1 + 0.8 * (i + 0.5) / bands);
      canvas.drawCircle(
        Offset(centre, h * 0.62),
        w * 0.07,
        Paint()
          ..color = i.isEven
              ? Colors.white.withValues(alpha: 0.85)
              : accent.withValues(alpha: 0.85),
      );
    }
  }

  void _paintBarrel(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path body = Path()
      ..moveTo(w * 0.24, h * 0.26)
      ..quadraticBezierTo(w * 0.08, h * 0.56, w * 0.24, h * 0.88)
      ..lineTo(w * 0.76, h * 0.88)
      ..quadraticBezierTo(w * 0.92, h * 0.56, w * 0.76, h * 0.26)
      ..close();
    canvas.drawPath(body, Paint()..color = _tint(KidUi.bark, amount: 0.12));

    final Paint hoop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..color = _tint(KidUi.stone, amount: 0.1);
    for (final double t in <double>[0.42, 0.72]) {
      canvas.drawLine(Offset(w * 0.12, h * t), Offset(w * 0.88, h * t), hoop);
    }
    canvas.drawOval(
      Rect.fromLTRB(w * 0.24, h * 0.16, w * 0.76, h * 0.36),
      Paint()..color = _tint(KidUi.barkCut, amount: 0.1),
    );
  }

  void _paintSign(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.52),
      Offset(w * 0.5, h * 0.96),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round
        ..color = _tint(KidUi.bark),
    );
    final RRect board = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.1, h * 0.14, w * 0.9, h * 0.56),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(board, Paint()..color = _tint(KidUi.barkCut, amount: 0.2));
    canvas.drawRRect(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(ScenePropPainter old) =>
      old.shape != shape || old.accent != accent;
}
