import 'package:flutter/material.dart';
import '../../data/sorter_models.dart';

class BasketTarget extends StatefulWidget {

  const BasketTarget({
    required this.basketType, required this.label, required this.icon, required this.color, required this.onFoodDropped, super.key,
    this.isTargetBasket = false,
  });
  final FoodType basketType;
  final String label;
  final IconData icon;
  final Color color;
  final bool isTargetBasket;
  final void Function(FoodItem) onFoodDropped;

  @override
  State<BasketTarget> createState() => _BasketTargetState();
}

class _BasketTargetState extends State<BasketTarget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isTargetBasket) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BasketTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTargetBasket && !oldWidget.isTargetBasket) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isTargetBasket && oldWidget.isTargetBasket) {
      _pulseController.stop();
      _pulseController.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<FoodItem>(
      builder: (context, candidateItems, rejectedItems) {
        final isHovered = candidateItems.isNotEmpty;

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isTargetBasket && !isHovered
                  ? _pulseAnimation.value
                  : 1.0,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHovered
                      ? widget.color.withValues(alpha: 0.3)
                      : (widget.isTargetBasket
                          ? widget.color.withValues(alpha: 0.15)
                          : widget.color.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHovered
                        ? widget.color
                        : (widget.isTargetBasket
                            ? widget.color
                            : widget.color.withValues(alpha: 0.5)),
                    width: isHovered || widget.isTargetBasket ? 4 : 2,
                  ),
                  boxShadow: isHovered || widget.isTargetBasket
                      ? [
                          BoxShadow(
                            color: widget.color
                                .withValues(alpha: isHovered ? 0.3 : 0.4),
                            blurRadius: widget.isTargetBasket ? 15 : 10,
                            spreadRadius: widget.isTargetBasket ? 5 : 2,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 80,
                      color: widget.color,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.color.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      onAcceptWithDetails: (details) {
        widget.onFoodDropped(details.data);
      },
    );
  }
}
