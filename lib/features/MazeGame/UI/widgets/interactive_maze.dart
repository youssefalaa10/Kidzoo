import 'package:flutter/material.dart';

import '../../data/models/maze_models.dart';
import '../../data/models/maze_state.dart';
import 'maze_painter.dart';

class InteractiveMaze extends StatelessWidget {
  const InteractiveMaze({
    required this.state,
    required this.onStartDrawing,
    required this.onContinueDrawing,
    required this.onEndDrawing,
    super.key,
  });

  final MazeState state;
  final void Function(MazePosition) onStartDrawing;
  final void Function(MazePosition) onContinueDrawing;
  final VoidCallback onEndDrawing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Use 98% of available space to be as large as possible without overflowing
        final maxSize = width < height ? width * 0.98 : height * 0.98;
        final cellSize = maxSize / state.gridSize;
        final mazeSize = cellSize * state.gridSize;

        return Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: GestureDetector(
                onPanStart: (details) {
                  final pos =
                      _getPositionFromOffset(details.localPosition, cellSize);
                  if (pos != null) onStartDrawing(pos);
                },
                onPanUpdate: (details) {
                  final pos =
                      _getPositionFromOffset(details.localPosition, cellSize);
                  if (pos != null) onContinueDrawing(pos);
                },
                onPanEnd: (_) => onEndDrawing(),
                child: CustomPaint(
                  painter: MazePainter(state: state, cellSize: cellSize),
                  size: Size(mazeSize, mazeSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  MazePosition? _getPositionFromOffset(Offset offset, double cellSize) {
    final col = (offset.dx / cellSize).floor();
    final row = (offset.dy / cellSize).floor();

    if (row >= 0 && row < state.gridSize && col >= 0 && col < state.gridSize) {
      return MazePosition(row, col);
    }
    return null;
  }
}
