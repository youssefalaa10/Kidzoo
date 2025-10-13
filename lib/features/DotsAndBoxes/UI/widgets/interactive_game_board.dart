import 'package:flutter/material.dart';

import '../../data/models/dots_and_boxes_models.dart';
import '../../data/models/game_state_model.dart';
import 'game_board_painter.dart';

class InteractiveGameBoard extends StatefulWidget {
  const InteractiveGameBoard({
    required this.state,
    required this.onLineTapped,
    super.key,
  });

  final DotsAndBoxesState state;
  final void Function(DotPosition start, DotPosition end) onLineTapped;

  @override
  State<InteractiveGameBoard> createState() => _InteractiveGameBoardState();
}

class _InteractiveGameBoardState extends State<InteractiveGameBoard>
    with SingleTickerProviderStateMixin {
  Line? _hoveredLine;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250), // Faster animation
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Smoother curve
    );
  }

  @override
  void didUpdateWidget(InteractiveGameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when boxes are completed
    if (widget.state.lastCompletedBoxes.isNotEmpty &&
        oldWidget.state.lastCompletedBoxes != widget.state.lastCompletedBoxes) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate board size based on screen size
    final maxBoardSize =
        screenWidth < screenHeight ? screenWidth * 0.85 : screenHeight * 0.55;

    final cellSize = maxBoardSize / (widget.state.gridSize + 0.5);
    final dotRadius = cellSize * 0.12;

    final boardSize = cellSize * widget.state.gridSize;
    final totalSize = boardSize + (dotRadius * 2);

    return Center(
      child: Container(
        width: totalSize,
        height: totalSize,
        padding: EdgeInsets.all(dotRadius),
        child: GestureDetector(
          onTapUp: (details) =>
              _handleTap(details.localPosition, cellSize, dotRadius),
          onPanUpdate: (details) =>
              _handleHover(details.localPosition, cellSize, dotRadius),
          onPanEnd: (_) => _clearHover(),
          child: MouseRegion(
            onHover: (event) =>
                _handleHover(event.localPosition, cellSize, dotRadius),
            onExit: (_) => _clearHover(),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: GameBoardPainter(
                    state: widget.state,
                    cellSize: cellSize,
                    dotRadius: dotRadius,
                    hoveredLine: _hoveredLine,
                    animationValue: _animation.value,
                  ),
                  size: Size(boardSize, boardSize),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position, double cellSize, double dotRadius) {
    final line = _getLineFromPosition(position, cellSize, dotRadius);

    if (line != null && !widget.state.isLineDrawn(line)) {
      widget.onLineTapped(line.start, line.end);
    }
  }

  void _handleHover(Offset position, double cellSize, double dotRadius) {
    final line = _getLineFromPosition(position, cellSize, dotRadius);

    if (line != _hoveredLine) {
      setState(() {
        _hoveredLine = line;
      });
    }
  }

  void _clearHover() {
    if (_hoveredLine != null) {
      setState(() {
        _hoveredLine = null;
      });
    }
  }

  Line? _getLineFromPosition(
      Offset position, double cellSize, double dotRadius) {
    final dotsPerSide = widget.state.dotsPerSide;

    // Check horizontal lines
    for (int row = 0; row < dotsPerSide; row++) {
      for (int col = 0; col < dotsPerSide - 1; col++) {
        final lineStartX = col * cellSize;
        final lineEndX = (col + 1) * cellSize;
        final lineY = row * cellSize;

        // Create a hit area around the line
        final hitArea = Rect.fromLTRB(
          lineStartX - dotRadius,
          lineY - dotRadius * 1.5,
          lineEndX + dotRadius,
          lineY + dotRadius * 1.5,
        );

        if (hitArea.contains(position)) {
          return Line(
            DotPosition(row, col),
            DotPosition(row, col + 1),
          );
        }
      }
    }

    // Check vertical lines
    for (int row = 0; row < dotsPerSide - 1; row++) {
      for (int col = 0; col < dotsPerSide; col++) {
        final lineX = col * cellSize;
        final lineStartY = row * cellSize;
        final lineEndY = (row + 1) * cellSize;

        // Create a hit area around the line
        final hitArea = Rect.fromLTRB(
          lineX - dotRadius * 1.5,
          lineStartY - dotRadius,
          lineX + dotRadius * 1.5,
          lineEndY + dotRadius,
        );

        if (hitArea.contains(position)) {
          return Line(
            DotPosition(row, col),
            DotPosition(row + 1, col),
          );
        }
      }
    }

    return null;
  }
}
