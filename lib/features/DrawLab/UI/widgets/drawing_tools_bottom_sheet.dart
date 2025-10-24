import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/logic/drawlab_cubit.dart';
import '../../data/models/drawlab_models.dart';

class ShapeSelectionBottomSheet extends StatelessWidget {
  const ShapeSelectionBottomSheet({
    required this.onShapeSelected,
    super.key,
  });
  final void Function(ShapeType) onShapeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select Shape',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Shape options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildShapeOption(
                    context, ShapeType.line, Icons.horizontal_rule, 'Line'),
                _buildShapeOption(context, ShapeType.rectangle,
                    Icons.crop_square, 'Rectangle'),
                _buildShapeOption(context, ShapeType.circle,
                    Icons.radio_button_unchecked, 'Circle'),
                _buildShapeOption(context, ShapeType.triangle,
                    Icons.change_history, 'Triangle'),
                _buildShapeOption(
                    context, ShapeType.arrow, Icons.arrow_forward, 'Arrow'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeOption(
      BuildContext context, ShapeType shapeType, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        onShapeSelected(shapeType);
        Navigator.pop(context);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawingToolsBottomSheet extends StatelessWidget {
  const DrawingToolsBottomSheet({
    required this.onClose,
    super.key,
  });
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Drawing Tools',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tools list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Tools section
                        const Text(
                          'Tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildToolTile(
                          context,
                          icon: Icons.brush,
                          title: 'Brush',
                          subtitle: 'Draw with brush',
                          tool: DrawingTool.brush,
                          isSelected: state.currentTool == DrawingTool.brush,
                          color: Colors.blue,
                        ),

                        _buildToolTile(
                          context,
                          icon: Icons.edit,
                          title: 'Pencil',
                          subtitle: 'Free drawing',
                          tool: DrawingTool.pencil,
                          isSelected: state.currentTool == DrawingTool.pencil,
                          color: Colors.amber,
                        ),

                        _buildToolTile(
                          context,
                          icon: Icons.cleaning_services,
                          title: 'Eraser',
                          subtitle: 'Erase parts',
                          tool: DrawingTool.eraser,
                          isSelected: state.currentTool == DrawingTool.eraser,
                          color: Colors.orange,
                        ),

                        _buildShapeTile(
                          context,
                          icon: Icons.category,
                          title: 'Shapes',
                          subtitle: 'Draw shapes',
                          tool: DrawingTool.shape,
                          isSelected: state.currentTool == DrawingTool.shape,
                          color: Colors.purple,
                        ),

                        _buildToolTile(
                          context,
                          icon: Icons.text_fields,
                          title: 'Text',
                          subtitle: 'Add text',
                          tool: DrawingTool.text,
                          isSelected: state.currentTool == DrawingTool.text,
                          color: Colors.green,
                        ),

                        const SizedBox(height: 24),

                        // Brush settings section
                        const Text(
                          'Brush Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Brush size slider
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Brush Size',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${state.strokeWidth.toInt()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: state.strokeWidth,
                                  min: 1,
                                  max: 50,
                                  divisions: 49,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (value) {
                                    context
                                        .read<DrawLabCubit>()
                                        .setStrokeWidth(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Opacity slider
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Opacity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${(state.opacity * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: state.opacity,
                                  min: 0.1,
                                  divisions: 9,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (value) {
                                    context
                                        .read<DrawLabCubit>()
                                        .setOpacity(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required DrawingTool tool,
    required bool isSelected,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? color.withOpacity(0.7) : Colors.grey,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () {
          context.read<DrawLabCubit>().setTool(tool);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildShapeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required DrawingTool tool,
    required bool isSelected,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? color.withOpacity(0.7) : Colors.grey,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () {
          context.read<DrawLabCubit>().setTool(tool);
          _showShapeSelection(context);
        },
      ),
    );
  }

  void _showShapeSelection(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShapeSelectionBottomSheet(
        onShapeSelected: (shapeType) {
          context.read<DrawLabCubit>().setSelectedShape(shapeType);
          Navigator.pop(context);
        },
      ),
    );
  }
}
