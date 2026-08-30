import 'package:flutter/material.dart';

import '../../data/model/animal_name_model.dart';

class AnimalImageDraggable extends StatelessWidget {
  const AnimalImageDraggable({
    required this.animal,
    super.key,
  });

  final AnimalNameModel animal;

  static const double _tileSize = 85.0;
  static const double _feedbackSize = 95.0;

  @override
  Widget build(BuildContext context) {
    return Draggable<AnimalNameModel>(
      data: animal,
      childWhenDragging: const SizedBox(
        width: _tileSize,
        height: _tileSize,
      ),
      feedback: _buildImageTile(_feedbackSize, opacity: 0.85),
      child: _buildImageTile(_tileSize, opacity: 1.0),
    );
  }

  Widget _buildImageTile(double size, {required double opacity}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            animal.imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
