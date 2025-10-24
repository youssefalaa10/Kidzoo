import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/logic/drawlab_cubit.dart';
import '../../data/models/drawlab_models.dart';
import 'drawing_canvas_painter.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    required this.canvasSize,
    super.key,
    this.gridSize = 20.0,
    this.isScrollable = true,
    this.minSize = const Size(400, 300),
  });

  final Size canvasSize;
  final double gridSize;
  final bool isScrollable;
  final Size minSize;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        final effectiveSize = Size(
          widget.canvasSize.width.clamp(widget.minSize.width, double.infinity),
          widget.canvasSize.height
              .clamp(widget.minSize.height, double.infinity),
        );

        final Widget canvasWidget = GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTapDown: _onTapDown,
          child: Container(
            width: effectiveSize.width,
            height: effectiveSize.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                size: effectiveSize,
                painter: DrawingCanvasPainter(
                  state: state,
                  canvasSize: effectiveSize,
                  gridSize: widget.gridSize,
                ),
              ),
            ),
          ),
        );

        if (widget.isScrollable) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: canvasWidget,
            ),
          );
        }

        return canvasWidget;
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    final cubit = context.read<DrawLabCubit>();
    final localPosition = details.localPosition;

    setState(() {
      _isDrawing = true;
    });

    switch (cubit.state.currentTool) {
      case DrawingTool.brush:
      case DrawingTool.pencil:
      case DrawingTool.eraser:
        cubit.startStroke(localPosition);
        break;
      case DrawingTool.shape:
        cubit.startShape(
            localPosition, cubit.state.selectedShape ?? ShapeType.rectangle);
        break;
      case DrawingTool.text:
        _showTextDialog(localPosition);
        break;
      case DrawingTool.select:
        // Handle selection logic
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    final cubit = context.read<DrawLabCubit>();
    final localPosition = details.localPosition;

    switch (cubit.state.currentTool) {
      case DrawingTool.brush:
      case DrawingTool.pencil:
      case DrawingTool.eraser:
        cubit.updateStroke(localPosition);
        break;
      case DrawingTool.shape:
        cubit.updateShape(localPosition);
        break;
      case DrawingTool.text:
      case DrawingTool.select:
        // No action needed
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    final cubit = context.read<DrawLabCubit>();

    switch (cubit.state.currentTool) {
      case DrawingTool.brush:
      case DrawingTool.pencil:
      case DrawingTool.eraser:
        cubit.endStroke();
        break;
      case DrawingTool.shape:
        cubit.endShape();
        break;
      case DrawingTool.text:
      case DrawingTool.select:
        // No action needed
        break;
    }

    setState(() {
      _isDrawing = false;
    });
  }

  void _onTapDown(TapDownDetails details) {
    final cubit = context.read<DrawLabCubit>();
    final localPosition = details.localPosition;

    if (cubit.state.currentTool == DrawingTool.text) {
      _showTextDialog(localPosition);
    }
  }

  void _showTextDialog(Offset position) {
    final l10n = AppLocalizations.of(context);

    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addText),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.enterText,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (text) {
            if (text.isNotEmpty) {
              context.read<DrawLabCubit>().addText(position, text);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // This will be handled by onSubmitted
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}

/// Canvas with export functionality
class ExportableDrawingCanvas extends StatefulWidget {
  const ExportableDrawingCanvas({
    required this.canvasSize,
    super.key,
    this.gridSize = 20.0,
    this.quality = ExportQuality.original,
    this.isScrollable = true,
    this.minSize = const Size(400, 300),
  });

  final Size canvasSize;
  final double gridSize;
  final ExportQuality quality;
  final bool isScrollable;
  final Size minSize;

  @override
  State<ExportableDrawingCanvas> createState() =>
      _ExportableDrawingCanvasState();
}

class _ExportableDrawingCanvasState extends State<ExportableDrawingCanvas> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _canvasKey,
      child: DrawingCanvas(
        canvasSize: widget.canvasSize,
        gridSize: widget.gridSize,
        isScrollable: widget.isScrollable,
        minSize: widget.minSize,
      ),
    );
  }

  /// Export the canvas as an image
  Future<Uint8List?> exportAsImage() async {
    try {
      final RenderRepaintBoundary boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(
        pixelRatio: _getPixelRatio(),
      );

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  double _getPixelRatio() {
    switch (widget.quality) {
      case ExportQuality.original:
        return 1.0;
      case ExportQuality.high2x:
        return 2.0;
      case ExportQuality.high3x:
        return 3.0;
    }
  }
}
