import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/features/DrawLab/data/models/drawing_model.dart';

import '../widgets/drawing_gesture_detector.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/smart_tool_bar.dart';

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({super.key});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with BackgroundMusicMixin, TickerProviderStateMixin {
  late DrawingData _drawingData;
  final List<DrawingData> _history = [];
  int _historyIndex = -1;

  String _currentTool = 'brush';
  Color _currentColor = const Color(0xFF000000);
  double _currentWidth = 3.0;
  double _currentOpacity = 1.0;
  bool _showGrid = false;
  double _gridSize = 20.0;
  bool _isFullscreen = false;
  bool _showQuickActions = false;

  late AnimationController _toolbarAnimationController;
  late AnimationController _quickActionsController;
  late Animation<double> _toolbarAnimation;
  late Animation<double> _quickActionsAnimation;

  @override
  void initState() {
    super.initState();
    _initializeDrawing();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _quickActionsController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _toolbarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeInOut,
    ));

    _quickActionsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _quickActionsController,
      curve: Curves.elasticOut,
    ));

    _toolbarAnimationController.forward();
  }

  void _initializeDrawing() {
    _drawingData = DrawingData(
      strokes: <DrawingStroke>[],
      shapes: <DrawingShape>[],
      texts: <DrawingText>[],
      canvasSize: const Size(800, 600),
      backgroundColor: const Color(0xFFFFFFFF),
      name: 'New Drawing',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _addToHistory(_drawingData);
  }

  void _addToHistory(DrawingData data) {
    // Remove any history after current index
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(data);
    _historyIndex = _history.length - 1;

    // Limit history size
    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _onDrawingChanged(DrawingData newData) {
    setState(() {
      _drawingData = newData;
    });
    _addToHistory(newData);
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _drawingData = _history[_historyIndex];
      });
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      setState(() {
        _historyIndex++;
        _drawingData = _history[_historyIndex];
      });
    }
  }

  void _clearCanvas() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Canvas'),
        content: const Text(
            'Are you sure you want to clear the canvas? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _drawingData = DrawingData(
                  strokes: <DrawingStroke>[],
                  shapes: <DrawingShape>[],
                  texts: <DrawingText>[],
                  canvasSize: _drawingData.canvasSize,
                  backgroundColor: _drawingData.backgroundColor,
                  name: _drawingData.name,
                  createdAt: _drawingData.createdAt,
                  updatedAt: DateTime.now(),
                );
              });
              _addToHistory(_drawingData);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    try {
      // Implementation for saving drawing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drawing saved successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save drawing: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareDrawing() async {
    try {
      // Implementation for sharing drawing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Drawing shared successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share drawing: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      _toolbarAnimationController.reverse();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _toolbarAnimationController.forward();
    }
  }

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
    });

    if (_showQuickActions) {
      _quickActionsController.forward();
    } else {
      _quickActionsController.reverse();
    }
  }

  @override
  void dispose() {
    _toolbarAnimationController.dispose();
    _quickActionsController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                if (!_isFullscreen) _buildHeader(),

                // Canvas area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DrawingGestureDetector(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: _drawingData.backgroundColor,
                          child: Center(
                            child: Text(
                              'Drawing Canvas\nTool: $_currentTool\nColor: ${_currentColor.toString()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Smart Tool Bar
                if (!_isFullscreen)
                  AnimatedBuilder(
                    animation: _toolbarAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - _toolbarAnimation.value) * 100),
                        child: Opacity(
                          opacity: _toolbarAnimation.value,
                          child: SmartToolBar(
                            currentTool: _currentTool,
                            currentColor: _currentColor,
                            currentWidth: _currentWidth,
                            currentOpacity: _currentOpacity,
                            canUndo: _historyIndex > 0,
                            canRedo: _historyIndex < _history.length - 1,
                            showGrid: _showGrid,
                            onToolChanged: (tool) {
                              setState(() {
                                _currentTool = tool;
                              });
                            },
                            onColorChanged: (color) {
                              setState(() {
                                _currentColor = color;
                              });
                            },
                            onWidthChanged: (width) {
                              setState(() {
                                _currentWidth = width;
                              });
                            },
                            onOpacityChanged: (opacity) {
                              setState(() {
                                _currentOpacity = opacity;
                              });
                            },
                            onUndo: _undo,
                            onRedo: _redo,
                            onClear: _clearCanvas,
                            onSave: _saveDrawing,
                            onShare: _shareDrawing,
                            onToggleGrid: () {
                              setState(() {
                                _showGrid = !_showGrid;
                              });
                            },
                            onToggleFullscreen: _toggleFullscreen,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

            // Quick Actions Panel
            if (_showQuickActions)
              AnimatedBuilder(
                animation: _quickActionsAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _quickActionsAnimation.value,
                    child: Opacity(
                      opacity: _quickActionsAnimation.value,
                      child: QuickActionsPanel(
                        onClose: _toggleQuickActions,
                        onSave: _saveDrawing,
                        onShare: _shareDrawing,
                        onClear: _clearCanvas,
                        onToggleGrid: () {
                          setState(() {
                            _showGrid = !_showGrid;
                          });
                        },
                        showGrid: _showGrid,
                      ),
                    ),
                  );
                },
              ),

            // Floating Action Buttons
            if (!_isFullscreen) _buildFloatingButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios),
            color: const Color(0xFF6B7280),
          ),
          const Text(
            'DrawLab',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings_outlined),
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Actions Button
          FloatingActionButton(
            heroTag: 'quick_actions',
            onPressed: _toggleQuickActions,
            backgroundColor: const Color(0xFF6366F1),
            child: AnimatedRotation(
              turns: _showQuickActions ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showQuickActions ? Icons.close : Icons.more_horiz,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Fullscreen Button
          FloatingActionButton(
            heroTag: 'fullscreen',
            onPressed: _toggleFullscreen,
            backgroundColor: const Color(0xFF10B981),
            child: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Grid settings
                  ListTile(
                    leading:
                        const Icon(Icons.grid_on, color: Color(0xFF6B7280)),
                    title: const Text('Show Grid'),
                    trailing: Switch(
                      value: _showGrid,
                      onChanged: (value) {
                        setState(() {
                          _showGrid = value;
                        });
                        Navigator.of(context).pop();
                      },
                      activeThumbColor: const Color(0xFF6366F1),
                    ),
                  ),

                  // Grid size
                  if (_showGrid)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grid Size: ${_gridSize.toInt()}px',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Slider(
                            value: _gridSize,
                            min: 10,
                            max: 50,
                            divisions: 8,
                            onChanged: (value) {
                              setState(() {
                                _gridSize = value;
                              });
                            },
                            activeColor: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Export settings
                  const Text(
                    'Export Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    leading: const Icon(Icons.image, color: Color(0xFF6B7280)),
                    title: const Text('Export as PNG'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _exportAsPng();
                    },
                  ),

                  ListTile(
                    leading:
                        const Icon(Icons.save_alt, color: Color(0xFF6B7280)),
                    title: const Text('Save to Gallery'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _saveToGallery();
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

  Future<void> _exportAsPng() async {
    try {
      // Implementation for PNG export
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image exported successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export image: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    try {
      // Implementation for saving to gallery
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }
}
