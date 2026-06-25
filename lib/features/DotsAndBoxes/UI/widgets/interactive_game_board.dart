import 'dart:math' as math;

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
  /// Minimum touch target (Material / kid-friendly).
  static const double _minTouchTarget = 52;

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
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) =>
              _handleTap(details.localPosition, cellSize, dotRadius),
          onPanUpdate: (details) =>
              _handleHover(details.localPosition, cellSize, dotRadius),
          onPanEnd: (_) => _handlePanEnd(),
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
    _tryDrawLine(_getLineFromPosition(position, cellSize, dotRadius));
  }

  void _handlePanEnd() {
    _tryDrawLine(_hoveredLine);
    _clearHover();
  }

  void _tryDrawLine(Line? line) {
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

  double _hitPadding(double cellSize, double dotRadius) {
    return math.max(dotRadius * 4, _minTouchTarget / 2);
  }

  Line? _getLineFromPosition(
      Offset position, double cellSize, double dotRadius) {
    final padding = _hitPadding(cellSize, dotRadius);
    final maxDistance = padding * 1.5;
    final dotsPerSide = widget.state.dotsPerSide;

    Line? nearest;
    var nearestDist = maxDistance;

    for (int row = 0; row < dotsPerSide; row++) {
      for (int col = 0; col < dotsPerSide - 1; col++) {
        final dist = _distanceToSegment(
          position,
          Offset(col * cellSize, row * cellSize),
          Offset((col + 1) * cellSize, row * cellSize),
        );
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = Line(DotPosition(row, col), DotPosition(row, col + 1));
        }
      }
    }

    for (int row = 0; row < dotsPerSide - 1; row++) {
      for (int col = 0; col < dotsPerSide; col++) {
        final dist = _distanceToSegment(
          position,
          Offset(col * cellSize, row * cellSize),
          Offset(col * cellSize, (row + 1) * cellSize),
        );
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = Line(DotPosition(row, col), DotPosition(row + 1, col));
        }
      }
    }

    if (nearest != null && widget.state.isLineDrawn(nearest)) {
      final nearestUndrawn = _findNearestLine(position, cellSize, maxDistance);
      if (nearestUndrawn != null) {
        return nearestUndrawn;
      }
    }

    return nearest;
  }

  Line? _findNearestLine(Offset position, double cellSize, double maxDistance) {
    final dotsPerSide = widget.state.dotsPerSide;
    Line? nearest;
    var nearestDist = maxDistance;

    for (int row = 0; row < dotsPerSide; row++) {
      for (int col = 0; col < dotsPerSide - 1; col++) {
        final line = Line(DotPosition(row, col), DotPosition(row, col + 1));
        if (widget.state.isLineDrawn(line)) continue;

        final dist = _distanceToSegment(
          position,
          Offset(col * cellSize, row * cellSize),
          Offset((col + 1) * cellSize, row * cellSize),
        );
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = line;
        }
      }
    }

    for (int row = 0; row < dotsPerSide - 1; row++) {
      for (int col = 0; col < dotsPerSide; col++) {
        final line = Line(DotPosition(row, col), DotPosition(row + 1, col));
        if (widget.state.isLineDrawn(line)) continue;

        final dist = _distanceToSegment(
          position,
          Offset(col * cellSize, row * cellSize),
          Offset(col * cellSize, (row + 1) * cellSize),
        );
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = line;
        }
      }
    }

    return nearest;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) return (point - start).distance;

    var t =
        ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSq;
    t = t.clamp(0.0, 1.0);
    final projection = Offset(start.dx + t * dx, start.dy + t * dy);
    return (point - projection).distance;
  }
}
