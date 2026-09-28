import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Rays radiating from the centre, behind something being celebrated.
///
/// Lifted out of `AdventureRewardOverlay`, where it was private, so the badge
/// pop-up gets the same visual language as a story page coming home. It knows
/// nothing about either: it is twelve wedges and a colour.
class RewardBurstPainter extends CustomPainter {
  const RewardBurstPainter(this.color);

  final Color color;

  /// Half-width of each wedge in radians. Narrow enough to read as light
  /// rather than as a pie chart.
  static const double _rayHalfWidth = 0.09;
  static const int _rayCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;
    final Paint paint = Paint()..color = color.withValues(alpha: 0.5);
    for (int index = 0; index < _rayCount; index++) {
      final double angle = index * (2 * math.pi / _rayCount);
      final Path path = Path()
        ..moveTo(centre.dx, centre.dy)
        ..lineTo(
          centre.dx + radius * math.cos(angle - _rayHalfWidth),
          centre.dy + radius * math.sin(angle - _rayHalfWidth),
        )
        ..lineTo(
          centre.dx + radius * math.cos(angle + _rayHalfWidth),
          centre.dy + radius * math.sin(angle + _rayHalfWidth),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(RewardBurstPainter oldDelegate) =>
      oldDelegate.color != color;
}
