import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/vegetables_game_engine.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (dashLength + dashSpace)).floor();
    final anglePerDash = (dashLength + dashSpace) / radius;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * anglePerDash;
      final sweepAngle = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VeggieTarget extends StatelessWidget {
  final VegetableItem? currentTarget;
  final bool isSuccess;
  final void Function(VegetableItem) onAccept;
  const VeggieTarget({
    super.key,
    required this.currentTarget,
    required this.isSuccess,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTarget == null) return const SizedBox();

    return DragTarget<VegetableItem>(
      onAcceptWithDetails: (details) {
        if (!isSuccess) {
          onAccept(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = min(constraints.maxWidth, constraints.maxHeight);
            
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dashed Outline or Solid hovering state
                  if (!isSuccess && !isHovering)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DashedCirclePainter(
                          color: Colors.grey.shade400,
                          strokeWidth: 4,
                          dashLength: 10,
                          dashSpace: 8,
                        ),
                      ),
                    ),
                  if (!isSuccess && isHovering)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 6),
                        color: Colors.green.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                    ),
                  if (isSuccess)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                    ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),

                  // Placeholder Silhouette
                  if (!isSuccess)
                    Padding(
                      padding: EdgeInsets.all(size * 0.16),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.grey.shade300,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(currentTarget!.assetPath),
                      ),
                    ),

                  // Correct Image
                  if (isSuccess)
                    Padding(
                      padding: EdgeInsets.all(size * 0.12),
                      child: Image.asset(currentTarget!.assetPath)
                          .animate()
                          .scale(curve: Curves.elasticOut, duration: 800.ms)
                          .shimmer(duration: 800.ms, color: Colors.yellow.withOpacity(0.4)),
                    ),
                    
                  // Star Burst
                  if (isSuccess)
                    ...List.generate(5, (index) {
                      final angle = (index * 2 * pi) / 5;
                      return Transform.translate(
                        offset: Offset(cos(angle) * (size / 1.8), sin(angle) * (size / 1.8)),
                        child: Icon(Icons.star, color: Colors.amber, size: size * 0.16)
                            .animate()
                            .scale(curve: Curves.elasticOut, duration: 600.ms)
                            .fadeOut(delay: 1000.ms, duration: 400.ms),
                      );
                    }),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
