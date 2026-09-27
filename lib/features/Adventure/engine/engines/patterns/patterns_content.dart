import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// What the child is asked to do with the repeat.
///
/// Both readings are the same data — a unit, a number of repetitions, and some
/// positions left empty — and differ only in *where* the empty positions are.
/// Splitting them into two engines would have produced two engines with one
/// model, which is the mistake `trace_path` already declined to make.
enum PatternMode {
  /// The gaps are at the end. "What comes next?" — the entry rung, because the
  /// child can read the whole pattern from left to right and simply carry on.
  extend,

  /// The gaps are inside. Harder, and the more useful one: a hole in the middle
  /// cannot be answered by momentum, only by working out what the rule *is* and
  /// applying it to a position you had to look away from to check.
  fillGap;

  static PatternMode parse(String raw, String path) {
    for (final PatternMode mode in PatternMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    throw ActivityContentException(
      path,
      '"$raw" is not a pattern mode; expected one of '
      '${PatternMode.values.map((PatternMode m) => m.name).toList()}',
    );
  }
}

/// One run of a repeating pattern, with some positions left empty.
@immutable
class PatternRound {
  const PatternRound({
    required this.id,
    required this.unitItemIds,
    required this.repeats,
    required this.gaps,
    required this.mode,
    required this.label,
    this.revealLine,
  });

  final String id;

  /// The chunk that repeats — ABC, AAB, AB. Two to four items.
  ///
  /// The *unit* is the thing being learned, not the strip. A child who can say
  /// "shell, shell, coral" has the rule; one who has only matched the tile two
  /// places to the left has not, which is why a longer strip of a short unit is
  /// easier rather than harder.
  final List<String> unitItemIds;

  final int repeats;

  /// Positions in the laid-out strip that start empty, in the order the child
  /// is asked to fill them.
  final List<int> gaps;

  final PatternMode mode;

  /// What this round is *for*, in the story. Spoken in place of the generic
  /// prompt, so the strip is never just a strip.
  final LocalizedText label;

  /// Said once the round is whole. This is the consequence — the current runs,
  /// the gate opens — and the beat after it depends on having heard it.
  final LocalizedText? revealLine;

  int get length => unitItemIds.length * repeats;

  /// What belongs at [index], by the rule.
  String itemIdAt(int index) => unitItemIds[index % unitItemIds.length];

  /// The strip as it looks before the child touches anything: the authored
  /// item at every position except the gaps.
  List<String?> get openStrip => <String?>[
        for (int index = 0; index < length; index++)
          gaps.contains(index) ? null : itemIdAt(index),
      ];
}

class PatternsContent extends ActivityContent {
  const PatternsContent({
    required this.rounds,
    required this.items,
    required this.revealedRepeats,
    required this.trayExtraCount,
    this.accentColorValue,
  });

  final List<PatternRound> rounds;

  /// The pack the tiles come from.
  final List<PackItem> items;

  /// How many whole repetitions are guaranteed visible before the first gap.
  ///
  /// The errorless-fading dial for this engine, and the reason it is the
  /// adaptation axis. One repetition shown is a guess; two is a pattern a child
  /// can see; three is generous. It is validated rather than merely declared —
  /// a round whose first gap arrives sooner than this claims is a content bug,
  /// not a harder round.
  final int revealedRepeats;

  /// Tiles in the tray that are in no gap.
  ///
  /// Without at least one, the last gap of a round can be filled by elimination
  /// — there is only one tile left, so it must go in the hole — and a child who
  /// does that has practised counting the tray, not reading the pattern.
  final int trayExtraCount;

  /// The chapter's accent, as content declared it.
  ///
  /// The ledge is drawn in it, which is what lets the same ribbon be a reef in
  /// one chapter and a vine in the next without a line of code moving.
  final int? accentColorValue;

  PackItem? itemById(String id) {
    for (final PackItem item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Iterable<String> get assetPaths =>
      items.map((PackItem item) => item.imageAsset);
}

PatternsContent parsePatternsContent(ActivitySpec spec, ItemPackResolver packs) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final ItemPack pack = packs.require(
    reader.requireString('itemsRef'),
    debugPath: '$path.itemsRef',
  );
  final List<PackItem> items = pack.select(
    reader.optionalStringList('itemIds'),
    debugPath: '$path.itemIds',
  );

  final int revealedRepeats = reader.optionalInt('revealedRepeats') ?? 2;
  if (revealedRepeats < 1 || revealedRepeats > 4) {
    throw ActivityContentException(
        '$path.revealedRepeats', 'expected between 1 and 4');
  }
  final int trayExtraCount = reader.optionalInt('trayExtraCount') ?? 1;
  if (trayExtraCount < 0 || trayExtraCount > 4) {
    throw ActivityContentException(
        '$path.trayExtraCount', 'expected between 0 and 4');
  }

  final String defaultMode = reader.optionalString('mode') ?? 'extend';
  PatternMode.parse(defaultMode, '$path.mode');

  final List<Map<String, dynamic>> rawRounds = reader.optionalMapList('rounds');
  if (rawRounds.isEmpty) {
    throw ActivityContentException(
      '$path.rounds',
      'need at least one round; a generated pattern cannot carry a story beat',
    );
  }

  final List<PatternRound> rounds = <PatternRound>[];
  final Set<String> signatures = <String>{};
  for (int index = 0; index < rawRounds.length; index++) {
    final Map<String, dynamic> raw = rawRounds[index];
    final String where = '$path.rounds[$index]';
    final JsonReader roundReader = JsonReader(raw, where);

    final List<String> unit = roundReader.requireStringList('unit');
    if (unit.length < 2 || unit.length > 4) {
      throw ActivityContentException('$where.unit',
          'a repeating unit is two to four items; got ${unit.length}');
    }
    for (final String id in unit) {
      if (!items.any((PackItem item) => item.id == id)) {
        throw ActivityContentException(
            '$where.unit', 'no item "$id" in the pack');
      }
    }
    if (unit.toSet().length < 2) {
      throw ActivityContentException('$where.unit',
          'every position is the same item, so there is no pattern to read');
    }

    final int repeats = roundReader.optionalInt('repeats') ?? 3;
    if (repeats < 2) {
      throw ActivityContentException(
          '$where.repeats', 'a unit shown once does not repeat');
    }

    final PatternMode mode = PatternMode.parse(
      roundReader.optionalString('mode') ?? defaultMode,
      '$where.mode',
    );

    final List<int> gaps = roundReader.optionalIntList('gaps');
    final int length = unit.length * repeats;
    if (gaps.isEmpty) {
      throw ActivityContentException(
          '$where.gaps', 'a round with no gap asks the child nothing');
    }
    if (gaps.toSet().length != gaps.length) {
      throw ActivityContentException('$where.gaps', 'a gap is listed twice');
    }
    for (final int gap in gaps) {
      if (gap < 0 || gap >= length) {
        throw ActivityContentException('$where.gaps',
            'gap $gap is outside a strip of $length positions');
      }
    }
    if (gaps.length >= length) {
      throw ActivityContentException(
          '$where.gaps', 'every position is a gap, so nothing shows the rule');
    }

    // The dial has to be true, not merely declared. A round claiming two
    // visible repetitions while opening a hole in the first one is not a
    // harder round — it is a round whose scaffolding silently is not there.
    final int firstGap = gaps.reduce((int a, int b) => a < b ? a : b);
    if (firstGap < revealedRepeats * unit.length) {
      throw ActivityContentException(
        '$where.gaps',
        'the first gap is at $firstGap, inside the $revealedRepeats whole '
        'repetitions this activity promises to show before asking anything',
      );
    }

    // Gaps all landing on the same position within the unit can be answered by
    // copying one tile a fixed distance back, without ever reading the unit.
    if (gaps.length > 1) {
      final Set<int> positions =
          gaps.map((int gap) => gap % unit.length).toSet();
      if (positions.length == 1) {
        throw ActivityContentException(
          '$where.gaps',
          'every gap falls on the same position in the unit, so the whole '
          'round is one question asked repeatedly',
        );
      }
    }

    if (mode == PatternMode.extend) {
      final int lastGap = gaps.reduce((int a, int b) => a > b ? a : b);
      if (lastGap != length - 1) {
        throw ActivityContentException('$where.gaps',
            'an "extend" round leaves the END of the strip open');
      }
    }

    final String signature = '${unit.join('-')}|${(List<int>.of(gaps)..sort())}';
    if (!signatures.add(signature)) {
      throw ActivityContentException(
        where,
        'another round already asks this exact question; repeating it reads to '
        'a child as the app getting stuck',
      );
    }

    rounds.add(PatternRound(
      id: roundReader.requireString('id'),
      unitItemIds: List<String>.unmodifiable(unit),
      repeats: repeats,
      gaps: List<int>.unmodifiable(gaps),
      mode: mode,
      label: LocalizedText.fromJson(raw['prompt'], debugPath: '$where.prompt'),
      revealLine: raw['revealLine'] == null
          ? null
          : LocalizedText.fromJson(raw['revealLine'],
              debugPath: '$where.revealLine'),
    ));
  }

  return PatternsContent(
    rounds: rounds,
    items: items,
    revealedRepeats: revealedRepeats,
    trayExtraCount: trayExtraCount,
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
