import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/logic/drawlab_cubit.dart';
import '../data/models/drawlab_models.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/drawing_tools_bottom_sheet.dart';

class DrawLabMobileScreen extends StatefulWidget {
  const DrawLabMobileScreen({super.key});

  @override
  State<DrawLabMobileScreen> createState() => _DrawLabMobileScreenState();
}

class _DrawLabMobileScreenState extends State<DrawLabMobileScreen> {
  Size _canvasSize = const Size(800, 600);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCanvasSize();
    });
  }

  void _updateCanvasSize() {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      _canvasSize = Size(
        screenSize.width,
        screenSize.height - 100,
      );
    } else {
      _canvasSize = Size(
        screenSize.width,
        screenSize.height - 200,
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showToolsBottomSheet(BuildContext context) {
    // Capture the cubit from current context before showing bottom sheet
    final drawLabCubit = context.read<DrawLabCubit>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BlocProvider<DrawLabCubit>.value(
        value: drawLabCubit,
        child: DrawingToolsBottomSheet(
          onClose: () => Navigator.pop(bottomSheetContext),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    final cubit = context.read<DrawLabCubit>();
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions
            ListTile(
              leading: const Icon(Icons.save, color: Colors.blue),
              title: Text(l10n.saveDrawing),
              onTap: () {
                Navigator.pop(context);
                _saveDrawing();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: Text(l10n.exportImage),
              onTap: () {
                Navigator.pop(context);
                _exportDrawing();
              },
            ),
            ListTile(
              leading: Icon(
                cubit.state.isGridVisible ? Icons.grid_off : Icons.grid_on,
                color: Colors.orange,
              ),
              title: Text(
                  cubit.state.isGridVisible ? l10n.hideGrid : l10n.showGrid),
              onTap: () {
                cubit.toggleGrid();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(l10n.clearCanvas),
              onTap: () {
                Navigator.pop(context);
                _showClearConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DrawLabCubit(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).drawLab),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showQuickActions(ctx),
                  tooltip: 'More options',
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateCanvasSize();
                });

                return Stack(
                  children: [
                    // Canvas area - takes full screen
                    Positioned.fill(
                      child: _buildCanvasArea(),
                    ),

                    // Floating tools button
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: _buildToolsButton(context),
                    ),

                    // Quick action buttons
                    Positioned(
                      left: 16,
                      bottom: 80,
                      child: _buildQuickActionButtons(),
                    ),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: _buildBottomToolbar(),
        ),
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExportableDrawingCanvas(
          canvasSize: _canvasSize,
          isScrollable: false,
        ),
      ),
    );
  }

  Widget _buildToolsButton(BuildContext context) {
    return FloatingActionButton.large(
      heroTag: 'tools_fab',
      onPressed: () => _showToolsBottomSheet(context),
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.brush, size: 32, color: Colors.white),
    );
  }

  Widget _buildQuickActionButtons() {
    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Undo
            if (state.canUndo)
              _buildSmallFAB(
                heroTag: 'undo_fab',
                icon: Icons.undo,
                color: Colors.blue,
                onPressed: () => context.read<DrawLabCubit>().undo(),
              ),
            const SizedBox(height: 8),

            // Redo
            if (state.canRedo)
              _buildSmallFAB(
                heroTag: 'redo_fab',
                icon: Icons.redo,
                color: Colors.blue,
                onPressed: () => context.read<DrawLabCubit>().redo(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSmallFAB({
    required String heroTag,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBottomToolbar() {
    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Current tool indicator
              _buildToolIndicator(state),

              // Color picker
              _buildColorPicker(state),

              // Brush size
              _buildBrushSizeControl(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolIndicator(DrawingState state) {
    IconData icon;
    String label;

    switch (state.currentTool) {
      case DrawingTool.brush:
        icon = Icons.brush;
        label = 'Brush';
        break;
      case DrawingTool.pencil:
        icon = Icons.edit;
        label = 'Pencil';
        break;
      case DrawingTool.eraser:
        icon = Icons.cleaning_services;
        label = 'Eraser';
        break;
      case DrawingTool.shape:
        icon = Icons.category;
        label = 'Shape';
        break;
      case DrawingTool.text:
        icon = Icons.text_fields;
        label = 'Text';
        break;
      case DrawingTool.select:
        icon = Icons.touch_app;
        label = 'Select';
        break;
    }

    return Builder(
      builder: (ctx) => InkWell(
        onTap: () => _showToolsBottomSheet(ctx),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(DrawingState state) {
    return Builder(
      builder: (ctx) => InkWell(
        onTap: () => _showColorPicker(ctx, state.currentColor),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: state.currentColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrushSizeControl(DrawingState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: state.strokeWidth.clamp(4.0, 20.0),
              height: state.strokeWidth.clamp(4.0, 20.0),
              decoration: BoxDecoration(
                color: state.currentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${state.strokeWidth.toInt()}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    final cubit = context.read<DrawLabCubit>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                return InkWell(
                  onTap: () {
                    cubit.setColor(color);
                    Navigator.pop(bottomSheetContext);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDrawing() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<DrawLabCubit>();
    final name = await _showSaveDialog();
    if (name != null && name.isNotEmpty) {
      try {
        final filePath = await cubit.saveDrawing(name, _canvasSize);
        if (mounted) {
          if (filePath != null) {
            _showSuccessSnackBar(l10n.drawingSaved);
          } else {
            _showErrorSnackBar(l10n.failedToSave);
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('${l10n.failedToSave}: $e');
        }
      }
    }
  }

  Future<void> _exportDrawing() async {
    final l10n = AppLocalizations.of(context);
    _showSuccessSnackBar(l10n.drawingExported);
  }

  Future<String?> _showSaveDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveDrawing),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterDrawingName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCanvas),
        content: Text(l10n.clearCanvasConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
