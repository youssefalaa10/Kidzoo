import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../models/drawlab_models.dart';

class DrawLabCubit extends Cubit<DrawingState> {
  DrawLabCubit() : super(DrawingState.initial()) {
    _saveToHistory();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Change the current drawing tool
  void setTool(DrawingTool tool) {
    emit(state.copyWith(currentTool: tool));
  }

  /// Change the current color
  void setColor(Color color) {
    emit(state.copyWith(currentColor: color));
  }

  /// Change stroke width
  void setStrokeWidth(double width) {
    emit(state.copyWith(strokeWidth: width.clamp(1.0, 50.0)));
  }

  /// Change opacity
  void setOpacity(double opacity) {
    emit(state.copyWith(opacity: opacity.clamp(0.0, 1.0)));
  }

  /// Change brush type
  void setBrushType(BrushType brushType) {
    emit(state.copyWith(brushType: brushType));
  }

  /// Change brush shape
  void setBrushShape(BrushShape brushShape) {
    emit(state.copyWith(brushShape: brushShape));
  }

  /// Set selected shape type
  void setSelectedShape(ShapeType shapeType) {
    emit(state.copyWith(selectedShape: shapeType));
  }

  /// Toggle grid visibility
  void toggleGrid() {
    emit(state.copyWith(isGridVisible: !state.isGridVisible));
  }

  /// Toggle snap to grid
  void toggleSnapToGrid() {
    emit(state.copyWith(isSnapToGrid: !state.isSnapToGrid));
  }

  /// Start a new stroke
  void startStroke(Offset point) {
    if (state.currentTool == DrawingTool.brush ||
        state.currentTool == DrawingTool.pencil ||
        state.currentTool == DrawingTool.eraser) {
      // Set brush type based on tool
      BrushType brushType = state.brushType;
      if (state.currentTool == DrawingTool.pencil) {
        brushType = BrushType.pencil;
      } else if (state.currentTool == DrawingTool.brush) {
        brushType = BrushType.pen;
      }

      final newStroke = DrawingStroke(
        points: [point],
        color: state.currentTool == DrawingTool.eraser
            ? Colors.transparent
            : state.currentColor,
        strokeWidth: state.currentTool == DrawingTool.pencil
            ? state.strokeWidth * 0.7 // Pencil is slightly thinner
            : state.strokeWidth,
        opacity: state.currentTool == DrawingTool.eraser ? 1.0 : state.opacity,
        brushType: brushType,
        blendMode: state.currentTool == DrawingTool.eraser
            ? ui.BlendMode.clear
            : ui.BlendMode.srcOver,
      );

      final newStrokes = List<DrawingStroke>.from(state.strokes)
        ..add(newStroke);
      emit(state.copyWith(strokes: newStrokes));
    }
  }

  /// Update current stroke
  void updateStroke(Offset point) {
    if (state.strokes.isNotEmpty) {
      final lastStroke = state.strokes.last;
      final updatedPoints = List<Offset>.from(lastStroke.points)..add(point);

      final updatedStroke = lastStroke.copyWith(points: updatedPoints);
      final newStrokes = List<DrawingStroke>.from(state.strokes);
      newStrokes[newStrokes.length - 1] = updatedStroke;

      emit(state.copyWith(strokes: newStrokes));
    }
  }

  /// End current stroke
  void endStroke() {
    _saveToHistory();
  }

  /// Start drawing a shape
  void startShape(Offset point, ShapeType shapeType) {
    if (state.currentTool == DrawingTool.shape) {
      final newShape = DrawingShape(
        type: shapeType,
        startPoint: point,
        endPoint: point,
        color: state.currentColor,
        strokeWidth: state.strokeWidth,
        opacity: state.opacity,
      );

      final newShapes = List<DrawingShape>.from(state.shapes)..add(newShape);
      emit(state.copyWith(shapes: newShapes, currentShape: newShape));
    }
  }

  /// Update current shape
  void updateShape(Offset point) {
    if (state.currentShape != null) {
      final updatedShape = state.currentShape!.copyWith(endPoint: point);
      final newShapes = List<DrawingShape>.from(state.shapes);
      final index = newShapes.indexOf(state.currentShape!);
      if (index != -1) {
        newShapes[index] = updatedShape;
        emit(state.copyWith(shapes: newShapes, currentShape: updatedShape));
      }
    }
  }

  /// End current shape
  void endShape() {
    emit(state.copyWith());
    _saveToHistory();
  }

  /// Add text to canvas
  void addText(Offset position, String text) {
    if (text.isNotEmpty) {
      final newText = DrawingText(
        text: text,
        position: position,
        color: state.currentColor,
        fontSize: state.strokeWidth * 2, // Scale font size with stroke width
      );

      final newTexts = List<DrawingText>.from(state.texts)..add(newText);
      emit(state.copyWith(texts: newTexts));
      _saveToHistory();
    }
  }

  /// Update text
  void updateText(DrawingText oldText, String newText) {
    if (newText.isNotEmpty) {
      final updatedText = oldText.copyWith(text: newText);
      final newTexts = List<DrawingText>.from(state.texts);
      final index = newTexts.indexOf(oldText);
      if (index != -1) {
        newTexts[index] = updatedText;
        emit(state.copyWith(texts: newTexts));
        _saveToHistory();
      }
    }
  }

  /// Delete text
  void deleteText(DrawingText text) {
    final newTexts = List<DrawingText>.from(state.texts)..remove(text);
    emit(state.copyWith(texts: newTexts));
    _saveToHistory();
  }

  /// Undo last action
  void undo() {
    if (state.canUndo) {
      final newIndex = state.historyIndex - 1;
      final previousState = state.history[newIndex];
      emit(previousState.copyWith(
          historyIndex: newIndex, history: state.history));
    }
  }

  /// Redo last undone action
  void redo() {
    if (state.canRedo) {
      final newIndex = state.historyIndex + 1;
      final nextState = state.history[newIndex];
      emit(nextState.copyWith(historyIndex: newIndex, history: state.history));
    }
  }

  /// Clear the entire canvas
  void clearCanvas() {
    emit(DrawingState.initial());
    _saveToHistory();
  }

  /// Save current state to history
  void _saveToHistory() {
    final newHistory = List<DrawingState>.from(state.history);

    // Remove any states after current index (when undoing and then making new changes)
    if (state.historyIndex < newHistory.length - 1) {
      newHistory.removeRange(state.historyIndex + 1, newHistory.length);
    }

    // Add current state
    newHistory.add(state);

    // Limit history size to 50 states
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }

    final newIndex = newHistory.length - 1;
    emit(state.copyWith(history: newHistory, historyIndex: newIndex));
  }

  /// Export canvas as image
  Future<Uint8List?> exportCanvas(Size canvasSize,
      {ExportQuality quality = ExportQuality.original}) {
    // This will be implemented in the painter
    return Future.value();
  }

  /// Save drawing to device
  Future<String?> saveDrawing(String name, Size canvasSize) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final drawLabDir = Directory('${directory.path}/DrawLab');
      if (!await drawLabDir.exists()) {
        await drawLabDir.create(recursive: true);
      }

      final id = _generateId();
      final fileName = '${name.replaceAll(' ', '_')}_$id.png';
      final filePath = '${drawLabDir.path}/$fileName';

      // Create thumbnail directory
      final thumbnailDir = Directory('${drawLabDir.path}/thumbnails');
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // final thumbnailPath = '${thumbnailDir.path}/thumb_$fileName';

      // Save the drawing (implementation will be in the painter)
      // For now, return the file path
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Load saved drawings
  Future<List<SavedDrawing>> loadSavedDrawings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final drawLabDir = Directory('${directory.path}/DrawLab');

      if (!await drawLabDir.exists()) {
        return [];
      }

      final files = await drawLabDir.list().toList();
      final drawings = <SavedDrawing>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          final fileName = file.path.split('/').last;
          final name = fileName.split('_').first.replaceAll('_', ' ');
          final id = fileName.split('_').last.replaceAll('.png', '');

          final thumbnailFile =
              File('${drawLabDir.path}/thumbnails/thumb_$fileName');

          drawings.add(SavedDrawing(
            id: id,
            name: name,
            filePath: file.path,
            thumbnailPath: thumbnailFile.path,
            createdAt: await file.lastModified(),
            canvasSize: const Size(800, 600), // Default size
          ));
        }
      }

      // Sort by creation date (newest first)
      drawings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return drawings;
    } catch (e) {
      return [];
    }
  }

  /// Share drawing
  Future<void> shareDrawing(String filePath) async {
    try {
      // For now, just show a message - share functionality can be added later
      print('Sharing drawing: $filePath');
    } catch (e) {
      // Handle error
    }
  }

  /// Delete saved drawing
  Future<bool> deleteDrawing(SavedDrawing drawing) async {
    try {
      final file = File(drawing.filePath);
      final thumbnailFile = File(drawing.thumbnailPath);

      if (await file.exists()) {
        await file.delete();
      }
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rename saved drawing
  Future<bool> renameDrawing(SavedDrawing drawing, String newName) async {
    try {
      final oldFile = File(drawing.filePath);
      final oldThumbnailFile = File(drawing.thumbnailPath);

      final newFileName = '${newName.replaceAll(' ', '_')}_${drawing.id}.png';
      final newFilePath =
          oldFile.path.replaceAll(oldFile.path.split('/').last, newFileName);
      final newThumbnailPath = oldThumbnailFile.path.replaceAll(
          oldThumbnailFile.path.split('/').last, 'thumb_$newFileName');

      await oldFile.rename(newFilePath);
      await oldThumbnailFile.rename(newThumbnailPath);

      return true;
    } catch (e) {
      return false;
    }
  }
}
