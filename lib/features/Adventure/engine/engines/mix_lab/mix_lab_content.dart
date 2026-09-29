import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One thing that can go into the mix.
@immutable
class MixInk {
  const MixInk({
    required this.id,
    required this.colorValue,
    required this.label,
  });

  final String id;
  final int colorValue;
  final LocalizedText label;
}

/// What a combination of inks makes.
@immutable
class MixResult {
  const MixResult({
    required this.inkIds,
    required this.colorValue,
    required this.label,
  });

  /// Sorted, so a result can be looked up by its set.
  final List<String> inkIds;
  final int colorValue;
  final LocalizedText label;
}

/// One thing to make.
@immutable
class MixRound {
  const MixRound({
    required this.id,
    required this.target,
    required this.label,
    this.revealLine,
  });

  final String id;

  /// The inks that make it, sorted. The board never shows this list — only
  /// the colour it makes — so working it out is the round.
  final List<String> target;

  final LocalizedText label;
  final LocalizedText? revealLine;
}

/// Inks, the complete table of what they make together, and rounds.
///
/// The table is authored, not computed, so the engine holds no theory of
/// colour: it could as well be juices, potions or paints. What it insists on
/// is that the table is **complete** — every combination a child can make is
/// declared — because a child experimenting will make all of them, and one
/// that silently shows nothing is a broken experiment.
@immutable
class MixLabContent extends ActivityContent {
  const MixLabContent({
    required this.inks,
    required this.results,
    required this.rounds,
    required this.emptyColorValue,
    this.vesselImage,
    this.accentColorValue,
  });

  final List<MixInk> inks;

  /// Keyed by the sorted ink ids joined with `+`.
  final Map<String, MixResult> results;

  final List<MixRound> rounds;

  /// The vessel with nothing in it.
  final int emptyColorValue;

  /// A white picture tinted by the mix. Optional; without it, a disc.
  final String? vesselImage;

  final int? accentColorValue;

  static String keyFor(Iterable<String> inkIds) =>
      (inkIds.toList()..sort()).join('+');

  MixResult? resultOf(Iterable<String> inkIds) =>
      inkIds.isEmpty ? null : results[keyFor(inkIds)];

  Iterable<String> get assetPaths =>
      <String>[if (vesselImage != null) vesselImage!];
}

/// Parses and validates a `mix_lab` payload.
MixLabContent parseMixLabContent(ActivitySpec spec) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final List<Map<String, dynamic>> rawInks = reader.optionalMapList('inks');
  // Two is the smallest set that can mix; past four the table is fifteen
  // entries and the tray is too wide for a phone.
  if (rawInks.length < 2 || rawInks.length > 4) {
    throw ActivityContentException(
        '$path.inks', 'expected 2..4 inks, got ${rawInks.length}');
  }
  final List<MixInk> inks = <MixInk>[];
  for (int index = 0; index < rawInks.length; index++) {
    final String where = '$path.inks[$index]';
    final JsonReader ink = JsonReader(rawInks[index], where);
    final String id = ink.requireString('id');
    if (id.contains('+')) {
      throw ActivityContentException('$where.id', '"+" joins ids; not in one');
    }
    if (inks.any((MixInk other) => other.id == id)) {
      throw ActivityContentException('$where.id', 'duplicate ink "$id"');
    }
    inks.add(MixInk(
      id: id,
      colorValue: _requireColor(ink, 'color', where),
      label: _requireText(rawInks[index]['label'], '$where.label'),
    ));
  }
  final Set<String> inkIds = inks.map((MixInk i) => i.id).toSet();

  final Map<String, MixResult> results = <String, MixResult>{
    for (final MixInk ink in inks)
      ink.id: MixResult(
          inkIds: <String>[ink.id], colorValue: ink.colorValue, label: ink.label),
  };
  final List<Map<String, dynamic>> rawMixes = reader.optionalMapList('mixes');
  for (int index = 0; index < rawMixes.length; index++) {
    final String where = '$path.mixes[$index]';
    final JsonReader mix = JsonReader(rawMixes[index], where);
    final List<String> of = mix.requireStringList('of');
    if (of.length < 2 || of.toSet().length != of.length) {
      throw ActivityContentException(
          '$where.of', 'a mix is two or more different inks');
    }
    for (final String id in of) {
      if (!inkIds.contains(id)) {
        throw ActivityContentException('$where.of', 'no ink "$id"');
      }
    }
    final String key = MixLabContent.keyFor(of);
    if (results.containsKey(key)) {
      throw ActivityContentException('$where.of', '$key is declared twice');
    }
    results[key] = MixResult(
      inkIds: (List<String>.of(of)..sort()),
      colorValue: _requireColor(mix, 'color', where),
      label: _requireText(rawMixes[index]['label'], '$where.label'),
    );
  }
  final int expected = (1 << inks.length) - 1;
  if (results.length != expected) {
    final List<String> missing = <String>[];
    for (int mask = 1; mask <= expected; mask++) {
      final List<String> set = <String>[
        for (int bit = 0; bit < inks.length; bit++)
          if (mask & (1 << bit) != 0) inks[bit].id,
      ];
      if (!results.containsKey(MixLabContent.keyFor(set))) {
        missing.add(MixLabContent.keyFor(set));
      }
    }
    throw ActivityContentException('$path.mixes',
        'every combination a child can make must say what it makes; '
        'missing $missing');
  }

  final List<Map<String, dynamic>> rawRounds = reader.optionalMapList('rounds');
  if (rawRounds.isEmpty) {
    throw ActivityContentException('$path.rounds', 'need at least one round');
  }
  final List<MixRound> rounds = <MixRound>[];
  for (int index = 0; index < rawRounds.length; index++) {
    final String where = '$path.rounds[$index]';
    final JsonReader round = JsonReader(rawRounds[index], where);
    final List<String> target = round.requireStringList('make')..sort();
    if (target.isEmpty || !results.containsKey(MixLabContent.keyFor(target))) {
      throw ActivityContentException(
          '$where.make', 'must name inks this activity has');
    }
    if (rounds.any((MixRound r) =>
        MixLabContent.keyFor(r.target) == MixLabContent.keyFor(target))) {
      throw ActivityContentException(
          '$where.make', 'asks for what an earlier round already made');
    }
    rounds.add(MixRound(
      id: round.requireString('id'),
      target: List<String>.unmodifiable(target),
      label: _requireText(rawRounds[index]['label'], '$where.label'),
      revealLine: rawRounds[index]['revealLine'] == null
          ? null
          : LocalizedText.fromJson(rawRounds[index]['revealLine'],
              debugPath: '$where.revealLine'),
    ));
  }
  if (rounds.every((MixRound r) => r.target.length < 2)) {
    throw ActivityContentException('$path.rounds',
        'no round needs a mix, so nothing is ever combined');
  }
  // Two results that look alike make the target ambiguous: the child made
  // the colour shown and was told it was wrong.
  final List<MixResult> all = results.values.toList();
  for (int a = 0; a < all.length; a++) {
    for (int b = a + 1; b < all.length; b++) {
      if (all[a].colorValue == all[b].colorValue) {
        throw ActivityContentException('$path.mixes',
            '${MixLabContent.keyFor(all[a].inkIds)} and '
            '${MixLabContent.keyFor(all[b].inkIds)} make the same colour');
      }
    }
  }

  return MixLabContent(
    inks: List<MixInk>.unmodifiable(inks),
    results: Map<String, MixResult>.unmodifiable(results),
    rounds: List<MixRound>.unmodifiable(rounds),
    emptyColorValue: reader.has('emptyColor')
        ? _requireColor(reader, 'emptyColor', path)
        : 0xFF9AA0A8,
    vesselImage: reader.optionalString('vesselImage'),
    accentColorValue: _hexValue(spec.presentation.accent),
  );
}

LocalizedText _requireText(Object? raw, String where) {
  final LocalizedText text = LocalizedText.fromJson(raw, debugPath: where);
  if (text.isEmpty) {
    throw ActivityContentException(where, 'expected {locale: text}');
  }
  return text;
}

int _requireColor(JsonReader reader, String key, String where) {
  final int? value = _hexValue(reader.optionalString(key));
  if (value == null) {
    throw ActivityContentException('$where.$key', 'expected "#RRGGBB"');
  }
  return value;
}

int? _hexValue(String? raw) {
  if (raw == null) {
    return null;
  }
  final String hex = raw.replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return null;
  }
  return int.parse('FF$hex', radix: 16);
}
