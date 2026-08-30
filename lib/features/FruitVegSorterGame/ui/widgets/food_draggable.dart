import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/sorter_models.dart';

class FoodDraggable extends StatefulWidget {

  const FoodDraggable({
    super.key,
    required this.food,
    required this.isDropped,
    required this.showHint,
    required this.flutterTts,
    this.isError = false,
  });
  final FoodItem food;
  final bool isDropped;
  final bool showHint;
  final FlutterTts flutterTts;
  final bool isError;

  @override
  State<FoodDraggable> createState() => _FoodDraggableState();
}

class _FoodDraggableState extends State<FoodDraggable>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void didUpdateWidget(FoodDraggable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDropped) {
      return const SizedBox(width: 100, height: 100);
    }

    final Widget content = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.showHint ? Colors.amber : Colors.transparent,
          width: widget.showHint ? 4 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.showHint
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.black12,
            blurRadius: widget.showHint ? 15 : 8,
            spreadRadius: widget.showHint ? 5 : 2,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          widget.food.imageAsset,
          width: 70,
          height: 70,
          fit: BoxFit.contain,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Draggable<FoodItem>(
        data: widget.food,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: content,
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: content,
        ),
        onDragStarted: () {
          widget.flutterTts.speak(
              widget.food.getLocalizedName(AppLocalizations.of(context)));
        },
        child: content,
      ),
    );
  }
}
