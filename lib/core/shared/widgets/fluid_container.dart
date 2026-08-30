import 'package:flutter/material.dart';

/// A standard responsive wrapper for all non-physics UI screens.
/// It enforces a maximum width to prevent components from stretching
/// on tablets and desktop monitors, while centering the content.
class FluidContainer extends StatelessWidget {

  const FluidContainer({
    required this.child,
    super.key,
    this.maxWidth = 800.0,
    this.padding = const EdgeInsets.all(16.0),
  });
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
