import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One point the line has to pass through, in order.
///
/// Anchors, not pixels. A figure is defined by the handful of places the line
/// must visit; everything between them is the child's own line. That is what
/// lets one model serve a numbered dot-to-dot, a traced shape and, later, a
/// letter: the three differ only in whether the anchors are numbered and
/// whether the road between them is drawn.
@immutable
class TraceAnchor {
  const TraceAnchor({
    required this.id,
    required this.position,
    this.isCorner = false,
  });

  final String id;

  /// Normalized 0..1 inside the figure's box, so one authored figure is the
  /// same figure on a phone, a tablet and in either orientation.
  final Offset position;

  /// Marks a place the line changes direction, which the board draws larger.
  /// A corner is where a child's hand needs to stop and think.
  final bool isCorner;
}

/// One shape, symbol, numeral or route to draw.
@immutable
class TraceFigure {
  const TraceFigure({
    required this.id,
    required this.anchors,
    required this.label,
    this.isClosed = false,
    this.showNumbers = false,
    this.showGuide = true,
    this.underlayImage,
    this.revealLine,
  });

  final String id;
  final List<TraceAnchor> anchors;

  /// What the child is drawing, in the story's words.
  final LocalizedText label;

  /// Whether the last anchor joins back to the first.
  final bool isClosed;

  /// Numbered anchors: the dot-to-dot reading of the same model.
  final bool showNumbers;

  /// The dotted road between the anchors: the tracing reading.
  ///
  /// Both may be on at once. They are two kinds of help, not two games, and a
  /// child meeting their first figure usually wants both.
  final bool showGuide;

  /// Art shown faintly beneath the figure — the broken thing being mended.
  final String? underlayImage;

  /// Spoken once the figure is whole.
  final LocalizedText? revealLine;

  /// The anchor the child has to reach for the figure to be finished.
  TraceAnchor get lastAnchor => isClosed ? anchors.first : anchors.last;

  /// The full ordered walk, including the closing return.
  List<TraceAnchor> get walk =>
      isClosed ? <TraceAnchor>[...anchors, anchors.first] : anchors;
}

/// Everything `trace_path` needs, parsed.
@immutable
class TraceContent extends ActivityContent {
  const TraceContent({
    required this.figures,
    required this.tolerance,
    this.keepCompleted = false,
    this.accentColorValue,
  });

  final List<TraceFigure> figures;

  /// How near the line has to pass an anchor to count as having reached it, as
  /// a fraction of the figure's short side.
  ///
  /// Generous on purpose. A child aiming for a target and missing it by three
  /// millimetres has not misunderstood the shape; scoring that as wrong
  /// measures their finger, not their thinking.
  final double tolerance;

  /// Whether a finished figure stays on screen while the next one is drawn.
  ///
  /// Off by default, because a set of unrelated shapes drawn in the same box
  /// would just pile up. On when the figures are *one thing* — a route down and
  /// the route back, a constellation joined star by star — where the point is
  /// that the child ends up looking at the whole of what they made rather than
  /// at the last stroke of it.
  final bool keepCompleted;

  final int? accentColorValue;

  Iterable<String> get assetPaths => <String>[
        for (final TraceFigure figure in figures)
          if (figure.underlayImage != null) figure.underlayImage!,
      ];
}

/// How much of [figure] a stroke covered, judged purely.
///
/// Returns the index of the last anchor the stroke reached in order, or -1 if
/// it never even reached the first. Shared by the judge and the board so what
/// the child sees filling in is exactly what gets marked.
int traceProgressOf({
  required TraceFigure figure,
  required List<Offset> stroke,
  required double tolerance,
}) {
  final List<TraceAnchor> walk = figure.walk;
  int reached = -1;
  for (final Offset point in stroke) {
    final int next = reached + 1;
    if (next >= walk.length) {
      break;
    }
    if ((point - walk[next].position).distance <= tolerance) {
      reached = next;
    }
  }
  return reached;
}

/// Reads a `trace_path` payload.
TraceContent parseTraceContent(ActivitySpec spec) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final List<Map<String, dynamic>> rawFigures =
      reader.optionalMapList('figures');
  if (rawFigures.isEmpty) {
    throw ActivityContentException(
        '$path.figures', 'need at least one figure to draw');
  }

  final List<TraceFigure> figures = <TraceFigure>[];
  for (int index = 0; index < rawFigures.length; index++) {
    final Map<String, dynamic> raw = rawFigures[index];
    final String where = '$path.figures[$index]';
    final JsonReader figureReader = JsonReader(raw, where);

    final Object? rawPoints = raw['points'];
    if (rawPoints is! List || rawPoints.length < 2) {
      throw ActivityContentException('$where.points',
          'a figure needs at least two points to be a line');
    }

    final List<TraceAnchor> anchors = <TraceAnchor>[];
    for (int p = 0; p < rawPoints.length; p++) {
      final Object? entry = rawPoints[p];
      if (entry is! List || entry.length < 2) {
        throw ActivityContentException('$where.points[$p]',
            'expected [x, y] as whole percentages of the figure box');
      }
      final double x = (entry[0] as num).toDouble() / 100;
      final double y = (entry[1] as num).toDouble() / 100;
      if (x < 0 || x > 1 || y < 0 || y > 1) {
        throw ActivityContentException('$where.points[$p]',
            'both values are percentages of the box, so 0..100');
      }
      anchors.add(TraceAnchor(
        id: '${figureReader.requireString('id')}_p$p',
        position: Offset(x, y),
        isCorner: entry.length > 2 && entry[2] == 1,
      ));
    }

    figures.add(TraceFigure(
      id: figureReader.requireString('id'),
      anchors: anchors,
      label: LocalizedText.fromJson(raw['label'], debugPath: '$where.label'),
      isClosed: figureReader.optionalBool('closed') ?? false,
      showNumbers: figureReader.optionalBool('showNumbers') ?? false,
      showGuide: figureReader.optionalBool('showGuide') ?? true,
      underlayImage: figureReader.optionalString('underlayImage'),
      revealLine: raw['revealLine'] == null
          ? null
          : LocalizedText.fromJson(raw['revealLine'],
              debugPath: '$where.revealLine'),
    ));
  }

  final double tolerance =
      (reader.optionalDouble('tolerancePercent') ?? 12) / 100;
  if (tolerance <= 0 || tolerance > 0.4) {
    throw ActivityContentException('$path.tolerancePercent',
        'expected a percentage of the figure box between 1 and 40');
  }

  // Anchors closer together than the tolerance cannot be told apart, so the
  // figure would complete itself the moment a finger landed anywhere near.
  for (final TraceFigure figure in figures) {
    for (int a = 1; a < figure.anchors.length; a++) {
      final double gap =
          (figure.anchors[a].position - figure.anchors[a - 1].position).distance;
      if (gap <= tolerance) {
        throw ActivityContentException(
          '$path.figures',
          'figure "${figure.id}" has two points $gap apart, inside the '
          'tolerance of $tolerance — they would be one point to a child',
        );
      }
    }
  }

  return TraceContent(
    figures: figures,
    tolerance: tolerance,
    keepCompleted: reader.optionalBool('keepCompleted') ?? false,
    accentColorValue: _accentValue(spec.presentation.accent),
  );
}

int? _accentValue(String? raw) {
  if (raw == null) {
    return null;
  }
  final String hex = raw.replaceFirst('#', '');
  if (hex.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return null;
  }
  return int.parse('FF$hex', radix: 16);
}
