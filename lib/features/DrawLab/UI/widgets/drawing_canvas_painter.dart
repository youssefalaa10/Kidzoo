import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/drawlab_models.dart';

class DrawingCanvasPainter extends CustomPainter {
  DrawingCanvasPainter({
    required this.state,
    required this.canvasSize,
    required this.gridSize,
  });

  final DrawingState state;
  final Size canvasSize;
  final double gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    _drawBackground(canvas, size);

    // Draw grid if enabled
    if (state.isGridVisible) {
      _drawGrid(canvas, size);
    }

    // Draw shapes
    for (final shape in state.shapes) {
      _drawShape(canvas, shape);
    }

    // Draw strokes
    for (final stroke in state.strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw texts
    for (final text in state.texts) {
      _drawText(canvas, text);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = stroke.blendMode;

    // Apply brush shape
    switch (state.brushShape) {
      case BrushShape.round:
        paint.strokeCap = StrokeCap.round;
        break;
      case BrushShape.square:
        paint.strokeCap = StrokeCap.square;
        break;
      case BrushShape.calligraphy:
        // For calligraphy, we'll use a custom path
        _drawCalligraphyStroke(canvas, stroke);
        return;
    }

    // Draw the stroke
    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawCalligraphyStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..blendMode = stroke.blendMode;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final start = stroke.points[i];
      final end = stroke.points[i + 1];

      // Calculate angle for calligraphy effect
      final angle = (end - start).direction;
      final width =
          stroke.strokeWidth * (1.0 + (angle.abs() / (3.14159 / 2)) * 0.5);

      // Draw oval at each point for calligraphy effect
      final rect = Rect.fromCenter(
        center: start,
        width: width,
        height: stroke.strokeWidth,
      );

      canvas.drawOval(rect, paint);
    }
  }

  void _drawShape(Canvas canvas, DrawingShape shape) {
    final paint = Paint()
      ..color = shape.color.withOpacity(shape.opacity)
      ..strokeWidth = shape.strokeWidth
      ..style = shape.isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    if (shape.isFilled && shape.fillColor != null) {
      final fillPaint = Paint()
        ..color = shape.fillColor!.withOpacity(shape.opacity)
        ..style = PaintingStyle.fill;

      _drawShapePath(canvas, shape, fillPaint);
    }

    _drawShapePath(canvas, shape, paint);
  }

  void _drawShapePath(Canvas canvas, DrawingShape shape, Paint paint) {
    final rect = Rect.fromPoints(shape.startPoint, shape.endPoint);

    switch (shape.type) {
      case ShapeType.line:
        canvas.drawLine(shape.startPoint, shape.endPoint, paint);
        break;
      case ShapeType.rectangle:
        canvas.drawRect(rect, paint);
        break;
      case ShapeType.circle:
        canvas.drawOval(rect, paint);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, shape, paint);
        break;
      case ShapeType.arrow:
        _drawArrow(canvas, shape, paint);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, DrawingShape shape, Paint paint) {
    final path = Path();
    final center = Offset(
      (shape.startPoint.dx + shape.endPoint.dx) / 2,
      (shape.startPoint.dy + shape.endPoint.dy) / 2,
    );

    // final width = (shape.endPoint.dx - shape.startPoint.dx).abs();
    // final height = (shape.endPoint.dy - shape.startPoint.dy).abs();

    path.moveTo(center.dx, shape.startPoint.dy);
    path.lineTo(shape.startPoint.dx, shape.endPoint.dy);
    path.lineTo(shape.endPoint.dx, shape.endPoint.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, DrawingShape shape, Paint paint) {
    final direction = (shape.endPoint - shape.startPoint).direction;
    final length = (shape.endPoint - shape.startPoint).distance;
    final arrowLength = length * 0.2;
    final arrowAngle = 0.5; // 30 degrees

    // Draw main line
    canvas.drawLine(shape.startPoint, shape.endPoint, paint);

    // Draw arrow head
    final arrow1 = Offset(
      shape.endPoint.dx - arrowLength * math.cos(direction - arrowAngle),
      shape.endPoint.dy - arrowLength * math.sin(direction - arrowAngle),
    );

    final arrow2 = Offset(
      shape.endPoint.dx - arrowLength * math.cos(direction + arrowAngle),
      shape.endPoint.dy - arrowLength * math.sin(direction + arrowAngle),
    );

    canvas.drawLine(shape.endPoint, arrow1, paint);
    canvas.drawLine(shape.endPoint, arrow2, paint);
  }

  void _drawText(Canvas canvas, DrawingText text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          color: text.color,
          fontSize: text.fontSize,
          fontWeight: text.fontWeight,
          fontStyle: text.fontStyle,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, text.position);
  }

  @override
  bool shouldRepaint(DrawingCanvasPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.canvasSize != canvasSize ||
        oldDelegate.gridSize != gridSize;
  }
}

/// Helper class for creating custom brush effects
class BrushEffect {
  static Path createBrushPath(
      List<Offset> points, double strokeWidth, BrushShape shape) {
    final path = Path();

    if (points.isEmpty) return path;

    switch (shape) {
      case BrushShape.round:
        return _createRoundPath(points, strokeWidth);
      case BrushShape.square:
        return _createSquarePath(points, strokeWidth);
      case BrushShape.calligraphy:
        return _createCalligraphyPath(points, strokeWidth);
    }
  }

  static Path _createRoundPath(List<Offset> points, double strokeWidth) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  static Path _createSquarePath(List<Offset> points, double strokeWidth) {
    final path = Path();
    if (points.isEmpty) return path;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final rect = Rect.fromPoints(start, end);
      path.addRect(rect);
    }
    return path;
  }

  static Path _createCalligraphyPath(List<Offset> points, double strokeWidth) {
    final path = Path();
    if (points.length < 2) return path;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final direction = (end - start).direction;
      final width =
          strokeWidth * (1.0 + (direction.abs() / (3.14159 / 2)) * 0.5);

      final rect = Rect.fromCenter(
        center: start,
        width: width,
        height: strokeWidth,
      );
      path.addOval(rect);
    }
    return path;
  }
}
