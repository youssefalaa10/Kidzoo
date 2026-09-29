import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One visual difference between the two panels.
@immutable
class DiffSpot {
  const DiffSpot({
    required this.id,
    required this.fractionLeft,
    required this.fractionRight,
    required this.hitRadius,
    required this.label,
    required this.revealLine,
  });

  final String id;

  /// Where this spot sits in the left panel, as a fraction of the panel.
  final Offset fractionLeft;

  /// Where it sits in the right panel. Usually the same place; different
  /// when the difference *is* that something moved.
  final Offset fractionRight;

  /// How close a tap must land, as a fraction of the panel side.
  final double hitRadius;

  /// Named in the banner once the child has needed help, so the second hint
  /// says what to look for rather than only that something is there.
  final LocalizedText label;

  /// Spoken when this one is found — whichever step it is found on.
  final LocalizedText revealLine;
}

/// Everything `spot_the_diff` needs, parsed.
///
/// Both panels are drawn **square**, so authored fractions land on the same
/// pixel of the picture at every board size. An image that is not square is
/// squashed rather than cropped: a crop would silently move every spot.
@immutable
class SpotDiffContent extends ActivityContent {
  const SpotDiffContent({
    required this.spots,
    required this.imageLeft,
    required this.imageRight,
    this.accentColorValue,
  });

  /// In authored order, which is also the order hints walk through them.
  final List<DiffSpot> spots;

  /// The reference scene.
  final String imageLeft;

  /// The scene with the differences in it.
  final String imageRight;

  final int? accentColorValue;

  Iterable<String> get assetPaths => <String>[imageLeft, imageRight];

  DiffSpot? spotNamed(String id) {
    for (final DiffSpot spot in spots) {
      if (spot.id == id) {
        return spot;
      }
    }
    return null;
  }
}

/// Parses and validates a `spot_the_diff` payload.
SpotDiffContent parseSpotDiffContent(ActivitySpec spec) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final String imageLeft = reader.requireString('imageLeft');
  final String imageRight = reader.requireString('imageRight');
  if (imageLeft == imageRight) {
    throw ActivityContentException('$path.imageRight',
        'both panels are the same picture, so there is nothing to find');
  }

  final List<Map<String, dynamic>> rawSpots = reader.optionalMapList('spots');
  if (rawSpots.isEmpty) {
    throw ActivityContentException(
        '$path.spots', 'need at least one difference to find');
  }

  final List<DiffSpot> spots = <DiffSpot>[];
  final Set<String> ids = <String>{};
  for (int i = 0; i < rawSpots.length; i++) {
    final Map<String, dynamic> raw = rawSpots[i];
    final String where = '$path.spots[$i]';
    final JsonReader spotReader = JsonReader(raw, where);

    Offset position(String key) {
      final Object? value = raw[key];
      if (value is! List || value.length != 2 || value.any((v) => v is! num)) {
        throw ActivityContentException('$where.$key', 'expected [x, y]');
      }
      final Offset offset = Offset(
          (value[0] as num).toDouble(), (value[1] as num).toDouble());
      if (offset.dx < 0 || offset.dx > 1 || offset.dy < 0 || offset.dy > 1) {
        throw ActivityContentException(
            '$where.$key', 'both values are fractions of the panel, so 0..1');
      }
      return offset;
    }

    final String id = spotReader.requireString('id');
    if (!ids.add(id)) {
      throw ActivityContentException('$where.id', 'duplicate spot id "$id"');
    }
    final double hitRadius = spotReader.optionalDouble('hitRadius') ?? 0.1;
    // Below this a four-year-old finger cannot land it on a phone; above it
    // a tap anywhere near the middle finds something.
    if (hitRadius < 0.05 || hitRadius > 0.2) {
      throw ActivityContentException(
          '$where.hitRadius', 'expected 0.05..0.2 of the panel side');
    }
    final LocalizedText revealLine = LocalizedText.fromJson(raw['revealLine'],
        debugPath: '$where.revealLine');
    if (revealLine.isEmpty) {
      throw ActivityContentException('$where.revealLine',
          'every difference says what it means; a find that tells the child '
          'nothing is a chime, not a clue');
    }
    spots.add(DiffSpot(
      id: id,
      fractionLeft: position('posLeft'),
      fractionRight: position('posRight'),
      hitRadius: hitRadius,
      label: LocalizedText.fromJson(raw['label'], debugPath: '$where.label'),
      revealLine: revealLine,
    ));
  }

  // Two spots whose targets overlap are one tap that counts twice, and the
  // child learns nothing about the second one.
  for (int a = 0; a < spots.length; a++) {
    for (int b = a + 1; b < spots.length; b++) {
      final double reach = spots[a].hitRadius + spots[b].hitRadius;
      if ((spots[a].fractionLeft - spots[b].fractionLeft).distance < reach ||
          (spots[a].fractionRight - spots[b].fractionRight).distance < reach) {
        throw ActivityContentException('$path.spots',
            '"${spots[a].id}" and "${spots[b].id}" overlap, so one tap finds both');
      }
    }
  }

  return SpotDiffContent(
    spots: List<DiffSpot>.unmodifiable(spots),
    imageLeft: imageLeft,
    imageRight: imageRight,
    accentColorValue: _accentValue(spec.presentation.accent),
  );
}

int? _accentValue(String? raw) {
  if (raw == null) {
    return null;
  }
  final String hex = raw.replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return null;
  }
  return int.parse('FF$hex', radix: 16);
}
