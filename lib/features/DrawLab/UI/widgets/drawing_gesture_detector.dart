import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrawingGestureDetector extends StatefulWidget {
  const DrawingGestureDetector({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;

  @override
  State<DrawingGestureDetector> createState() => _DrawingGestureDetectorState();
}

class _DrawingGestureDetectorState extends State<DrawingGestureDetector>
    with TickerProviderStateMixin {
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _provideHapticFeedback();
        widget.onTap?.call();
      },
      onLongPress: () {
        _provideHapticFeedback();
        widget.onLongPress?.call();
      },
      onPanStart: (details) {
        _isDrawing = true;
        _feedbackController.forward();
        widget.onPanStart?.call(details);
      },
      onPanUpdate: (details) {
        if (_isDrawing) {
          widget.onPanUpdate?.call(details);
        }
      },
      onPanEnd: (details) {
        _isDrawing = false;
        _feedbackController.reverse();
        widget.onPanEnd?.call(details);
      },
      child: AnimatedBuilder(
        animation: _feedbackAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _feedbackAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }

  void _provideHapticFeedback() {
    // Provide subtle haptic feedback for better user experience
    HapticFeedback.lightImpact();
  }
}
