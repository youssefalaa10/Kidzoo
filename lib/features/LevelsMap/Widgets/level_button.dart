import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Data/Logic/Model/level_model.dart';

class LevelButton extends StatefulWidget {
  // Optional color parameter for game type

  const LevelButton({
    required this.level,
    required this.onTap,
    super.key,
    this.color,
  });
  final Level level;
  final VoidCallback onTap;
  final Color? color;

  @override
  LevelButtonState createState() => LevelButtonState();
}

class LevelButtonState extends State<LevelButton>
    with TickerProviderStateMixin {
  // Helper method to darken a color for borders
  Color _darkenColor(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }

  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _rotationController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    // Initialize tap animation controller
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );

    // Initialize bounce animation controller (local to each button)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Initialize rotation controller for last level sparkle
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _tapController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onTap() {
    _tapController.forward().then((_) => _tapController.reverse());
    widget.onTap();
  }

  // Check if this is the last level of its phase (6, 12, 18)
  bool _isLastLevelOfPhase() {
    return widget.level.id == 6 ||
        widget.level.id == 12 ||
        widget.level.id == 18;
  }

  @override
  Widget build(BuildContext context) {
    final isLastLevel = _isLastLevelOfPhase();

    // Static part of the widget tree
    final buttonContent = Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: isLastLevel
              ? CustomPaint(
                  painter: StarPainter(
                    color: widget.level.isLocked
                        ? Colors.grey.shade600
                        : Colors.yellow.shade700,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.level.isLocked
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : [Colors.yellow.shade200, Colors.yellow.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                      border: Border.all(
                        color: widget.level.isLocked
                            ? Colors.grey.shade800
                            : Colors.yellow.shade900,
                        width: 3,
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.level.isLocked
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : widget.color != null
                              ? [
                                  widget.color!.withValues(alpha: 0.7),
                                  widget.color!
                                ]
                              : [
                                  Colors.orange.shade300,
                                  Colors.orange.shade500
                                ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ],
                    border: Border.all(
                      color: widget.level.isLocked
                          ? Colors.grey.shade800
                          : widget.color != null
                              ? _darkenColor(widget.color!)
                              : Colors.yellow.shade700,
                      width: 3,
                    ),
                  ),
                ),
        ),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.level.id}',
                style: GoogleFonts.chewy(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              if (isLastLevel && !widget.level.isLocked)
                const Icon(Icons.expand_circle_down_outlined,
                    color: Colors.yellowAccent, size: 20),
            ],
          ),
        ),
        // Lock icon for locked levels
        if (widget.level.isLocked)
          const Icon(
            Icons.lock,
            color: Colors.white70,
            size: 30,
          ),
      ],
    );

    return VisibilityDetector(
      key: Key('level-${widget.level.id}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        setState(() {
          _isVisible = info.visibleFraction > 0;
          // Pause or resume animations based on visibility
          if (_isVisible) {
            if (mounted) {
              _bounceController.repeat(reverse: true);
              _rotationController.repeat();
            }
          } else {
            _bounceController.stop();
            _rotationController.stop();
          }
        });
      },
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    child!,
                    // Sparkle effect for unlocked levels (enhanced for last level)
                    if (!widget.level.isLocked && _isVisible)
                      RotationTransition(
                        turns: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: _rotationController,
                            curve: Curves.linear,
                          ),
                        ),
                        child: Icon(
                          Icons.star,
                          color: isLastLevel
                              ? Colors.yellow.shade800
                              : Colors.yellow.shade300,
                          size: isLastLevel ? 70 : 60,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          child: buttonContent,
        ),
      ),
    );
  }
}

// Custom painter for star shape
class StarPainter extends CustomPainter {
  StarPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const numberOfPoints = 5;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outerRadius = radius;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < numberOfPoints * 2; i++) {
      final isOuterPoint = i % 2 == 0;
      final angle = (i * pi / numberOfPoints) + (pi / 2);
      final radius = isOuterPoint ? outerRadius : innerRadius;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
