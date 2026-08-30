import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Represents a drawing stroke
class DrawingStroke {
  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.brushType,
    this.blendMode = ui.BlendMode.srcOver,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final BrushType brushType;
  final ui.BlendMode blendMode;

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    double? opacity,
    BrushType? brushType,
    ui.BlendMode? blendMode,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      brushType: brushType ?? this.brushType,
      blendMode: blendMode ?? this.blendMode,
    );
  }
}

/// Represents a shape on the canvas
class DrawingShape {
  DrawingShape({
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    this.isFilled = false,
    this.fillColor,
  });

  final ShapeType type;
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final bool isFilled;
  final Color? fillColor;

  DrawingShape copyWith({
    ShapeType? type,
    Offset? startPoint,
    Offset? endPoint,
    Color? color,
    double? strokeWidth,
    double? opacity,
    bool? isFilled,
    Color? fillColor,
  }) {
    return DrawingShape(
      type: type ?? this.type,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      isFilled: isFilled ?? this.isFilled,
      fillColor: fillColor ?? this.fillColor,
    );
  }
}

/// Represents text on the canvas
class DrawingText {
  DrawingText({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  });

  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  DrawingText copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
  }) {
    return DrawingText(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
    );
  }
}

/// Represents a saved drawing
class SavedDrawing {
  SavedDrawing({
    required this.id,
    required this.name,
    required this.filePath,
    required this.thumbnailPath,
    required this.createdAt,
    required this.canvasSize,
  });

  final String id;
  final String name;
  final String filePath;
  final String thumbnailPath;
  final DateTime createdAt;
  final Size canvasSize;

  SavedDrawing copyWith({
    String? id,
    String? name,
    String? filePath,
    String? thumbnailPath,
    DateTime? createdAt,
    Size? canvasSize,
  }) {
    return SavedDrawing(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      canvasSize: canvasSize ?? this.canvasSize,
    );
  }
}

/// Brush types
enum BrushType {
  pen,
  marker,
  pencil,
  eraser,
  highlighter,
}

/// Shape types
enum ShapeType {
  line,
  rectangle,
  circle,
  triangle,
  arrow,
}

/// Drawing tool types
enum DrawingTool {
  brush,
  pencil,
  eraser,
  shape,
  text,
  select,
}

/// Export quality levels
enum ExportQuality {
  original,
  high2x,
  high3x,
}

/// Brush shape options
enum BrushShape {
  round,
  square,
  calligraphy,
}

/// Drawing state
class DrawingState {
  /// Create initial state
  factory DrawingState.initial() {
    return DrawingState(
      strokes: [],
      shapes: [],
      texts: [],
      currentTool: DrawingTool.brush,
      currentColor: Colors.black,
      strokeWidth: 3.0,
      opacity: 1.0,
      brushType: BrushType.pen,
      brushShape: BrushShape.round,
      isGridVisible: false,
      isSnapToGrid: false,
    );
  }
  DrawingState({
    required this.strokes,
    required this.shapes,
    required this.texts,
    required this.currentTool,
    required this.currentColor,
    required this.strokeWidth,
    required this.opacity,
    required this.brushType,
    required this.brushShape,
    required this.isGridVisible,
    required this.isSnapToGrid,
    this.selectedShape,
    this.currentShape,
    this.selectedText,
    this.historyIndex = -1,
    this.history = const [],
  });

  final List<DrawingStroke> strokes;
  final List<DrawingShape> shapes;
  final List<DrawingText> texts;
  final DrawingTool currentTool;
  final Color currentColor;
  final double strokeWidth;
  final double opacity;
  final BrushType brushType;
  final BrushShape brushShape;
  final bool isGridVisible;
  final bool isSnapToGrid;
  final ShapeType? selectedShape;
  final DrawingShape? currentShape;
  final DrawingText? selectedText;
  final int historyIndex;
  final List<DrawingState> history;

  // Computed properties
  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < history.length - 1;

  int get totalElements => strokes.length + shapes.length + texts.length;

  bool get hasContent =>
      strokes.isNotEmpty || shapes.isNotEmpty || texts.isNotEmpty;

  DrawingState copyWith({
    List<DrawingStroke>? strokes,
    List<DrawingShape>? shapes,
    List<DrawingText>? texts,
    DrawingTool? currentTool,
    Color? currentColor,
    double? strokeWidth,
    double? opacity,
    BrushType? brushType,
    BrushShape? brushShape,
    bool? isGridVisible,
    bool? isSnapToGrid,
    ShapeType? selectedShape,
    DrawingShape? currentShape,
    DrawingText? selectedText,
    int? historyIndex,
    List<DrawingState>? history,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      shapes: shapes ?? this.shapes,
      texts: texts ?? this.texts,
      currentTool: currentTool ?? this.currentTool,
      currentColor: currentColor ?? this.currentColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      brushType: brushType ?? this.brushType,
      brushShape: brushShape ?? this.brushShape,
      isGridVisible: isGridVisible ?? this.isGridVisible,
      isSnapToGrid: isSnapToGrid ?? this.isSnapToGrid,
      selectedShape: selectedShape ?? this.selectedShape,
      currentShape: currentShape ?? this.currentShape,
      selectedText: selectedText ?? this.selectedText,
      historyIndex: historyIndex ?? this.historyIndex,
      history: history ?? this.history,
    );
  }
}

/// Color palette with predefined colors
class ColorPalette {
  static const List<Color> defaultColors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.cyan,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.lime,
  ];

  static const List<Color> pastelColors = [
    Color(0xFFFFE5E5), // Light Pink
    Color(0xFFFFF0E5), // Light Orange
    Color(0xFFFFFFE5), // Light Yellow
    Color(0xFFE5FFE5), // Light Green
    Color(0xFFE5F0FF), // Light Blue
    Color(0xFFF0E5FF), // Light Purple
    Color(0xFFFFE5F0), // Light Rose
    Color(0xFFE5E5E5), // Light Grey
  ];

  static const List<Color> vibrantColors = [
    Color(0xFFFF0000), // Red
    Color(0xFFFF8000), // Orange
    Color(0xFFFFFF00), // Yellow
    Color(0xFF00FF00), // Green
    Color(0xFF0080FF), // Blue
    Color(0xFF8000FF), // Purple
    Color(0xFFFF0080), // Magenta
    Color(0xFF00FFFF), // Cyan
  ];
}
