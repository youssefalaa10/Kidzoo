import 'package:flutter/material.dart';

import '../../data/model/color_model.dart';

class ColorContainer extends StatefulWidget {
  const ColorContainer({
    required this.color,
    required this.isMatched,
    required this.languageCode,
    required this.onMatched,
    super.key,
  });

  final ColorModel color;
  final bool isMatched;
  final String languageCode;
  final VoidCallback onMatched;

  @override
  State<ColorContainer> createState() => _ColorContainerState();
}

class _ColorContainerState extends State<ColorContainer>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() {
      _isHovered = hovering;
    });
    if (hovering && !widget.isMatched) {
      _bounceController.forward();
    } else {
      _bounceController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<ColorModel>(
      onWillAcceptWithDetails: (details) {
        if (widget.isMatched) return false;
        final droppedColor = details.data;
        final isCorrect = droppedColor.colorValue == widget.color.colorValue;
        if (isCorrect && !widget.isMatched) {
          _onHover(true);
        }
        return isCorrect && !widget.isMatched;
      },
      onLeave: (data) {
        _onHover(false);
      },
      onAcceptWithDetails: (details) {
        final droppedColor = details.data;
        if (droppedColor.colorValue == widget.color.colorValue &&
            !widget.isMatched) {
          widget.onMatched();
          _onHover(false);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty || _isHovered;
        final hasRejected = rejectedData.isNotEmpty;

        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isHighlighted ? _bounceAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(widget.color.colorValue).withValues(alpha: 0.3),
                  border: Border.all(
                    color: isHighlighted
                        ? Color(widget.color.colorValue)
                        : hasRejected
                            ? Colors.red
                            : Colors.grey.shade300,
                    width: isHighlighted ? 4 : 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: widget.isMatched
                      ? [
                          BoxShadow(
                            color: Color(widget.color.colorValue)
                                .withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // Checkmark for matched colors
                    if (widget.isMatched)
                      const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    // Color label
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Text(
                        widget.color.getColorName(widget.languageCode),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isMatched
                              ? Colors.white
                              : Color(widget.color.colorValue),
                          shadows: widget.isMatched
                              ? [
                                  const Shadow(
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    // Sparkle effect when matched
                    if (widget.isMatched)
                      ...List.generate(5, (index) {
                        return Positioned(
                          left: (index * 20.0) % 100,
                          top: (index * 15.0) % 100,
                          child: const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 20,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
