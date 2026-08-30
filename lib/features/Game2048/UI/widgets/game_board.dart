import 'package:flutter/material.dart';

import '../../data/models/board_model.dart';
import 'animated_tile.dart';
import 'tile_widget.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({
    required this.board,
    required this.onSwipe,
    required this.boardSize,
    super.key,
  });

  final Board board;
  final void Function(DragEndDetails) onSwipe;
  final double boardSize;

  @override
  Widget build(BuildContext context) {
    final spacing = 12.0;
    final tileSize = (boardSize - (spacing * (board.size + 1))) / board.size;

    return GestureDetector(
      onPanEnd: onSwipe,
      child: Container(
        width: boardSize,
        height: boardSize,
        padding: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          color: const Color(0xFFBBADA0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Empty grid background
            _buildEmptyGrid(tileSize, spacing),
            // Tiles
            ..._buildTiles(tileSize, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGrid(double tileSize, double spacing) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: board.size,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: board.size * board.size,
      itemBuilder: (context, index) {
        return EmptyTileWidget(tileSize: tileSize);
      },
    );
  }

  List<Widget> _buildTiles(double tileSize, double spacing) {
    return board.tiles.asMap().entries.map((entry) {
      final index = entry.key;
      final tile = entry.value;
      final top = tile.row * (tileSize + spacing);
      final left = tile.col * (tileSize + spacing);

      return Positioned(
        key: ValueKey('tile-$index-${tile.value}-${tile.row}-${tile.col}'),
        top: top,
        left: left,
        child: AnimatedTile(
          tile: tile,
          tileSize: tileSize,
          spacing: spacing,
        ),
      );
    }).toList();
  }
}
