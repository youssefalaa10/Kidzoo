import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/feed_animal_models.dart';

class AnimalTarget extends StatefulWidget {

  const AnimalTarget({
    super.key,
    required this.animal,
    required this.isSuccess,
    required this.isError,
    this.eatenFood,
    required this.onFoodDropped,
    this.maxHeight = 350,
  });
  final AnimalItem animal;
  final bool isSuccess;
  final bool isError;
  final FeedItem? eatenFood;
  final void Function(FeedItem) onFoodDropped;
  final double maxHeight;

  @override
  State<AnimalTarget> createState() => _AnimalTargetState();
}

class _AnimalTargetState extends State<AnimalTarget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant AnimalTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.maxHeight / 350;
    return DragTarget<FeedItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        widget.onFoodDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final sineValue = 4 * pi * _shakeController.value;
            final dx = 15 * sin(sineValue);
            
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: widget.isSuccess ? 1.15 : 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: widget.maxHeight),
                      child: Image.asset(
                        widget.animal.imageAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              if (widget.isSuccess && widget.eatenFood != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                  builder: (context, value, child) {
                    // Food starts at bottom (scale 1.0) and moves to center (scale 0.0)
                    return Positioned(
                      top: (200 + (1 - value) * 100) * scale, // Starts lower
                      child: Transform.scale(
                        scale: 1.0 - value, // Shrinks as it goes into mouth
                        child: Opacity(
                          opacity: 1.0 - (value * 0.5), // Fades slightly
                          child: Image.asset(widget.eatenFood!.imageAsset,
                              height: 80 * scale),
                        ),
                      ),
                    );
                  },
                ),
              if (widget.isSuccess)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Positioned(
                      top: (20 - value * 50) * scale,
                      child: Opacity(
                        opacity: 1.0 - value,
                        child: Icon(Icons.star,
                            color: Colors.amber, size: 60 * scale),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
