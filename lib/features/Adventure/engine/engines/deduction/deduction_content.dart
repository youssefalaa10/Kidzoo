import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One fact about the answer.
///
/// A clue *keeps* the candidates whose [attribute] equals [value] and rules
/// out the rest. Stated positively on purpose: "it has a tail" is something a
/// four-year-old can check against a picture; "it has no wings" asks them to
/// hold a negation and a picture at once.
@immutable
class DeductionClue {
  const DeductionClue({
    required this.id,
    required this.attribute,
    required this.value,
    required this.label,
    this.image,
    this.revealLine,
  });

  final String id;
  final String attribute;
  final String value;

  /// Shown and spoken as the prompt while this clue is being applied.
  final LocalizedText label;

  /// A picture of the fact — a snowflake for "icy" — so the clue can be
  /// checked against the cards without reading.
  final String? image;

  /// Spoken once everything this clue rules out has been set aside.
  final LocalizedText? revealLine;

  bool keeps(PackItem item) => item.attribute(attribute) == value;
}

/// Candidates, and the clues that narrow them to one.
@immutable
class DeductionContent extends ActivityContent {
  const DeductionContent({
    required this.candidates,
    required this.clues,
    required this.answer,
    this.accentColorValue,
  });

  /// In authored order, which is also their slot on the board. Slots never
  /// move, so a card set aside leaves a gap that says so.
  final List<PackItem> candidates;

  final List<DeductionClue> clues;

  /// What is left when every clue has been applied. Derived, never authored,
  /// so it cannot disagree with the clues.
  final PackItem answer;

  final int? accentColorValue;

  /// Who [clue] rules out, among those still standing before it.
  List<PackItem> ruledOutBy(int clueIndex) {
    final List<PackItem> standing = <PackItem>[
      for (final PackItem item in candidates)
        if (clues.take(clueIndex).every((DeductionClue c) => c.keeps(item)))
          item,
    ];
    return <PackItem>[
      for (final PackItem item in standing)
        if (!clues[clueIndex].keeps(item)) item,
    ];
  }

  Iterable<String> get assetPaths => <String>[
        for (final PackItem item in candidates) item.imageAsset,
        for (final DeductionClue clue in clues)
          if (clue.image != null) clue.image!,
      ];
}

/// Parses a `deduction` payload and proves it solvable before anyone plays.
DeductionContent parseDeductionContent(
  ActivitySpec spec,
  ItemPackResolver packs,
) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final ItemPack pack = packs.require(reader.requireString('itemsRef'),
      debugPath: '$path.itemsRef');
  final List<String> candidateIds = reader.requireStringList('candidateIds');
  // Three is the fewest that makes ruling out different from guessing;
  // past eight the cards are too small to check against a clue.
  if (candidateIds.length < 3 || candidateIds.length > 8) {
    throw ActivityContentException('$path.candidateIds',
        'expected 3..8 candidates, got ${candidateIds.length}');
  }
  if (candidateIds.toSet().length != candidateIds.length) {
    throw ActivityContentException(
        '$path.candidateIds', 'a candidate is listed twice');
  }
  final List<PackItem> candidates =
      pack.select(candidateIds, debugPath: '$path.candidateIds');

  final List<Map<String, dynamic>> rawClues = reader.optionalMapList('clues');
  if (rawClues.isEmpty) {
    throw ActivityContentException('$path.clues', 'need at least one clue');
  }
  final List<DeductionClue> clues = <DeductionClue>[];
  List<PackItem> standing = List<PackItem>.of(candidates);
  for (int index = 0; index < rawClues.length; index++) {
    final String where = '$path.clues[$index]';
    final JsonReader clue = JsonReader(rawClues[index], where);
    final String attribute = clue.requireString('attribute');
    for (final PackItem item in candidates) {
      if (item.attribute(attribute) == null) {
        throw ActivityContentException('$where.attribute',
            '"${item.id}" says nothing about "$attribute", so the clue '
            'cannot be checked against it');
      }
    }
    final LocalizedText label =
        LocalizedText.fromJson(rawClues[index]['label'], debugPath: '$where.label');
    if (label.isEmpty) {
      throw ActivityContentException('$where.label', 'a clue has to be said');
    }
    final DeductionClue parsed = DeductionClue(
      id: clue.requireString('id'),
      attribute: attribute,
      value: clue.requireString('value'),
      label: label,
      image: clue.optionalString('image'),
      revealLine: rawClues[index]['revealLine'] == null
          ? null
          : LocalizedText.fromJson(rawClues[index]['revealLine'],
              debugPath: '$where.revealLine'),
    );
    final List<PackItem> kept =
        standing.where(parsed.keeps).toList(growable: false);
    if (kept.length == standing.length) {
      throw ActivityContentException(where,
          'rules nobody out, so the child has nothing to do with it');
    }
    if (kept.isEmpty) {
      throw ActivityContentException(
          where, 'rules everybody out, so there is no answer');
    }
    clues.add(parsed);
    standing = kept;
  }
  if (standing.length != 1) {
    throw ActivityContentException('$path.clues',
        'leaves ${standing.map((PackItem i) => i.id).toList()} standing; the '
        'clues must narrow it to exactly one');
  }

  return DeductionContent(
    candidates: candidates,
    clues: List<DeductionClue>.unmodifiable(clues),
    answer: standing.single,
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
