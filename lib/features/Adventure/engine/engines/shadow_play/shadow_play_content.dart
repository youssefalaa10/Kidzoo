import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One object to place between the light and the wall.
@immutable
class ShadowRound {
  const ShadowRound({
    required this.id,
    required this.item,
    required this.targetPercent,
    required this.startPercent,
    required this.label,
    this.revealLine,
  });

  final String id;

  /// What casts the shadow. Its picture is both the object on the track and,
  /// flattened, the shadow on the wall — so the shadow is recognisably *its*.
  final PackItem item;

  /// Where along the track, as a percentage of the distance from the light to
  /// the wall, the shadow exactly fits the outline.
  final int targetPercent;

  /// Where the object starts. Always well away from the answer, so the round
  /// is never solved before the child touches it.
  final int startPercent;

  final LocalizedText label;
  final LocalizedText? revealLine;

  /// True when the answer is nearer the light than the start, which is the
  /// direction that makes the shadow bigger.
  bool get growsShadow => targetPercent < startPercent;
}

/// A light, a wall, and objects between them.
///
/// The one rule is real optics, simplified to a point light: a shadow's size
/// on the wall is the object's size times (light-to-wall ÷ light-to-object).
/// Nothing in the engine names what the light, the wall or the objects are.
@immutable
class ShadowPlayContent extends ActivityContent {
  const ShadowPlayContent({
    required this.rounds,
    required this.tolerancePercent,
    required this.trackMinPercent,
    required this.trackMaxPercent,
    this.lightImage,
    this.wallImage,
    this.accentColorValue,
  });

  final List<ShadowRound> rounds;

  /// How far from the target, in track percent, still counts. The adaptation
  /// axis: a child who is struggling gets a wider window, not fewer objects.
  final int tolerancePercent;

  /// How close to the light and to the wall the object can go.
  final int trackMinPercent;
  final int trackMaxPercent;

  /// What is shining. Optional; without it the board draws a plain glow.
  final String? lightImage;

  /// What the shadow falls on. Drawn behind the shadow, so whatever is on it
  /// disappears where the shadow lands — which is the point.
  final String? wallImage;

  final int? accentColorValue;

  /// Shadow size as a multiple of its size at the nearest the object can go.
  /// 1.0 at [trackMinPercent], smaller further out.
  double shadowScaleAt(double percent) => trackMinPercent / percent;

  Iterable<String> get assetPaths => <String>[
        if (lightImage != null) lightImage!,
        if (wallImage != null) wallImage!,
        for (final ShadowRound round in rounds) round.item.imageAsset,
      ];
}

/// Parses and validates a `shadow_play` payload.
ShadowPlayContent parseShadowPlayContent(
  ActivitySpec spec,
  ItemPackResolver packs,
) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final ItemPack pack = packs.require(reader.requireString('itemsRef'),
      debugPath: '$path.itemsRef');

  final List<int> track = reader.optionalIntList('trackPercent');
  final int trackMin = track.length == 2 ? track[0] : 20;
  final int trackMax = track.length == 2 ? track[1] : 80;
  if (reader.has('trackPercent') && track.length != 2) {
    throw ActivityContentException(
        '$path.trackPercent', 'expected [nearest, furthest]');
  }
  // Nearer than a tenth of the way and the shadow is ten times the object:
  // off every wall. Further than 95% and it is pressed against the wall with
  // nothing left to change.
  if (trackMin < 10 || trackMin > 40 || trackMax < 60 || trackMax > 95) {
    throw ActivityContentException('$path.trackPercent',
        'nearest must be 10..40 and furthest 60..95, got [$trackMin, $trackMax]');
  }

  final int tolerance = reader.optionalInt('tolerancePercent') ?? 6;
  if (tolerance < 3 || tolerance > 15) {
    throw ActivityContentException(
        '$path.tolerancePercent', 'expected 3..15, got $tolerance');
  }

  final List<Map<String, dynamic>> rawRounds = reader.optionalMapList('rounds');
  if (rawRounds.isEmpty) {
    throw ActivityContentException('$path.rounds', 'need at least one round');
  }
  final List<ShadowRound> rounds = <ShadowRound>[];
  final Set<String> ids = <String>{};
  for (int index = 0; index < rawRounds.length; index++) {
    final String where = '$path.rounds[$index]';
    final JsonReader round = JsonReader(rawRounds[index], where);
    final String id = round.requireString('id');
    if (!ids.add(id)) {
      throw ActivityContentException('$where.id', 'duplicate round id "$id"');
    }
    final String itemId = round.requireString('itemId');
    final PackItem? item = pack.findById(itemId);
    if (item == null) {
      throw ActivityContentException('$where.itemId',
          'pack "${pack.packId}" has no item "$itemId"');
    }
    final int target = round.requireInt('targetPercent');
    if (target < trackMin + tolerance || target > trackMax - tolerance) {
      throw ActivityContentException('$where.targetPercent',
          'must sit at least one tolerance inside the track '
          '(${trackMin + tolerance}..${trackMax - tolerance}), got $target');
    }
    final int start = round.requireInt('startPercent');
    if (start < trackMin || start > trackMax) {
      throw ActivityContentException('$where.startPercent',
          'must be on the track ($trackMin..$trackMax), got $start');
    }
    if ((start - target).abs() <= tolerance * 2) {
      throw ActivityContentException('$where.startPercent',
          'starts within reach of the answer, so the round is solved before '
          'the child touches it');
    }
    final LocalizedText label =
        LocalizedText.fromJson(rawRounds[index]['label'], debugPath: '$where.label');
    if (label.isEmpty) {
      throw ActivityContentException('$where.label',
          'each round says what the shadow has to do');
    }
    rounds.add(ShadowRound(
      id: id,
      item: item,
      targetPercent: target,
      startPercent: start,
      label: label,
      revealLine: rawRounds[index]['revealLine'] == null
          ? null
          : LocalizedText.fromJson(rawRounds[index]['revealLine'],
              debugPath: '$where.revealLine'),
    ));
  }

  // The rule is only discovered if both halves of it are needed. A chapter
  // of rounds that are all "move it closer" teaches "always move it closer".
  if (rounds.length > 1 &&
      (rounds.every((ShadowRound r) => r.growsShadow) ||
          rounds.every((ShadowRound r) => !r.growsShadow))) {
    throw ActivityContentException('$path.rounds',
        'every round moves the same way; at least one must need a bigger '
        'shadow and one a smaller, or the child learns a direction, not a rule');
  }
  for (int index = 1; index < rounds.length; index++) {
    if ((rounds[index].targetPercent - rounds[index - 1].targetPercent).abs() <=
        tolerance * 2) {
      throw ActivityContentException('$path.rounds[$index].targetPercent',
          'lands where the round before it did, so leaving the object where '
          'it was would answer it');
    }
  }

  return ShadowPlayContent(
    rounds: List<ShadowRound>.unmodifiable(rounds),
    tolerancePercent: tolerance,
    trackMinPercent: trackMin,
    trackMaxPercent: trackMax,
    lightImage: reader.optionalString('lightImage'),
    wallImage: reader.optionalString('wallImage'),
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
