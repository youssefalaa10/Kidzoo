import 'package:flutter/material.dart';

import '../../data/models/dots_and_boxes_models.dart';
import '../../data/models/game_state_model.dart';

class GameBoardPainter extends CustomPainter {
  GameBoardPainter({
    required this.state,
    required this.cellSize,
    required this.dotRadius,
    this.hoveredLine,
    this.animationValue = 1.0,
  });

  final DotsAndBoxesState state;
  final double cellSize;
  final double dotRadius;
  final Line? hoveredLine;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoxes(canvas);
    _drawLines(canvas);
    _drawHoveredLine(canvas);
    _drawDots(canvas);
  }

  void _drawDots(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final dotsPerSide = state.dotsPerSide;

    for (int row = 0; row < dotsPerSide; row++) {
      for (int col = 0; col < dotsPerSide; col++) {
        final x = col * cellSize;
        final y = row * cellSize;
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  void _drawLines(Canvas canvas) {
    final lineWidth = cellSize * 0.08;

    for (final line in state.lines.values) {
      final paint = Paint()
        ..color = line.ownedBy?.color ?? Colors.grey
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final startX = line.start.col * cellSize;
      final startY = line.start.row * cellSize;
      final endX = line.end.col * cellSize;
      final endY = line.end.row * cellSize;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  void _drawHoveredLine(Canvas canvas) {
    if (hoveredLine == null) return;
    if (state.isLineDrawn(hoveredLine!)) return;

    final paint = Paint()
      ..color = state.currentPlayer.color.withOpacity(0.15) // Reduced from 0.3
      ..strokeWidth = cellSize * 0.06 // Thinner line
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startX = hoveredLine!.start.col * cellSize;
    final startY = hoveredLine!.start.row * cellSize;
    final endX = hoveredLine!.end.col * cellSize;
    final endY = hoveredLine!.end.row * cellSize;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(endX, endY),
      paint,
    );
  }

  void _drawBoxes(Canvas canvas) {
    for (final box in state.boxes) {
      if (box.ownedBy != null) {
        final x = box.topLeft.col * cellSize;
        final y = box.topLeft.row * cellSize;

        // Check if this box was just completed
        final isNewlyCompleted = state.lastCompletedBoxes.any(
          (b) =>
              b.topLeft.row == box.topLeft.row &&
              b.topLeft.col == box.topLeft.col,
        );

        // Smoother, subtler animation
        final scale = isNewlyCompleted ? (0.95 + 0.05 * animationValue) : 1.0;
        final opacity = isNewlyCompleted
            ? (0.6 + 0.4 * animationValue)
            : 0.85; // Reduced base opacity

        final paint = Paint()
          ..color = box.ownedBy!.lightColor.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        // Draw filled box with scale animation
        canvas.save();
        canvas.translate(x + cellSize / 2, y + cellSize / 2);
        canvas.scale(scale);
        canvas.translate(-(cellSize / 2), -(cellSize / 2));

        canvas.drawRect(
          Rect.fromLTWH(0, 0, cellSize, cellSize),
          paint,
        );

        canvas.restore();

        // Draw player indicator (circle or square) in the center
        final centerX = x + cellSize / 2;
        final centerY = y + cellSize / 2;
        final indicatorSize = cellSize * 0.15 * scale;

        final indicatorPaint = Paint()
          ..color = box.ownedBy!.color.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        if (box.ownedBy == Player.player1) {
          // Draw circle for player 1
          canvas.drawCircle(
            Offset(centerX, centerY),
            indicatorSize,
            indicatorPaint,
          );
        } else {
          // Draw square for player 2
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(centerX, centerY),
              width: indicatorSize * 2,
              height: indicatorSize * 2,
            ),
            indicatorPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(GameBoardPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.hoveredLine != hoveredLine ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.animationValue != animationValue;
  }
}
