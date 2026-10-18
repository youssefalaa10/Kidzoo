import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../../../../core/localization/app_localizations.dart';

class DrawLabScreen extends StatefulWidget {
  const DrawLabScreen({super.key});

  @override
  State<DrawLabScreen> createState() => _DrawLabScreenState();
}

class _DrawLabScreenState extends State<DrawLabScreen>
    with TickerProviderStateMixin {
  // Drawing state
  String _currentTool = 'brush';
  Color _currentColor = const Color(0xFF000000);
  double _currentWidth = 3.0;
  double _currentOpacity = 1.0;
  bool _showGrid = false;
  bool _isFullscreen = false;
  bool _showQuickActions = false;
  bool _hasUnsavedChanges = false;

  // Pen tool state
  bool _penStraightLineMode = false;
  Offset? _straightLineStart;

  // Shape tool state
  String _selectedShape = 'circle';
  double _shapeSize = 50.0;
  bool _shapeFilled = false;
  int? _selectedShapeIndex;

  // Text tool state
  final List<TextItem> _textItems = [];
  int? _selectedTextIndex;

  // Animation controllers
  late AnimationController _toolbarAnimationController;
  late Animation<double> _toolbarAnimation;

  // Drawing data
  final List<Offset> _currentStroke = [];
  final List<List<Offset>> _strokes = [];
  final List<Color> _strokeColors = [];
  final List<double> _strokeWidths = [];
  final List<String> _strokeTools = []; // Track which tool made each stroke
  final List<ShapeItem> _shapes = [];

  /// Strokes taken off by undo, newest last, so redo can put them back.
  final List<_UndoneStroke> _undoneStrokes = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _toolbarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toolbarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toolbarAnimationController,
      curve: Curves.easeInOut,
    ));

    _toolbarAnimationController.forward();
  }

  /// Rubs out any shape or text the eraser passes over.
  ///
  /// The eraser was only ever a stroke: it painted opaque white rectangles
  /// onto the stroke layer. Shapes and text are drawn *after* every stroke, so
  /// no amount of scrubbing could remove them - the eraser marks went
  /// underneath. Shapes and text are objects rather than pixels, so the fix is
  /// to erase the object.
  ///
  /// Returns true when something was removed.
  bool _eraseItemsAt(Offset position) {
    // Match the eraser the child actually sees (drawn at _currentWidth * 2
    // wide) and add a little slack, because aiming precisely is hard for them.
    final reach = _currentWidth + 8;

    final removedShapes = <ShapeItem>[];
    for (final shape in _shapes) {
      final hitRadius = (shape.size / 2) + reach;
      if ((shape.position - position).distance <= hitRadius) {
        removedShapes.add(shape);
      }
    }

    final removedTexts = <TextItem>[];
    for (final item in _textItems) {
      final rect = Rect.fromCenter(
        center: item.position,
        width: (item.text.length * item.fontSize * 0.6) + reach * 2,
        height: (item.fontSize * 1.5) + reach * 2,
      );
      if (rect.contains(position)) removedTexts.add(item);
    }

    if (removedShapes.isEmpty && removedTexts.isEmpty) return false;

    setState(() {
      _shapes.removeWhere(removedShapes.contains);
      _textItems.removeWhere(removedTexts.contains);
      _selectedShapeIndex = null;
      _selectedTextIndex = null;
      _hasUnsavedChanges = true;
    });
    HapticFeedback.selectionClick();
    return true;
  }

  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;

    // The eraser clears objects as well as ink, wherever it lands.
    if (_currentTool == 'eraser') {
      _eraseItemsAt(position);
    }

    // Handle text selection/dragging
    if (_currentTool == 'text') {
      for (int i = 0; i < _textItems.length; i++) {
        final textItem = _textItems[i];
        final textRect = Rect.fromCenter(
          center: textItem.position,
          width: textItem.text.length * textItem.fontSize * 0.6,
          height: textItem.fontSize * 1.5,
        );

        if (textRect.contains(position)) {
          setState(() {
            _selectedTextIndex = i;
            for (var item in _textItems) {
              item.isSelected = false;
            }
            textItem.isSelected = true;
          });
          HapticFeedback.mediumImpact();
          return;
        }
      }
      setState(() {
        _selectedTextIndex = null;
        for (var item in _textItems) {
          item.isSelected = false;
        }
      });
      return;
    }

    // Handle shape tool - single tap to place
    if (_currentTool == 'shape') {
      setState(() {
        _shapes.add(ShapeItem(
          type: _selectedShape,
          position: position,
          size: _shapeSize,
          color: _currentColor,
          filled: _shapeFilled,
          opacity: _currentOpacity,
        ));
      });
      HapticFeedback.mediumImpact();
      return;
    }

    // Handle pen straight line mode
    if (_currentTool == 'pen' && _penStraightLineMode) {
      setState(() {
        _straightLineStart = position;
        _currentStroke.clear();
        _currentStroke.add(position);
      });
      HapticFeedback.mediumImpact();
      return;
    }

    // Handle brush/pencil/eraser
    setState(() {
      _currentStroke.clear();
      _currentStroke.add(position);
    });
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    if (_currentTool == 'eraser') {
      _eraseItemsAt(position);
    }

    // Drag text item
    if (_currentTool == 'text' && _selectedTextIndex != null) {
      setState(() {
        _textItems[_selectedTextIndex!].position = position;
      });
      return;
    }

    // Continue drawing stroke
    if (_currentTool != 'shape' && _currentTool != 'text') {
      setState(() {
        _currentStroke.add(position);
      });
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    final position = details.localFocalPoint;

    // Check if user is trying to resize a shape
    if (_currentTool == 'shape') {
      for (int i = 0; i < _shapes.length; i++) {
        final shape = _shapes[i];
        final distance = (shape.position - position).distance;
        if (distance < shape.size) {
          setState(() {
            _selectedShapeIndex = i;
          });
          HapticFeedback.selectionClick();
          return;
        }
      }
    }

    // Handle drawing gestures
    _onPanStart(DragStartDetails(localPosition: position));
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_selectedShapeIndex != null && _currentTool == 'shape') {
      setState(() {
        final shape = _shapes[_selectedShapeIndex!];
        final newSize = (shape.size * details.scale).clamp(20.0, 200.0);
        _shapes[_selectedShapeIndex!] = ShapeItem(
          type: shape.type,
          position: shape.position,
          size: newSize,
          color: shape.color,
          filled: shape.filled,
          opacity: shape.opacity,
        );
        _hasUnsavedChanges = true;
      });
    } else {
      // Handle drawing gestures
      _onPanUpdate(DragUpdateDetails(
        localPosition: details.localFocalPoint,
        globalPosition: details.focalPoint,
      ));
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_selectedShapeIndex != null) {
      setState(() {
        _selectedShapeIndex = null;
      });
    } else {
      // Handle drawing gestures
      _onPanEnd(DragEndDetails());
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentTool == 'text' || _currentTool == 'shape') {
      return; // These tools don't use strokes
    }

    setState(() {
      _hasUnsavedChanges = true;

      if (_currentStroke.isNotEmpty) {
        // Handle pen straight line mode
        if (_currentTool == 'pen' &&
            _penStraightLineMode &&
            _straightLineStart != null) {
          // Draw straight line from start to end
          _strokes.add([_straightLineStart!, _currentStroke.last]);
          _strokeColors.add(_currentColor.withValues(alpha: _currentOpacity));
          _strokeWidths.add(_currentWidth);
          _strokeTools.add('pen');
          _straightLineStart = null;
        } else {
          // Handle different tools
          switch (_currentTool) {
            case 'brush':
              // Smooth brush stroke
              _strokes.add(List.from(_currentStroke));
              _strokeColors
                  .add(_currentColor.withValues(alpha: _currentOpacity));
              _strokeWidths.add(_currentWidth);
              _strokeTools.add('brush');
              break;
            case 'pen':
              // Sharp pen stroke
              _strokes.add(List.from(_currentStroke));
              _strokeColors.add(
                  _currentColor.withValues(alpha: 1.0)); // Full opacity for pen
              _strokeWidths.add(_currentWidth);
              _strokeTools.add('pen');
              break;
            case 'pencil':
              _strokes.add(List.from(_currentStroke));
              _strokeColors
                  .add(_currentColor.withValues(alpha: _currentOpacity));
              _strokeWidths.add(_currentWidth);
              _strokeTools.add('pencil');
              break;
            case 'eraser':
              // Square eraser - use white color with full opacity
              _strokes.add(List.from(_currentStroke));
              _strokeColors.add(Colors.white);
              _strokeWidths.add(_currentWidth * 2); // Eraser is wider
              _strokeTools.add('eraser');
              break;
          }
        }
        _currentStroke.clear();
        // Drawing something new makes the redo history meaningless.
        _undoneStrokes.clear();
      }
    });
  }

  void _clearCanvas() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).clearCanvas),
        content: Text(AppLocalizations.of(context).clearCanvasConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _strokes.clear();
                _strokeColors.clear();
                _strokeWidths.clear();
                _strokeTools.clear();
                _currentStroke.clear();
                _shapes.clear();
                _textItems.clear();
                _selectedTextIndex = null;
                _hasUnsavedChanges = false;
              });
            },
            child: Text(AppLocalizations.of(context).clear),
          ),
        ],
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
  }

  @override
  void dispose() {
    _toolbarAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).saveDrawing),
        content: Text(AppLocalizations.of(context).saveDrawingConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: Text(AppLocalizations.of(context).exitWithoutSaving,
                style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(AppLocalizations.of(context).saveAndExit),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _saveToGallery();
      return true;
    } else if (result == 'discard') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
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
                      margin: _isFullscreen
                          ? EdgeInsets.zero
                          : const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: _isFullscreen
                            ? BorderRadius.zero
                            : BorderRadius.circular(16),
                        boxShadow: _isFullscreen
                            ? null
                            : const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: _isFullscreen
                            ? BorderRadius.zero
                            : BorderRadius.circular(16),
                        child: GestureDetector(
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onScaleEnd: _onScaleEnd,
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: DrawingPainter(
                                  strokes: _strokes,
                                  strokeColors: _strokeColors,
                                  strokeWidths: _strokeWidths,
                                  strokeTools: _strokeTools,
                                  currentStroke: _currentStroke,
                                  currentColor: _currentColor,
                                  currentWidth: _currentWidth,
                                  currentTool: _currentTool,
                                  showGrid: _showGrid,
                                  shapes: _shapes,
                                ),
                                size: Size.infinite,
                              ),
                              // Render text items
                              ..._textItems.map((textItem) => Positioned(
                                    left: textItem.position.dx -
                                        (textItem.text.length *
                                            textItem.fontSize *
                                            0.3),
                                    top: textItem.position.dy -
                                        (textItem.fontSize * 0.75),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_currentTool == 'text') {
                                          _editTextItem(
                                              _textItems.indexOf(textItem));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: textItem.isSelected
                                            ? BoxDecoration(
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFF6366F1),
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              )
                                            : null,
                                        child: Text(
                                          textItem.text,
                                          style: TextStyle(
                                            color: textItem.color,
                                            fontSize: textItem.fontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
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
                          offset:
                              Offset(0, (1 - _toolbarAnimation.value) * 100),
                          child: Opacity(
                            opacity: _toolbarAnimation.value,
                            child: _buildSmartToolBar(isLandscape),
                          ),
                        );
                      },
                    ),
                ],
              ),

              // Quick Actions Panel
              if (_showQuickActions) _buildQuickActionsPanel(),

              // Exit fullscreen button
              if (_isFullscreen)
                Positioned(
                  top: 40,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFF6366F1),
                    onPressed: _toggleFullscreen,
                    child:
                        const Icon(Icons.fullscreen_exit, color: Colors.white),
                  ),
                ),
            ],
          ),
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
          Text(
            AppLocalizations.of(context).drawLab,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),

          // Quick Actions Button
          IconButton(
            onPressed: _toggleQuickActions,
            icon: AnimatedRotation(
              turns: _showQuickActions ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showQuickActions ? Icons.close : Icons.more_horiz,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),

          // Fullscreen Button
          IconButton(
            onPressed: _toggleFullscreen,
            icon: Icon(
              _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartToolBar(bool isLandscape) {
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
      child: isLandscape
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolSelector(),
                  const SizedBox(width: 12),
                  _buildQuickActions(),
                  const SizedBox(width: 12),
                  _buildColorPicker(),
                  const SizedBox(width: 12),
                  SizedBox(width: 150, child: _buildWidthControl(false)),
                  const SizedBox(width: 12),
                  SizedBox(width: 150, child: _buildOpacityControl(false)),
                  const SizedBox(width: 12),
                  _buildSaveButton(),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row - Tools and Actions
                _buildToolSelector(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildQuickActions()],
                ),
                const SizedBox(height: 12),
                // Bottom row - Color, Width, Opacity, and Save
                Row(
                  children: [
                    // Color picker
                    _buildColorPicker(),
                    const SizedBox(width: 12),
                    // Width control
                    _buildWidthControl(true),
                    const SizedBox(width: 12),
                    // Opacity control
                    _buildOpacityControl(true),
                    const SizedBox(width: 12),
                    // Save to gallery
                    _buildSaveButton(),
                  ],
                ),
              ],
            ),
    );
  }

  /// Every tool, always on screen.
  ///
  /// Switching tools used to mean opening a dropdown dialog, picking, and
  /// waiting for it to close - a modal round trip for the single most frequent
  /// action in a drawing app. The tools are now one row of large, obvious
  /// buttons that show which one is live.
  Widget _buildToolSelector() {
    final l10n = AppLocalizations.of(context);
    final tools = <List<Object>>[
      ['brush', Icons.brush_rounded, l10n.brush],
      ['pen', Icons.create_rounded, l10n.pen],
      ['pencil', Icons.edit_rounded, l10n.pencil],
      ['eraser', Icons.cleaning_services_rounded, l10n.eraser],
      ['shape', Icons.category_rounded, l10n.shape],
      ['text', Icons.text_fields_rounded, l10n.text],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tool in tools) ...[
            _buildToolChip(
              tool[0] as String,
              tool[1] as IconData,
              tool[2] as String,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildToolChip(String tool, IconData icon, String label) {
    final isSelected = _currentTool == tool;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _currentTool = tool);
              // These three need a choice before they can draw anything.
              if (tool == 'shape') {
                _showShapeSelector();
              } else if (tool == 'text') {
                _showTextInput();
              } else if (tool == 'pen') {
                _showPenOptions();
              }
            },
            child: Container(
              // Comfortably past the ~48dp minimum, since small hands are
              // aiming at these constantly.
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Undo
        _buildActionButton(
          icon: Icons.undo_rounded,
          color: _strokes.isNotEmpty
              ? const Color(0xFF3B82F6)
              : const Color(0xFF9CA3AF),
          onPressed: _strokes.isNotEmpty ? _undoStroke : null,
        ),
        const SizedBox(width: 8),

        // Redo
        _buildActionButton(
          icon: Icons.redo_rounded,
          color: _undoneStrokes.isNotEmpty
              ? const Color(0xFF3B82F6)
              : const Color(0xFF9CA3AF),
          onPressed: _undoneStrokes.isNotEmpty ? _redoStroke : null,
        ),
        const SizedBox(width: 8),

        // Clear
        _buildActionButton(
          icon: Icons.delete_outline_rounded,
          color: _strokes.isNotEmpty
              ? const Color(0xFFEF4444)
              : const Color(0xFF9CA3AF),
          onPressed: _strokes.isNotEmpty ? _clearCanvas : null,
        ),
      ],
    );
  }

  /// Undo used to pop `_strokes`, `_strokeColors` and `_strokeWidths` but
  /// leave `_strokeTools` untouched. The painter reads those four lists by the
  /// same index, so a single undo shifted every tool label by one and strokes
  /// started rendering as the wrong tool - an old pen line could suddenly draw
  /// itself as an eraser. All four move together now, and what comes off is
  /// kept so it can be put back.
  void _undoStroke() {
    if (_strokes.isEmpty) return;
    setState(() {
      _undoneStrokes.add(_UndoneStroke(
        points: _strokes.removeLast(),
        color: _strokeColors.removeLast(),
        width: _strokeWidths.removeLast(),
        tool: _strokeTools.isNotEmpty ? _strokeTools.removeLast() : 'brush',
      ));
      _hasUnsavedChanges = true;
    });
    HapticFeedback.selectionClick();
  }

  void _redoStroke() {
    if (_undoneStrokes.isEmpty) return;
    setState(() {
      final entry = _undoneStrokes.removeLast();
      _strokes.add(entry.points);
      _strokeColors.add(entry.color);
      _strokeWidths.add(entry.width);
      _strokeTools.add(entry.tool);
      _hasUnsavedChanges = true;
    });
    HapticFeedback.selectionClick();
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

  Widget _buildColorPicker() {
    return GestureDetector(
      onTap: () => _showColorPicker(),
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
                color: _currentColor,
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

  Widget _buildWidthControl(bool useExpanded) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.line_weight, color: Color(0xFF6B7280), size: 14),
            const SizedBox(width: 4),
            Text(
              '${_currentWidth.toInt()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        Slider(
          value: _currentWidth,
          min: 1.0,
          max: 20.0,
          divisions: 19,
          activeColor: const Color(0xFF6366F1),
          onChanged: (value) {
            setState(() {
              _currentWidth = value;
            });
          },
        ),
      ],
    );
    return useExpanded ? Expanded(child: content) : content;
  }

  Widget _buildOpacityControl(bool useExpanded) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.opacity, color: Color(0xFF6B7280), size: 14),
            const SizedBox(width: 4),
            Text(
              '${(_currentOpacity * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        Slider(
          value: _currentOpacity,
          min: 0.1,
          divisions: 9,
          activeColor: const Color(0xFF6366F1),
          onChanged: (value) {
            setState(() {
              _currentOpacity = value;
            });
          },
        ),
      ],
    );
    return useExpanded ? Expanded(child: content) : content;
  }

  Widget _buildQuickActionsPanel() {
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
                  Text(
                    AppLocalizations.of(context).quickActions,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleQuickActions,
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
                    icon: _showGrid ? Icons.grid_off : Icons.grid_on,
                    label: _showGrid
                        ? AppLocalizations.of(context).hideGrid
                        : AppLocalizations.of(context).showGrid,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      setState(() {
                        _showGrid = !_showGrid;
                      });
                      _toggleQuickActions();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionItem(
                    icon: Icons.delete_outline,
                    label: AppLocalizations.of(context).clear,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      _clearCanvas();
                      _toggleQuickActions();
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

  String _getToolName(BuildContext context, String tool) {
    switch (tool) {
      case 'brush':
        return AppLocalizations.of(context).brush;
      case 'pen':
        return AppLocalizations.of(context).pen;
      case 'pencil':
        return AppLocalizations.of(context).pencil;
      case 'eraser':
        return AppLocalizations.of(context).eraser;
      case 'shape':
        return AppLocalizations.of(context).shape;
      case 'text':
        return AppLocalizations.of(context).text;
      case 'select':
        return AppLocalizations.of(context).select;
      case 'circle':
        return AppLocalizations.of(context).circle;
      case 'square':
        return AppLocalizations.of(context).square;
      case 'rectangle':
        return AppLocalizations.of(context).rectangle;
      case 'triangle':
        return AppLocalizations.of(context).triangle;
      case 'pentagon':
        return AppLocalizations.of(context).pentagon;
      case 'heart':
        return AppLocalizations.of(context).heart;
      case 'diamond':
        return AppLocalizations.of(context).diamond;
      case 'star':
        return AppLocalizations.of(context).star;
      case 'cylinder':
        return AppLocalizations.of(context).cylinder;
      default:
        return AppLocalizations.of(context).brush;
    }
  }

  void _showColorPicker() {
    showModalBottomSheet<void>(
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
              Text(
                AppLocalizations.of(context).chooseColor,
                style: const TextStyle(
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
                  final isSelected = color == _currentColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentColor = color;
                      });
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

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveToGallery,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.save,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context).save,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToGallery() async {
    try {
      // Check if gal has permission
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
        if (!await Gal.hasAccess()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).galleryAccessDenied),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
          return;
        }
      }

      // Create a canvas to render the drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(1080, 1920); // High resolution

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Create painter and draw
      final painter = DrawingPainter(
        strokes: _strokes,
        strokeColors: _strokeColors,
        strokeWidths: _strokeWidths,
        strokeTools: _strokeTools,
        currentStroke: const [],
        currentColor: _currentColor,
        currentWidth: _currentWidth,
        currentTool: _currentTool,
        showGrid: false,
        shapes: _shapes,
      );
      painter.paint(canvas, size);

      // Convert to image
      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to gallery using gal
      await Gal.putImageBytes(
        bytes,
        name: 'drawing_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).drawingSaved),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).failedToSave}: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showShapeSelector() {
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(AppLocalizations.of(context).selectShape),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shape selection grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildShapeOption('circle', Icons.circle_outlined,
                        AppLocalizations.of(context).circle, setDialogState),
                    _buildShapeOption('square', Icons.crop_square,
                        AppLocalizations.of(context).square, setDialogState),
                    _buildShapeOption('rectangle', Icons.crop_16_9,
                        AppLocalizations.of(context).rectangle, setDialogState),
                    _buildShapeOption('triangle', Icons.change_history,
                        AppLocalizations.of(context).triangle, setDialogState),
                    _buildShapeOption('pentagon', Icons.pentagon_outlined,
                        AppLocalizations.of(context).pentagon, setDialogState),
                    _buildShapeOption('heart', Icons.favorite_border,
                        AppLocalizations.of(context).heart, setDialogState),
                    _buildShapeOption('diamond', Icons.diamond_outlined,
                        AppLocalizations.of(context).diamond, setDialogState),
                    _buildShapeOption('star', Icons.star_border,
                        AppLocalizations.of(context).star, setDialogState),
                    _buildShapeOption('cylinder', Icons.view_in_ar_outlined,
                        AppLocalizations.of(context).cylinder, setDialogState),
                  ],
                ),
                const SizedBox(height: 20),

                // Size slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${AppLocalizations.of(context).size}: ${_shapeSize.toInt()}'),
                    Slider(
                      value: _shapeSize,
                      min: 20,
                      max: 150,
                      divisions: 26,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (value) {
                        setDialogState(() {
                          _shapeSize = value;
                        });
                        setState(() {
                          _shapeSize = value;
                        });
                      },
                    ),
                  ],
                ),

                // Filled toggle
                SwitchListTile(
                  title: Text(AppLocalizations.of(context).filled),
                  value: _shapeFilled,
                  activeThumbColor: const Color(0xFF6366F1),
                  onChanged: (value) {
                    setDialogState(() {
                      _shapeFilled = value;
                    });
                    setState(() {
                      _shapeFilled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${_getToolName(context, _selectedShape)} ${AppLocalizations.of(context).select} - ${AppLocalizations.of(context).textAdded}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeOption(
      String shape, IconData icon, String label, StateSetter setDialogState) {
    final isSelected = _selectedShape == shape;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          _selectedShape = shape;
        });
        setState(() {
          _selectedShape = shape;
        });
      },
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPenOptions() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).penOptions),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(AppLocalizations.of(context).straightLineMode),
              subtitle: Text(AppLocalizations.of(context).straightLineModeDesc),
              value: _penStraightLineMode,
              activeThumbColor: const Color(0xFF6366F1),
              onChanged: (value) {
                setState(() {
                  _penStraightLineMode = value;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? AppLocalizations.of(context).straightLineModeEnabled
                        : AppLocalizations.of(context).freehandModeEnabled),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }

  void _showTextInput() {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).addText),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).enterYourText,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  _textItems.add(TextItem(
                    text: textController.text,
                    position: const Offset(200, 200), // Default position
                    color: _currentColor,
                    fontSize: 24.0,
                  ));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).textAdded),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text(AppLocalizations.of(context).add),
          ),
        ],
      ),
    );
  }

  void _editTextItem(int index) {
    final textItem = _textItems[index];
    final textController = TextEditingController(text: textItem.text);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context).editText),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).enterYourText,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _textItems.removeAt(index);
                _selectedTextIndex = null;
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).delete,
                style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                setState(() {
                  textItem.text = textController.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter({
    required this.strokes,
    required this.strokeColors,
    required this.strokeWidths,
    required this.strokeTools,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
    required this.showGrid,
    required this.shapes,
  });
  final List<List<Offset>> strokes;
  final List<Color> strokeColors;
  final List<double> strokeWidths;
  final List<String> strokeTools;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;
  final String currentTool;
  final bool showGrid;
  final List<ShapeItem> shapes;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw completed strokes
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].isNotEmpty) {
        final isEraser = i < strokeTools.length && strokeTools[i] == 'eraser';

        final paint = Paint()
          ..color = strokeColors[i] // Color already has opacity applied
          ..strokeWidth = strokeWidths[i]
          ..style = PaintingStyle.stroke
          ..strokeCap = isEraser ? StrokeCap.square : StrokeCap.round
          ..strokeJoin = isEraser ? StrokeJoin.miter : StrokeJoin.round;

        if (isEraser) {
          // Draw eraser as rectangles for clear removal
          for (int j = 0; j < strokes[i].length; j++) {
            final rect = Rect.fromCenter(
              center: strokes[i][j],
              width: strokeWidths[i],
              height: strokeWidths[i],
            );
            canvas.drawRect(rect, paint..style = PaintingStyle.fill);
          }
        } else {
          // Draw normal strokes
          final path = Path();
          path.moveTo(strokes[i][0].dx, strokes[i][0].dy);
          for (int j = 1; j < strokes[i].length; j++) {
            path.lineTo(strokes[i][j].dx, strokes[i][j].dy);
          }
          canvas.drawPath(path, paint);
        }
      }
    }

    // Draw current stroke
    if (currentStroke.isNotEmpty) {
      final isEraser = currentTool == 'eraser';

      final paint = Paint()
        ..color = currentColor // Use current color as is
        ..strokeWidth = currentWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = isEraser ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = isEraser ? StrokeJoin.miter : StrokeJoin.round;

      if (isEraser) {
        // Draw current eraser stroke as rectangles
        for (int i = 0; i < currentStroke.length; i++) {
          final rect = Rect.fromCenter(
            center: currentStroke[i],
            width: currentWidth,
            height: currentWidth,
          );
          canvas.drawRect(
              rect,
              paint
                ..style = PaintingStyle.fill
                ..color = Colors.white);
        }
      } else {
        // Draw normal current stroke
        final path = Path();
        path.moveTo(currentStroke[0].dx, currentStroke[0].dy);
        for (int i = 1; i < currentStroke.length; i++) {
          path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // Draw shapes
    for (final shape in shapes) {
      _drawShape(canvas, shape);
    }
  }

  void _drawShape(Canvas canvas, ShapeItem shape) {
    final paint = Paint()
      ..color = shape.color.withValues(alpha: shape.opacity)
      ..style = shape.filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = shape.position;
    final size = shape.size;

    switch (shape.type) {
      case 'circle':
        canvas.drawCircle(center, size / 2, paint);
        break;
      case 'square':
      case 'rectangle':
        final rect = Rect.fromCenter(
          center: center,
          width: size,
          height: shape.type == 'square' ? size : size * 0.6,
        );
        canvas.drawRect(rect, paint);
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx - size / 2, center.dy + size / 2)
          ..lineTo(center.dx + size / 2, center.dy + size / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'pentagon':
        _drawPolygon(canvas, center, size / 2, 5, paint);
        break;
      case 'heart':
        _drawHeart(canvas, center, size, paint);
        break;
      case 'diamond':
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy)
          ..lineTo(center.dx, center.dy + size / 2)
          ..lineTo(center.dx - size / 2, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'star':
        _drawStar(canvas, center, size / 2, paint);
        break;
      case 'cylinder':
        _drawCylinder(canvas, center, size, paint);
        break;
    }
  }

  void _drawPolygon(
      Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * 3.14159) / sides - 3.14159 / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * 3.14159) / 5 - 3.14159 / 2;
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size / 4);

    path.cubicTo(
      center.dx - size / 2,
      center.dy - size / 4,
      center.dx - size / 2,
      center.dy - size / 2,
      center.dx,
      center.dy - size / 6,
    );

    path.cubicTo(
      center.dx + size / 2,
      center.dy - size / 2,
      center.dx + size / 2,
      center.dy - size / 4,
      center.dx,
      center.dy + size / 4,
    );

    canvas.drawPath(path, paint);
  }

  void _drawCylinder(Canvas canvas, Offset center, double size, Paint paint) {
    // Top ellipse
    final topRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - size / 3),
      width: size,
      height: size / 3,
    );
    canvas.drawOval(topRect, paint);

    // Bottom ellipse
    final bottomRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size / 3),
      width: size,
      height: size / 3,
    );
    canvas.drawOval(bottomRect, paint);

    // Sides
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy - size / 3),
      Offset(center.dx - size / 2, center.dy + size / 3),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size / 2, center.dy - size / 3),
      Offset(center.dx + size / 2, center.dy + size / 3),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    const gridSize = 20.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data classes for shapes and text
class ShapeItem {
  ShapeItem({
    required this.type,
    required this.position,
    required this.size,
    required this.color,
    required this.filled,
    required this.opacity,
  });
  final String type;
  final Offset position;
  final double size;
  final Color color;
  final bool filled;
  final double opacity;
}

class TextItem {
  TextItem({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    this.isSelected = false,
  });
  String text;
  Offset position;
  final Color color;
  final double fontSize;
  bool isSelected;
}

/// A stroke removed by undo, held so redo can put it back exactly as it was.
class _UndoneStroke {
  const _UndoneStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final String tool;
}
