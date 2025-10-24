import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/localization/language_settings_screen.dart';
import 'package:kidzoo/features/DrawLab/UI/screens/gallery_screen.dart';
import 'package:kidzoo/features/DrawLab/UI/widgets/brush_controls.dart';
import 'package:kidzoo/features/DrawLab/UI/widgets/color_picker_widget.dart';
import 'package:kidzoo/features/DrawLab/UI/widgets/drawing_canvas.dart';
import 'package:kidzoo/features/DrawLab/UI/widgets/tool_palette.dart';
import 'package:kidzoo/features/DrawLab/data/logic/drawlab_cubit.dart';
import 'package:kidzoo/features/DrawLab/data/models/drawlab_models.dart';

import 'drawlab_mobile_screen.dart';

class DrawLabScreen extends StatelessWidget {
  const DrawLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use mobile-optimized version for all devices
    return const DrawLabMobileScreen();
  }
}

// Old desktop version kept for reference
class _OldDrawLabScreen extends StatefulWidget {
  const _OldDrawLabScreen({super.key});

  @override
  State<_OldDrawLabScreen> createState() => _OldDrawLabScreenState();
}

class _OldDrawLabScreenState extends State<_OldDrawLabScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Size _canvasSize = const Size(800, 600);
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCanvasSize();
    });
  }

  void _updateCanvasSize() {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      // In landscape, use more horizontal space and allow for larger canvas
      _canvasSize = Size(
        (screenSize.width * 0.5).clamp(800.0, 1600.0),
        (screenSize.height * 0.8).clamp(500.0, 1000.0),
      );
    } else {
      // In portrait, use more vertical space
      _canvasSize = Size(
        (screenSize.width * 0.95).clamp(400.0, 800.0),
        (screenSize.height * 0.6).clamp(500.0, 1000.0),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return BlocProvider(
      create: (context) => DrawLabCubit(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Update canvas size when layout changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateCanvasSize();
            });

            return Column(
              children: [
                // Tool palette
                _buildToolPalette(),

                // Main content area
                Expanded(
                  child: orientation == Orientation.landscape
                      ? _buildLandscapeLayout()
                      : _buildPortraitLayout(),
                ),
              ],
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButtons(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context);

    return AppBar(
      title: Text(l10n.drawLab),
      backgroundColor: Colors.blue.shade50,
      actions: [
        // Language toggle
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const LanguageSettingsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.language),
          tooltip: 'Language Settings',
        ),

        // Grid toggle
        BlocBuilder<DrawLabCubit, DrawingState>(
          builder: (context, state) {
            return IconButton(
              onPressed: () => context.read<DrawLabCubit>().toggleGrid(),
              icon: Icon(
                state.isGridVisible ? Icons.grid_on : Icons.grid_off,
              ),
              tooltip:
                  state.isGridVisible ? l10n.hideGrid : l10n.showGridTooltip,
            );
          },
        ),

        // Export button
        PopupMenuButton<String>(
          onSelected: _handleExportAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'save',
              child: ListTile(
                leading: const Icon(Icons.save),
                title: Text(l10n.saveDrawing),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: const Icon(Icons.download),
                title: Text(l10n.exportImage),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'gallery',
              child: ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.openGallery),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildToolPalette() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: const ToolPalette(),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left sidebar - Controls (wider in landscape)
        _buildLeftSidebar(320),

        // Center - Canvas with scrollable area
        Expanded(
          child: _buildCanvasArea(),
        ),

        // Right sidebar - Gallery (narrower in landscape)
        _buildRightSidebar(200),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Canvas area (larger in portrait)
        Expanded(
          flex: 3,
          child: _buildCanvasArea(),
        ),

        // Bottom controls
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Left controls
              Expanded(
                flex: 2,
                child: _buildLeftSidebar(0),
              ),

              // Right gallery
              Expanded(
                child: _buildRightSidebar(0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftSidebar(double width) {
    return Container(
      width: width > 0 ? width : null,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          // Tools tab
          _buildToolsTab(),
          // Gallery tab
          _buildGalleryTab(),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Brush controls
          BrushControls(),
          SizedBox(height: 16),

          // Color picker
          ColorPickerWidget(),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    return const GalleryScreen();
  }

  Widget _buildCanvasArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.3,
          maxScale: 4.0,
          onInteractionUpdate: (details) {
            setState(() {
              _zoomLevel = details.scale;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ExportableDrawingCanvas(
                canvasSize: _canvasSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightSidebar(double width) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: width > 0 ? width : null,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: const Icon(Icons.build), text: l10n.tools),
                Tab(icon: const Icon(Icons.photo_library), text: l10n.gallery),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildToolsTab(),
                _buildGalleryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Zoom in button
            FloatingActionButton(
              heroTag: 'zoom_in',
              onPressed: () => _zoomIn(),
              backgroundColor: Colors.green,
              tooltip: 'Zoom In',
              child: const Icon(Icons.zoom_in, color: Colors.white),
            ),
            const SizedBox(height: 8),

            // Zoom out button
            FloatingActionButton(
              heroTag: 'zoom_out',
              onPressed: () => _zoomOut(),
              backgroundColor: Colors.orange,
              tooltip: 'Zoom Out',
              child: const Icon(Icons.zoom_out, color: Colors.white),
            ),
            const SizedBox(height: 8),

            // Reset zoom button
            FloatingActionButton(
              heroTag: 'reset_zoom',
              onPressed: () => _resetZoom(),
              backgroundColor: Colors.purple,
              tooltip: 'Reset Zoom',
              child: const Icon(Icons.center_focus_strong, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Undo button
            FloatingActionButton(
              heroTag: 'undo',
              onPressed: state.canUndo
                  ? () => context.read<DrawLabCubit>().undo()
                  : null,
              backgroundColor:
                  state.canUndo ? Colors.blue : Colors.grey.shade300,
              tooltip: l10n.undoTooltip,
              child: const Icon(Icons.undo, color: Colors.white),
            ),
            const SizedBox(height: 8),

            // Redo button
            FloatingActionButton(
              heroTag: 'redo',
              onPressed: state.canRedo
                  ? () => context.read<DrawLabCubit>().redo()
                  : null,
              backgroundColor:
                  state.canRedo ? Colors.blue : Colors.grey.shade300,
              tooltip: l10n.redoTooltip,
              child: const Icon(Icons.redo, color: Colors.white),
            ),
            const SizedBox(height: 8),

            // Clear button
            FloatingActionButton(
              heroTag: 'clear',
              onPressed:
                  state.hasContent ? () => _showClearConfirmation() : null,
              backgroundColor:
                  state.hasContent ? Colors.red : Colors.grey.shade300,
              tooltip: l10n.clearCanvasTooltip,
              child: const Icon(Icons.clear, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  void _handleExportAction(String action) async {
    switch (action) {
      case 'save':
        await _saveDrawing();
        break;
      case 'export':
        await _exportDrawing();
        break;
      case 'gallery':
        _tabController.animateTo(1);
        break;
    }
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
    try {
      // Get the canvas widget and export it
      final canvasWidget = _scaffoldKey.currentContext!
          .findAncestorStateOfType<_OldDrawLabScreenState>();
      if (canvasWidget != null) {
        // Export logic would go here
        _showSuccessSnackBar(l10n.drawingExported);
      }
    } catch (e) {
      _showErrorSnackBar('${l10n.failedToExport}: $e');
    }
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

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.2).clamp(0.3, 4.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.2).clamp(0.3, 4.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }
}
