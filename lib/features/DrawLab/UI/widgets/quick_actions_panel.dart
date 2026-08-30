import 'package:flutter/material.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({
    required this.onClose,
    required this.onSave,
    required this.onShare,
    required this.onClear,
    required this.onToggleGrid,
    required this.showGrid,
    super.key,
  });
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onClear;
  final VoidCallback onToggleGrid;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 200,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildActionItem(
                    icon: Icons.save,
                    label: 'Save',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      onSave();
                      onClose();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionItem(
                    icon: Icons.share,
                    label: 'Share',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      onShare();
                      onClose();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionItem(
                    icon: showGrid ? Icons.grid_off : Icons.grid_on,
                    label: showGrid ? 'Hide Grid' : 'Show Grid',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      onToggleGrid();
                      onClose();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionItem(
                    icon: Icons.delete_outline,
                    label: 'Clear',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      onClear();
                      onClose();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
