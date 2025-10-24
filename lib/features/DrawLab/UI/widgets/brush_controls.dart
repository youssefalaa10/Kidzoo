import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/logic/drawlab_cubit.dart';
import '../../data/models/drawlab_models.dart';

class BrushControls extends StatelessWidget {
  const BrushControls({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.brushSettings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Brush Type
              _buildBrushTypeSelector(context, state),
              const SizedBox(height: 16),

              // Brush Shape
              _buildBrushShapeSelector(context, state),
              const SizedBox(height: 16),

              // Stroke Width
              _buildStrokeWidthSlider(context, state),
              const SizedBox(height: 16),

              // Opacity
              _buildOpacitySlider(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrushTypeSelector(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.brushType,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: BrushType.values.map((type) {
            final isSelected = state.brushType == type;
            return GestureDetector(
              onTap: () => context.read<DrawLabCubit>().setBrushType(type),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getBrushIcon(type),
                      size: 16,
                      color: isSelected ? Colors.blue : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getBrushName(type, l10n),
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrushShapeSelector(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.brushShape,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: BrushShape.values.map((shape) {
            final isSelected = state.brushShape == shape;
            return Expanded(
              child: GestureDetector(
                onTap: () => context.read<DrawLabCubit>().setBrushShape(shape),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getBrushShapeIcon(shape),
                        size: 20,
                        color: isSelected ? Colors.blue : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getBrushShapeName(shape, l10n),
                        style: TextStyle(
                          color:
                              isSelected ? Colors.blue : Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStrokeWidthSlider(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.strokeWidth,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${state.strokeWidth.toInt()}px',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: state.strokeWidth,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          onChanged: (value) =>
              context.read<DrawLabCubit>().setStrokeWidth(value),
        ),
        // Preview stroke
        Center(
          child: Container(
            height: 4,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Container(
                height: state.strokeWidth.clamp(1.0, 4.0),
                width: 100,
                decoration: BoxDecoration(
                  color: state.currentColor,
                  borderRadius: BorderRadius.circular(state.strokeWidth / 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpacitySlider(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.opacity,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${(state.opacity * 100).toInt()}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: state.opacity,
          divisions: 100,
          onChanged: (value) => context.read<DrawLabCubit>().setOpacity(value),
        ),
        // Preview opacity
        Center(
          child: Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                height: 20,
                width: 100,
                decoration: BoxDecoration(
                  color: state.currentColor.withOpacity(state.opacity),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getBrushIcon(BrushType type) {
    switch (type) {
      case BrushType.pen:
        return Icons.edit;
      case BrushType.marker:
        return Icons.brush;
      case BrushType.pencil:
        return Icons.create;
      case BrushType.eraser:
        return Icons.cleaning_services;
      case BrushType.highlighter:
        return Icons.highlight;
    }
  }

  String _getBrushName(BrushType type, AppLocalizations l10n) {
    switch (type) {
      case BrushType.pen:
        return l10n.pen;
      case BrushType.marker:
        return l10n.marker;
      case BrushType.pencil:
        return l10n.pencil;
      case BrushType.eraser:
        return l10n.eraser;
      case BrushType.highlighter:
        return l10n.highlighter;
    }
  }

  IconData _getBrushShapeIcon(BrushShape shape) {
    switch (shape) {
      case BrushShape.round:
        return Icons.circle;
      case BrushShape.square:
        return Icons.crop_square;
      case BrushShape.calligraphy:
        return Icons.brush;
    }
  }

  String _getBrushShapeName(BrushShape shape, AppLocalizations l10n) {
    switch (shape) {
      case BrushShape.round:
        return l10n.round;
      case BrushShape.square:
        return l10n.square;
      case BrushShape.calligraphy:
        return l10n.calligraphy;
    }
  }
}
