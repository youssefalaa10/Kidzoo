import 'package:flutter/material.dart';

class SmartToolBar extends StatelessWidget {
  const SmartToolBar({
    required this.currentTool,
    required this.currentColor,
    required this.currentWidth,
    required this.currentOpacity,
    required this.canUndo,
    required this.canRedo,
    required this.showGrid,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onOpacityChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onSave,
    required this.onShare,
    required this.onToggleGrid,
    required this.onToggleFullscreen,
    super.key,
  });
  final String currentTool;
  final Color currentColor;
  final double currentWidth;
  final double currentOpacity;
  final bool canUndo;
  final bool canRedo;
  final bool showGrid;
  final void Function(String) onToolChanged;
  final void Function(Color) onColorChanged;
  final void Function(double) onWidthChanged;
  final void Function(double) onOpacityChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row - Tools and Actions
          Row(
            children: [
              // Tool selector
              Expanded(
                child: _buildToolSelector(),
              ),
              const SizedBox(width: 12),

              // Quick actions
              _buildQuickActions(),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom row - Color, Width, and Settings
          Row(
            children: [
              // Color picker
              _buildColorPicker(context),
              const SizedBox(width: 12),

              // Width control
              _buildWidthControl(),
              const SizedBox(width: 12),

              // Opacity control
              _buildOpacityControl(),
              const Spacer(),

              // Settings
              _buildSettingsButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getToolIcon(currentTool),
            color: const Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _getToolName(currentTool),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF6B7280),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo
        _buildActionButton(
          icon: Icons.undo,
          color: canUndo ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
          onPressed: canUndo ? onUndo : null,
        ),
        const SizedBox(width: 8),

        // Redo
        _buildActionButton(
          icon: Icons.redo,
          color: canRedo ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
          onPressed: canRedo ? onRedo : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onPressed != null
              ? color.withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showColorPicker(context),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF6B7280),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: currentWidth.clamp(4.0, 20.0),
            height: currentWidth.clamp(4.0, 20.0),
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${currentWidth.toInt()}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpacityControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.opacity,
            color: Color(0xFF6B7280),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${(currentOpacity * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSettingsBottomSheet(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.settings,
          color: Color(0xFF6B7280),
          size: 18,
        ),
      ),
    );
  }

  IconData _getToolIcon(String tool) {
    switch (tool) {
      case 'brush':
        return Icons.brush;
      case 'pencil':
        return Icons.edit;
      case 'eraser':
        return Icons.cleaning_services;
      case 'shape':
        return Icons.category;
      case 'text':
        return Icons.text_fields;
      case 'select':
        return Icons.touch_app;
      default:
        return Icons.brush;
    }
  }

  String _getToolName(String tool) {
    switch (tool) {
      case 'brush':
        return 'Brush';
      case 'pencil':
        return 'Pencil';
      case 'eraser':
        return 'Eraser';
      case 'shape':
        return 'Shape';
      case 'text':
        return 'Text';
      case 'select':
        return 'Select';
      default:
        return 'Brush';
    }
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Colors.black,
                  Colors.white,
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                ].map((color) {
                  final isSelected = color == currentColor;
                  return GestureDetector(
                    onTap: () {
                      onColorChanged(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 24)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tool Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 20),

              // Grid toggle
              ListTile(
                leading: const Icon(Icons.grid_on, color: Color(0xFF6B7280)),
                title: const Text('Show Grid'),
                trailing: Switch(
                  value: showGrid,
                  onChanged: (value) {
                    onToggleGrid();
                    Navigator.pop(context);
                  },
                  activeThumbColor: const Color(0xFF6366F1),
                ),
              ),

              // Width slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brush Width: ${currentWidth.toInt()}px',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Slider(
                      value: currentWidth,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: onWidthChanged,
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),

              // Opacity slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opacity: ${(currentOpacity * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Slider(
                      value: currentOpacity,
                      min: 0.1,
                      divisions: 9,
                      onChanged: onOpacityChanged,
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
