import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/model/color_model.dart';

class ColorBall extends StatelessWidget {
  const ColorBall({
    required this.color,
    required this.onMatched,
    required this.onWrongMatch,
    required this.availableColors,
    super.key,
  });

  final ColorModel color;
  final void Function(ColorModel) onMatched;
  final VoidCallback onWrongMatch;
  final List<ColorModel> availableColors;

  @override
  Widget build(BuildContext context) {
    return Draggable<ColorModel>(
      data: color,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(color.colorValue),
            boxShadow: [
              BoxShadow(
                color: Color(color.colorValue).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _GlossyBallPainter(color.colorValue),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(color.colorValue).withValues(alpha: 0.3),
        ),
      ),
      onDragEnd: (details) {
        // The actual matching logic is handled by DragTarget in the container
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(color.colorValue),
          boxShadow: [
            BoxShadow(
              color: Color(color.colorValue).withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(-3, -3),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _GlossyBallPainter(color.colorValue),
        ),
      ),
    );
  }
}

class _GlossyBallPainter extends CustomPainter {
  _GlossyBallPainter(this.colorValue);

  final int colorValue;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw glossy highlight effect
    final highlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.3, size.height * 0.3),
        size.width * 0.4,
        [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.0),
        ],
      );

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.4,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
