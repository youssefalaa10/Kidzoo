import 'package:flutter/material.dart';

import '../../data/models/color_memory_constants.dart';

class ColorGridWidget extends StatelessWidget {
  const ColorGridWidget({
    required this.gridSize,
    required this.palette,
    required this.highlightedIndex,
    required this.onColorTap,
    required this.isInteractive,
    this.colorBlindMode = false,
    super.key,
  });

  final int gridSize;
  final ColorPalette palette;
  final int highlightedIndex;
  final void Function(int) onColorTap;
  final bool isInteractive;
  final bool colorBlindMode;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - (ColorMemoryConstants.gridPadding * 2);
    final gridWidth = availableWidth.clamp(200.0, 500.0);

    return Container(
      width: gridWidth,
      padding: const EdgeInsets.all(ColorMemoryConstants.gridPadding),
      decoration: BoxDecoration(
        color: ColorMemoryConstants.cardBackgroundColor,
        borderRadius: BorderRadius.circular(ColorMemoryConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          crossAxisSpacing: ColorMemoryConstants.gridSpacing,
          mainAxisSpacing: ColorMemoryConstants.gridSpacing,
        ),
        itemCount: gridSize * gridSize,
        itemBuilder: (context, index) {
          // Only show colors up to the palette size
          if (index >= palette.colors.length) {
            return const SizedBox.shrink();
          }

          final isHighlighted = index == highlightedIndex;
          final color = isHighlighted
              ? palette.highlightColors[index]
              : palette.colors[index];

          return ColorTile(
            color: color,
            isHighlighted: isHighlighted,
            isInteractive: isInteractive,
            colorName: palette.names[index],
            colorBlindMode: colorBlindMode,
            onTap: () => onColorTap(index),
          );
        },
      ),
    );
  }
}

class ColorTile extends StatefulWidget {
  const ColorTile({
    required this.color,
    required this.isHighlighted,
    required this.isInteractive,
    required this.colorName,
    required this.colorBlindMode,
    required this.onTap,
    super.key,
  });

  final Color color;
  final bool isHighlighted;
  final bool isInteractive;
  final String colorName;
  final bool colorBlindMode;
  final VoidCallback onTap;

  @override
  State<ColorTile> createState() => _ColorTileState();
}

class _ColorTileState extends State<ColorTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ColorMemoryConstants.tapAnimationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ColorTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isInteractive) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isInteractive) {
      _controller.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (widget.isInteractive) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isHighlighted ? 1.05 : _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isHighlighted
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                border: widget.isHighlighted
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.colorBlindMode)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.colorName[0],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                      ),
                    ),
                  // Pump feedback icon overlay for obvious interaction
                  AnimatedOpacity(
                    opacity: _controller.isAnimating ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.touch_app,
                      size: 36,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
