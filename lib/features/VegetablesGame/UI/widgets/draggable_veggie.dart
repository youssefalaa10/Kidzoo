import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/vegetables_game_engine.dart';

class DraggableVeggie extends StatelessWidget {
  const DraggableVeggie({
    super.key,
    required this.option,
    required this.isLandscape,
    this.isShaking = false,
    this.isSuccess = false,
    this.isTarget = false,
  });
  final VegetableItem option;
  final bool isLandscape;
  final bool isShaking;
  final bool isSuccess;
  final bool isTarget;

  Widget _buildCard({required double size, bool dragging = false}) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        margin: EdgeInsets.all(size * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: dragging ? Colors.green.shade200 : Colors.transparent,
            width: dragging ? 4 : 0,
          ),
          boxShadow: dragging
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.15),
          child: Image.asset(option.assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double size = constraints.maxWidth;

      Widget card = Draggable<VegetableItem>(
        data: option,
        feedback: Material(
          color: Colors.transparent,
          child: _buildCard(size: size, dragging: true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: _buildCard(size: size),
        ),
        child: _buildCard(size: size),
      );

      if (isShaking) {
        card = card
            .animate(key: UniqueKey())
            .shakeX(hz: 4, amount: 6, duration: 400.ms)
            .tint(color: Colors.red.withOpacity(0.3), duration: 400.ms);
      } else if (isSuccess && isTarget) {
        // Hide the draggable card when successfully placed in the target
        card = Opacity(opacity: 0.0, child: _buildCard(size: size));
      } else {
        card =
            card.animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
      }

      return card;
    });
  }
}
