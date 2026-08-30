import 'package:flutter/material.dart';
import '../../services/background_resolver.dart';

/// A standard responsive wrapper for all physics-based games.
/// It enforces a strict aspect ratio to preserve physics boundaries
/// and centers the game canvas. The remaining exterior space is painted
/// with a dynamically resolved decorative background image to avoid black bars.
class PhysicsGameCanvas extends StatelessWidget {

  const PhysicsGameCanvas({
    required this.child,
    super.key,
    this.useTechBackground = false,
    this.aspectRatio = 9 / 16, // Default to standard mobile portrait ratio
  });
  final Widget child;
  final double aspectRatio;
  final bool useTechBackground;

  @override
  Widget build(BuildContext context) {
    final type = useTechBackground ? BackgroundType.tech : BackgroundType.game;
    final bgPath = BackgroundResolver(context, type).resolveBackground()!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        image: DecorationImage(
          image: AssetImage(bgPath),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: child,
          ),
        ),
      ),
    );
  }
}
