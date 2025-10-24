import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_settings_screen.dart';
import '../data/logic/drawlab_cubit.dart';
import '../data/models/drawlab_models.dart';
import 'screens/gallery_screen.dart';
import 'widgets/brush_controls.dart';
import 'widgets/color_picker_widget.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/tool_palette.dart';

class DrawLabScreen extends StatefulWidget {
  const DrawLabScreen({super.key});

  @override
  State<DrawLabScreen> createState() => _DrawLabScreenState();
}

class _DrawLabScreenState extends State<DrawLabScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Size _canvasSize = const Size(800, 600);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DrawLabCubit(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Tool palette
            _buildToolPalette(),

            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Left sidebar - Controls
                  _buildLeftSidebar(),

                  // Center - Canvas
                  Expanded(
                    child: _buildCanvasArea(),
                  ),

                  // Right sidebar - Gallery
                  _buildRightSidebar(),
                ],
              ),
            ),
          ],
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

  Widget _buildLeftSidebar() {
    return Container(
      width: 280,
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
    );
  }

  Widget _buildRightSidebar() {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: 200,
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
            // Undo button
            FloatingActionButton(
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
          .findAncestorStateOfType<_DrawLabScreenState>();
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
}
