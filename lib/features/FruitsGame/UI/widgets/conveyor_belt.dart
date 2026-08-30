import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/fruits_game_engine.dart';

class ConveyorBelt extends StatefulWidget {

  const ConveyorBelt({
    super.key,
    required this.fruits,
    required this.onFruitTapped,
    required this.currentTarget,
    required this.isFrozen,
    this.successFruit,
    this.shakingFruit,
    required this.onBeltFinished,
  });
  final List<FruitItem> fruits;
  final void Function(FruitItem) onFruitTapped;
  final FruitItem currentTarget;
  final bool isFrozen;
  final FruitItem? successFruit;
  final FruitItem? shakingFruit;
  final VoidCallback onBeltFinished;

  @override
  State<ConveyorBelt> createState() => _ConveyorBeltState();
}

class _ConveyorBeltState extends State<ConveyorBelt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Speed varies between 8 to 12 seconds per belt cycle
    final durationSec = 8 + (DateTime.now().millisecond % 5);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: durationSec),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // If the belt finishes and the correct fruit was not tapped
        if (widget.successFruit == null && !widget.isFrozen) {
          widget.onBeltFinished();
        }
      }
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(ConveyorBelt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fruits != oldWidget.fruits) {
      _controller.reset();
      final durationSec = 8 + (DateTime.now().millisecond % 5);
      _controller.duration = Duration(seconds: durationSec);
      if (!widget.isFrozen) {
        _controller.forward();
      }
    } else {
      if (widget.isFrozen && _controller.isAnimating) {
        _controller.stop();
      } else if (!widget.isFrozen && !_controller.isAnimating && widget.successFruit == null) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final itemWidth = 120.0;
        final spacing = 40.0;
        final totalBeltWidth = widget.fruits.length * (itemWidth + spacing);
        final totalTravel = screenWidth + totalBeltWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Belt background
            Positioned(
              left: -50,
              right: -50,
              bottom: 20,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black54, width: 4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    20,
                    (index) => Container(
                      width: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
            
            // Fruits
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(widget.fruits.length, (index) {
                    final fruit = widget.fruits[index];
                    final startX = screenWidth + (index * (itemWidth + spacing));
                    final currentX = startX - (_controller.value * totalTravel);

                    final isSuccess = widget.successFruit?.assetPath == fruit.assetPath;
                    final isShaking = widget.shakingFruit?.assetPath == fruit.assetPath;

                    Widget fruitWidget = GestureDetector(
                      onTap: () {
                        if (!widget.isFrozen) {
                          widget.onFruitTapped(fruit);
                        }
                      },
                      child: Container(
                        width: itemWidth,
                        height: itemWidth,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            const BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                            if (isSuccess)
                              BoxShadow(
                                color: Colors.yellow.withValues(alpha: 0.6),
                                blurRadius: 20,
                                spreadRadius: 10,
                              ),
                          ],
                          border: Border.all(
                            color: isSuccess ? Colors.yellow.shade600 : Colors.transparent,
                            width: isSuccess ? 6 : 0,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(fruit.assetPath),
                      ),
                    );

                    if (isShaking) {
                      fruitWidget = fruitWidget
                          .animate(key: UniqueKey())
                          .shakeX(hz: 4, amount: 6, duration: 400.ms)
                          .tint(color: Colors.red.withValues(alpha: 0.3), duration: 400.ms);
                    } else if (isSuccess) {
                      fruitWidget = fruitWidget
                          .animate()
                          .scale(curve: Curves.elasticOut, duration: 800.ms, begin: const Offset(1, 1), end: const Offset(1.5, 1.5))
                          .shimmer(duration: 800.ms);
                    } else {
                      // Slight bounce as it moves
                      fruitWidget = fruitWidget
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .moveY(begin: 0, end: -5, duration: 500.ms, curve: Curves.easeInOut);
                    }

                    return Positioned(
                      left: currentX,
                      bottom: 40,
                      child: fruitWidget,
                    );
                  }),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
