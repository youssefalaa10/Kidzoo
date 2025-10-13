import 'package:flutter/material.dart';

import '../../data/models/crossword_models.dart';

class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    required this.grid,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    this.highlightedCells = const [],
    super.key,
  });

  final List<List<CrosswordCell>> grid;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onCellTap;
  final List<List<int>> highlightedCells;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate cell size accounting for padding, borders, and spacing
    const containerPadding = 16.0;
    const cellSpacing = 2.0;
    final cols = grid.isNotEmpty ? grid[0].length : 1;
    final totalSpacing = cellSpacing * (cols - 1);
    final availableWidth =
        screenWidth - (containerPadding * 2) - 32; // 32 for screen margins
    final cellSize = ((availableWidth - totalSpacing) / cols).clamp(30.0, 60.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(grid.length, (row) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: row < grid.length - 1 ? cellSpacing : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(grid[row].length, (col) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: col < grid[row].length - 1 ? cellSpacing : 0,
                    ),
                    child: _buildCell(grid[row][col], cellSize, row, col),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCell(CrosswordCell cell, double size, int row, int col) {
    final isSelected = selectedRow == row && selectedCol == col;
    final isHighlighted =
        highlightedCells.any((pos) => pos[0] == row && pos[1] == col);
    final fontSize = (size * 0.5).clamp(14.0, 28.0);

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cell.isBlocked
              ? Colors.grey.shade800
              : isSelected
                  ? Colors.blue.shade200
                  : isHighlighted
                      ? Colors.blue.shade50
                      : cell.isCorrect
                          ? Colors.green.shade50
                          : Colors.white,
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade500
                : isHighlighted
                    ? Colors.blue.shade200
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 0.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            // Cell number (RTL - top right)
            if (cell.number != null)
              Positioned(
                top: 1,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '${cell.number}',
                    style: TextStyle(
                      fontSize: (size * 0.2).clamp(8.0, 12.0),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      height: 1,
                    ),
                  ),
                ),
              ),
            // Letter (centered)
            if (!cell.isBlocked)
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    cell.userLetter ?? '',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: cell.isCorrect
                          ? Colors.green.shade700
                          : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
