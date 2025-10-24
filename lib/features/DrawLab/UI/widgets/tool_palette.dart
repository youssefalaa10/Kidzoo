import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/logic/drawlab_cubit.dart';
import '../../data/models/drawlab_models.dart';

class ToolPalette extends StatelessWidget {
  const ToolPalette({super.key});

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
                l10n.tools,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Drawing tools
              _buildDrawingTools(context, state),
              const SizedBox(height: 16),

              // Shape tools
              _buildShapeTools(context, state),
              const SizedBox(height: 16),

              // Grid controls
              _buildGridControls(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawingTools(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.drawingTools,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildToolButton(
              context,
              DrawingTool.brush,
              Icons.brush,
              l10n.pen,
              state.currentTool == DrawingTool.brush,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              DrawingTool.eraser,
              Icons.cleaning_services,
              l10n.eraser,
              state.currentTool == DrawingTool.eraser,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              DrawingTool.text,
              Icons.text_fields,
              l10n.addText,
              state.currentTool == DrawingTool.text,
            ),
            const SizedBox(width: 8),
            _buildToolButton(
              context,
              DrawingTool.select,
              Icons.open_with,
              l10n.select,
              state.currentTool == DrawingTool.select,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeTools(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shapes,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildShapeButton(
              context,
              ShapeType.line,
              Icons.horizontal_rule,
              l10n.line,
            ),
            const SizedBox(width: 8),
            _buildShapeButton(
              context,
              ShapeType.rectangle,
              Icons.crop_square,
              l10n.rectangle,
            ),
            const SizedBox(width: 8),
            _buildShapeButton(
              context,
              ShapeType.circle,
              Icons.circle_outlined,
              l10n.circle,
            ),
            const SizedBox(width: 8),
            _buildShapeButton(
              context,
              ShapeType.triangle,
              Icons.change_history,
              l10n.triangle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildShapeButton(
              context,
              ShapeType.arrow,
              Icons.arrow_forward,
              l10n.arrow,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridControls(BuildContext context, DrawingState state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.grid,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                context,
                l10n.showGrid,
                Icons.grid_on,
                state.isGridVisible,
                () => context.read<DrawLabCubit>().toggleGrid(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildToggleButton(
                context,
                l10n.snapToGrid,
                Icons.grid_off,
                state.isSnapToGrid,
                () => context.read<DrawLabCubit>().toggleSnapToGrid(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    DrawingTool tool,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<DrawLabCubit>().setTool(tool),
        child: Container(
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
                icon,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeButton(
    BuildContext context,
    ShapeType shapeType,
    IconData icon,
    String label,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          context.read<DrawLabCubit>().setTool(DrawingTool.shape);
          // Store the selected shape type for when drawing starts
          // This would need to be added to the cubit
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action buttons for quick actions
class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Undo button
            FloatingActionButton.small(
              onPressed: state.canUndo
                  ? () => context.read<DrawLabCubit>().undo()
                  : null,
              backgroundColor:
                  state.canUndo ? Colors.blue : Colors.grey.shade300,
              child: const Icon(Icons.undo, color: Colors.white),
            ),

            // Redo button
            FloatingActionButton.small(
              onPressed: state.canRedo
                  ? () => context.read<DrawLabCubit>().redo()
                  : null,
              backgroundColor:
                  state.canRedo ? Colors.blue : Colors.grey.shade300,
              child: const Icon(Icons.redo, color: Colors.white),
            ),

            // Clear button
            FloatingActionButton.small(
              onPressed: state.hasContent
                  ? () => _showClearConfirmation(context)
                  : null,
              backgroundColor:
                  state.hasContent ? Colors.red : Colors.grey.shade300,
              child: const Icon(Icons.clear, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text(
            'Are you sure you want to clear the entire canvas? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DrawLabCubit>().clearCanvas();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
