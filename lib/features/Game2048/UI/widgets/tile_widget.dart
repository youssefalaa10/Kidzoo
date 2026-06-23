import 'package:flutter/material.dart';
import '../../data/models/tile_model.dart';

class TileWidget extends StatelessWidget {
  const TileWidget({
    required this.tile,
    required this.tileSize,
    super.key,
  });

  final Tile tile;
  final double tileSize;

  Color _getTileColor(int value) {
    switch (value) {
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFFEDC53F);
      case 2048:
        return const Color(0xFFEDC22E);
      case 4096:
        return const Color(0xFF3C3A32);
      default:
        return const Color(0xFF3C3A32);
    }
  }

  Color _getTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }

  double _getFontSize(int value) {
    if (value < 100) return tileSize * 0.35;
    if (value < 1000) return tileSize * 0.30;
    if (value < 10000) return tileSize * 0.25;
    return tileSize * 0.20;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        color: _getTileColor(tile.value),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${tile.value}',
          style: TextStyle(
            fontSize: _getFontSize(tile.value),
            fontWeight: FontWeight.bold,
            color: _getTextColor(tile.value),
          ),
        ),
      ),
    );
  }
}

class EmptyTileWidget extends StatelessWidget {
  const EmptyTileWidget({
    required this.tileSize,
    super.key,
  });

  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        color: const Color(0xFFCDC1B4).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
