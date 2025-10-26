import 'package:flutter/material.dart';

class DrawingData {
  const DrawingData({
    required this.strokes,
    required this.shapes,
    required this.texts,
    required this.canvasSize,
    required this.backgroundColor,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DrawingData.fromJson(Map<String, dynamic> json) {
    return DrawingData(
      strokes: (json['strokes'] as List)
          .map((stroke) => DrawingStroke.fromJson(stroke))
          .toList(),
      shapes: (json['shapes'] as List)
          .map((shape) => DrawingShape.fromJson(shape))
          .toList(),
      texts: (json['texts'] as List)
          .map((text) => DrawingText.fromJson(text))
          .toList(),
      canvasSize: Size(
        json['canvasSize']['width'],
        json['canvasSize']['height'],
      ),
      backgroundColor: Color(json['backgroundColor']),
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
  final List<DrawingStroke> strokes;
  final List<DrawingShape> shapes;
  final List<DrawingText> texts;
  final Size canvasSize;
  final Color backgroundColor;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  DrawingData copyWith({
    List<DrawingStroke>? strokes,
    List<DrawingShape>? shapes,
    List<DrawingText>? texts,
    Size? canvasSize,
    Color? backgroundColor,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DrawingData(
      strokes: strokes ?? this.strokes,
      shapes: shapes ?? this.shapes,
      texts: texts ?? this.texts,
      canvasSize: canvasSize ?? this.canvasSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'shapes': shapes.map((shape) => shape.toJson()).toList(),
      'texts': texts.map((text) => text.toJson()).toList(),
      'canvasSize': {
        'width': canvasSize.width,
        'height': canvasSize.height,
      },
      'backgroundColor': backgroundColor.value,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class DrawingStroke {
  const DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
    required this.tool,
    required this.timestamp,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points: (json['points'] as List)
          .map((point) => Offset(point['x'], point['y']))
          .toList(),
      color: Color(json['color']),
      width: json['width'],
      opacity: json['opacity'],
      tool: json['tool'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  final List<Offset> points;
  final Color color;
  final double width;
  final double opacity;
  final String tool;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
      'color': color.value,
      'width': width,
      'opacity': opacity,
      'tool': tool,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DrawingShape {
  const DrawingShape({
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.width,
    required this.opacity,
    required this.isFilled,
    required this.timestamp,
  });

  factory DrawingShape.fromJson(Map<String, dynamic> json) {
    return DrawingShape(
      type: json['type'],
      startPoint: Offset(json['startPoint']['x'], json['startPoint']['y']),
      endPoint: Offset(json['endPoint']['x'], json['endPoint']['y']),
      color: Color(json['color']),
      width: json['width'],
      opacity: json['opacity'],
      isFilled: json['isFilled'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  final String type;
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double width;
  final double opacity;
  final bool isFilled;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startPoint': {'x': startPoint.dx, 'y': startPoint.dy},
      'endPoint': {'x': endPoint.dx, 'y': endPoint.dy},
      'color': color.value,
      'width': width,
      'opacity': opacity,
      'isFilled': isFilled,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DrawingText {
  const DrawingText({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.timestamp,
  });

  factory DrawingText.fromJson(Map<String, dynamic> json) {
    return DrawingText(
      text: json['text'],
      position: Offset(json['position']['x'], json['position']['y']),
      color: Color(json['color']),
      fontSize: json['fontSize'],
      fontFamily: json['fontFamily'],
      fontWeight: FontWeight.values[json['fontWeight']],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'position': {'x': position.dx, 'y': position.dy},
      'color': color.value,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'fontWeight': fontWeight.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
