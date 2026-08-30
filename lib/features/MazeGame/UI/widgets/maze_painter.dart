import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/maze_models.dart';
import '../../data/models/maze_state.dart';

class MazePainter extends CustomPainter {
  MazePainter({
    required this.state,
    required this.cellSize,
  });

  final MazeState state;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCells(canvas);
    _drawWalls(canvas);
    _drawPath(canvas);
    _drawStars(canvas);
    _drawStartEnd(canvas);
  }

  void _drawCells(Canvas canvas) {
    final paint = Paint()..color = Colors.white;

    for (int row = 0; row < state.gridSize; row++) {
      for (int col = 0; col < state.gridSize; col++) {
        final x = col * cellSize;
        final y = row * cellSize;

        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    for (int row = 0; row < state.gridSize; row++) {
      for (int col = 0; col < state.gridSize; col++) {
        final cell = state.maze[row][col];
        final x = col * cellSize;
        final y = row * cellSize;

        // Top wall
        if (cell.topWall) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + cellSize, y),
            wallPaint,
          );
        }

        // Right wall
        if (cell.rightWall) {
          canvas.drawLine(
            Offset(x + cellSize, y),
            Offset(x + cellSize, y + cellSize),
            wallPaint,
          );
        }

        // Bottom wall
        if (cell.bottomWall) {
          canvas.drawLine(
            Offset(x, y + cellSize),
            Offset(x + cellSize, y + cellSize),
            wallPaint,
          );
        }

        // Left wall
        if (cell.leftWall) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + cellSize),
            wallPaint,
          );
        }
      }
    }
  }

  void _drawPath(Canvas canvas) {
    if (state.path.isEmpty) return;

    // Draw path with gradient effect
    if (state.path.length >= 2) {
      final pathPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.shade300.withValues(alpha: 0.7),
            Colors.blue.shade600.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromLTWH(
            0, 0, state.gridSize * cellSize, state.gridSize * cellSize))
        ..strokeWidth = cellSize * 0.25
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final firstPos = state.path.first;
      path.moveTo(
        firstPos.col * cellSize + cellSize / 2,
        firstPos.row * cellSize + cellSize / 2,
      );

      for (int i = 1; i < state.path.length; i++) {
        final pos = state.path[i];
        path.lineTo(
          pos.col * cellSize + cellSize / 2,
          pos.row * cellSize + cellSize / 2,
        );
      }

      canvas.drawPath(path, pathPaint);
    }

    // Draw current position indicator
    if (state.currentPosition != null) {
      final currentPaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.fill;

      final currentPos = state.currentPosition!;
      final centerX = currentPos.col * cellSize + cellSize / 2;
      final centerY = currentPos.row * cellSize + cellSize / 2;

      // Draw pulsing circle at current position
      canvas.drawCircle(
        Offset(centerX, centerY),
        cellSize * 0.15,
        currentPaint,
      );

      // Draw white center
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(centerX, centerY),
        cellSize * 0.08,
        whitePaint,
      );
    }
  }

  void _drawStars(Canvas canvas) {
    final starPaint = Paint()
      ..color = Colors.yellow.shade600
      ..style = PaintingStyle.fill;

    final starBorderPaint = Paint()
      ..color = Colors.orange.shade800
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int row = 0; row < state.gridSize; row++) {
      for (int col = 0; col < state.gridSize; col++) {
        final cell = state.maze[row][col];

        if (cell.hasStar) {
          final pos = MazePosition(row, col);
          final collected = state.collectedStars.contains(pos);

          final centerX = col * cellSize + cellSize / 2;
          final centerY = row * cellSize + cellSize / 2;
          final radius = cellSize * 0.25;

          if (!collected) {
            // Add glow effect for uncollected stars
            final glowPaint = Paint()
              ..color = Colors.yellow.withValues(alpha: 0.3)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(
                Offset(centerX, centerY), radius * 1.3, glowPaint);

            _drawStar(
                canvas, centerX, centerY, radius, starPaint, starBorderPaint);
          } else {
            // Draw checkmark for collected star
            final collectedPaint = Paint()
              ..color = Colors.green.withValues(alpha: 0.4)
              ..style = PaintingStyle.fill;
            canvas.drawCircle(Offset(centerX, centerY), radius, collectedPaint);

            // Draw checkmark
            final checkPaint = Paint()
              ..color = Colors.green.shade700
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke;

            final checkPath = Path();
            checkPath.moveTo(centerX - radius * 0.4, centerY);
            checkPath.lineTo(centerX - radius * 0.1, centerY + radius * 0.3);
            checkPath.lineTo(centerX + radius * 0.4, centerY - radius * 0.3);
            canvas.drawPath(checkPath, checkPaint);
          }
        }
      }
    }
  }

  void _drawStar(Canvas canvas, double cx, double cy, double radius,
      Paint fillPaint, Paint borderPaint) {
    final path = Path();
    final points = 5;
    final angle = math.pi * 2 / points;

    for (int i = 0; i < points * 2; i++) {
      final r = i % 2 == 0 ? radius : radius / 2;
      final currentAngle = angle * i - math.pi / 2;
      final x = cx + r * math.cos(currentAngle);
      final y = cy + r * math.sin(currentAngle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawStartEnd(Canvas canvas) {
    // Draw start (green circle with "Start" text)
    _drawMarker(
      canvas,
      state.startPosition,
      Colors.green,
      'ابدأ\nStart',
    );

    // Draw end (red flag with "Finish" text)
    _drawMarker(
      canvas,
      state.endPosition,
      Colors.red,
      'نهاية\nFinish',
    );
  }

  void _drawMarker(Canvas canvas, MazePosition pos, Color color, String text) {
    final centerX = pos.col * cellSize + cellSize / 2;
    final centerY = pos.row * cellSize + cellSize / 2;
    final radius = cellSize * 0.3;

    // Draw circle background
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), radius, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(centerX, centerY), radius, borderPaint);

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: cellSize * 0.15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(MazePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
