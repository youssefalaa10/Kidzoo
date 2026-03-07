import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StarComponent extends PositionComponent {
  StarComponent({
    required super.position,
    this.radius = 15,
  }) : super(
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  final double radius;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw a simple star shape
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = (size / 2).toOffset();
    final outerRadius = radius;
    final innerRadius = radius / 2.5;

    // Simpler draw: a white circle as "star" or use a Flutter icon
    // Using a diamond/star shape manually:
    path.moveTo(center.dx, center.dy - outerRadius);
    path.lineTo(center.dx + innerRadius, center.dy - innerRadius);
    path.lineTo(center.dx + outerRadius, center.dy);
    path.lineTo(center.dx + innerRadius, center.dy + innerRadius);
    path.lineTo(center.dx, center.dy + outerRadius);
    path.lineTo(center.dx - innerRadius, center.dy + innerRadius);
    path.lineTo(center.dx - outerRadius, center.dy);
    path.lineTo(center.dx - innerRadius, center.dy - innerRadius);
    path.close();

    canvas.drawPath(path, paint);

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
