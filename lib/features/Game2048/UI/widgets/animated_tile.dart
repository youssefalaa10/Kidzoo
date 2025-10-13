import 'package:flutter/material.dart';

import '../../data/models/tile_model.dart';
import 'tile_widget.dart';

class AnimatedTile extends StatefulWidget {
  const AnimatedTile({
    required this.tile,
    required this.tileSize,
    required this.spacing,
    super.key,
  });

  final Tile tile;
  final double tileSize;
  final double spacing;

  @override
  State<AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Scale animation for new tiles
    if (widget.tile.isNew) {
      _scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
    } else if (widget.tile.merged) {
      // Pulse animation for merged tiles
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
    } else {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.0,
      ).animate(_controller);
    }

    // Calculate position animation only if tile actually moved
    final hasMoved = widget.tile.previousRow != null &&
        widget.tile.previousCol != null &&
        (widget.tile.previousRow != widget.tile.row ||
            widget.tile.previousCol != widget.tile.col);

    if (hasMoved) {
      final fromRow = widget.tile.previousRow!;
      final fromCol = widget.tile.previousCol!;
      final toRow = widget.tile.row;
      final toCol = widget.tile.col;

      final dx = (fromCol - toCol) * (widget.tileSize + widget.spacing);
      final dy = (fromRow - toRow) * (widget.tileSize + widget.spacing);

      _positionAnimation = Tween<Offset>(
        begin: Offset(dx, dy),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOut,
        ),
      );
    } else {
      _positionAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(_controller);
    }

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't re-animate if it's the same tile
    if (oldWidget.tile.value != widget.tile.value ||
        oldWidget.tile.row != widget.tile.row ||
        oldWidget.tile.col != widget.tile.col) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: TileWidget(
              tile: widget.tile,
              tileSize: widget.tileSize,
            ),
          ),
        );
      },
    );
  }
}
