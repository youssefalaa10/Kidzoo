import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One thing the child can put on the pan, and what it weighs.
///
/// The weight comes off a pack attribute rather than out of the activity file,
/// so an item weighs the same everywhere it appears. A crate that is heavy in
/// one story and light in the next is not a world, it is a quiz.
@immutable
class WeighedItem {
  const WeighedItem({required this.item, required this.weight});

  final PackItem item;
  final int weight;

  String get id => item.id;
  String get imageAsset => item.imageAsset;
  LocalizedText get label => item.label;
}

/// One order to make up.
@immutable
class BalanceRound {
  const BalanceRound({
    required this.id,
    required this.target,
    required this.available,
    required this.prompt,
    this.revealLine,
  });

  final String id;

  /// What the other pan already holds. The child's job is to match it.
  final int target;

  /// What is on the counter to choose from.
  final List<WeighedItem> available;

  final LocalizedText prompt;

  /// Spoken once the pans come level, so getting it right *causes* something.
  final LocalizedText? revealLine;

  /// Whether the target can be made at all from what is on offer.
  ///
  /// Checked when the file is parsed rather than discovered by a child who
  /// cannot finish. Items may be used more than once, so this is a coin
  /// problem over very small numbers.
  bool get isReachable {
    final List<int> weights = available
        .map((WeighedItem item) => item.weight)
        .where((int weight) => weight > 0 && weight <= target)
        .toList(growable: false);
    if (weights.isEmpty) {
      return false;
    }
    final List<bool> canMake = List<bool>.filled(target + 1, false);
    canMake[0] = true;
    for (int total = 1; total <= target; total++) {
      for (final int weight in weights) {
        if (weight <= total && canMake[total - weight]) {
          canMake[total] = true;
          break;
        }
      }
    }
    return canMake[target];
  }

  /// One way to make the target, smallest first. Used to demonstrate.
  List<WeighedItem> get oneSolution {
    final List<WeighedItem> sorted = <WeighedItem>[...available]
      ..sort((WeighedItem a, WeighedItem b) => b.weight.compareTo(a.weight));
    final List<WeighedItem> chosen = <WeighedItem>[];
    int remaining = target;
    for (final WeighedItem item in sorted) {
      while (item.weight > 0 && item.weight <= remaining) {
        chosen.add(item);
        remaining -= item.weight;
      }
    }
    return remaining == 0 ? chosen : const <WeighedItem>[];
  }
}

/// Everything `balance_experiment` needs, parsed.
@immutable
class BalanceContent extends ActivityContent {
  const BalanceContent({
    required this.rounds,
    required this.weightAttribute,
    required this.tolerance,
    this.unitLabel = const LocalizedText.empty(),
    this.targetImage,
    this.accentColorValue,
  });

  final List<BalanceRound> rounds;

  /// Which pack attribute carries the weight. Named in content so a story
  /// about buoyancy can balance on `floats` and one about cargo on `mass`.
  final String weightAttribute;

  /// How far off level still counts as level.
  ///
  /// Zero for whole units, which is the honest default: a balance that says
  /// "close enough" teaches that the numbers do not really matter. It exists
  /// for content where the quantity is genuinely continuous.
  final int tolerance;

  final LocalizedText unitLabel;
  final String? targetImage;
  final int? accentColorValue;

  Iterable<String> get assetPaths => <String>[
        if (targetImage != null) targetImage!,
        for (final BalanceRound round in rounds)
          for (final WeighedItem item in round.available) item.imageAsset,
      ];
}

/// Reads a `balance_experiment` payload.
BalanceContent parseBalanceContent(ActivitySpec spec, ItemPackResolver packs) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final String attribute = reader.optionalString('weightAttribute') ?? 'weight';
  final ItemPack pack = packs.require(
    reader.requireString('itemsRef'),
    debugPath: '$path.itemsRef',
  );

  final List<Map<String, dynamic>> rawRounds = reader.optionalMapList('rounds');
  if (rawRounds.isEmpty) {
    throw ActivityContentException(
        '$path.rounds', 'need at least one thing to weigh out');
  }

  final List<BalanceRound> rounds = <BalanceRound>[];
  for (int index = 0; index < rawRounds.length; index++) {
    final Map<String, dynamic> raw = rawRounds[index];
    final String where = '$path.rounds[$index]';
    final JsonReader roundReader = JsonReader(raw, where);

    final List<PackItem> items = pack.select(
      roundReader.optionalStringList('itemIds'),
      debugPath: '$where.itemIds',
    );
    final List<WeighedItem> weighed = <WeighedItem>[];
    for (final PackItem item in items) {
      final String? rawWeight = item.attribute(attribute);
      final int? weight = rawWeight == null ? null : int.tryParse(rawWeight);
      if (weight == null || weight <= 0) {
        throw ActivityContentException(
          '$where.itemIds',
          'item "${item.id}" has no usable "$attribute" attribute, so it '
          'cannot be put on a scale',
        );
      }
      weighed.add(WeighedItem(item: item, weight: weight));
    }

    final BalanceRound round = BalanceRound(
      id: roundReader.requireString('id'),
      target: roundReader.requireInt('target'),
      available: weighed,
      prompt:
          LocalizedText.fromJson(raw['prompt'], debugPath: '$where.prompt'),
      revealLine: raw['revealLine'] == null
          ? null
          : LocalizedText.fromJson(raw['revealLine'],
              debugPath: '$where.revealLine'),
    );
    if (round.target <= 0) {
      throw ActivityContentException(
          '$where.target', 'an empty pan is already level, so there is no task');
    }
    if (!round.isReachable) {
      throw ActivityContentException(
        '$where.target',
        'no combination of ${weighed.map((WeighedItem w) => '${w.id}:${w.weight}').toList()} '
        'adds up to ${round.target} — the child could try forever',
      );
    }
    rounds.add(round);
  }

  return BalanceContent(
    rounds: rounds,
    weightAttribute: attribute,
    tolerance: reader.optionalInt('tolerance') ?? 0,
    unitLabel: LocalizedText.fromJson(spec.payload['unitLabel'],
        debugPath: '$path.unitLabel'),
    targetImage: reader.optionalString('targetImage'),
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
