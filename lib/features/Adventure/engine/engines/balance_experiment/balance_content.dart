import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One thing the child can put on the pan, and what it weighs.
///
/// The weight comes off a pack attribute rather than out of the activity file,
/// so an item weighs the same everywhere it appears. A crate that is heavy in
/// one story and light in the next is not a world, it is a quiz.
///
/// [quantity] caps how many times this item may be placed on the pan in one
/// round. Null means unlimited. A story that says "there is one apple on the
/// counter" should set quantity: 1; two apples means Apple+Apple=4 is wrong
/// regardless of whether the weights add up.
@immutable
class WeighedItem {
  const WeighedItem({required this.item, required this.weight, this.quantity});

  final PackItem item;
  final int weight;

  /// How many of this item are available in this round. Null = unlimited.
  final int? quantity;

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
  /// cannot finish. When an item has a quantity cap the problem is bounded
  /// knapsack; when all items are unlimited it degenerates to the coin problem.
  bool get isReachable {
    final List<bool> canMake = List<bool>.filled(target + 1, false);
    canMake[0] = true;
    for (final WeighedItem item in available) {
      final int w = item.weight;
      if (w <= 0) continue;
      // limit: how many times this item may be used (null = floor(target/w))
      final int limit = item.quantity ?? (target ~/ w);
      // Snapshot to prevent reuse of this item's own contribution within one sweep
      final List<bool> prev = List<bool>.from(canMake);
      for (int total = w; total <= target; total++) {
        for (int k = 1; k <= limit && k * w <= total; k++) {
          if (prev[total - k * w]) {
            canMake[total] = true;
            break;
          }
        }
      }
    }
    return canMake[target];
  }

  /// One way to make the target, heaviest-first greedy. Used to demonstrate.
  List<WeighedItem> get oneSolution {
    final List<WeighedItem> sorted = <WeighedItem>[...available]
      ..sort((WeighedItem a, WeighedItem b) => b.weight.compareTo(a.weight));
    final List<WeighedItem> chosen = <WeighedItem>[];
    final Map<String, int> used = <String, int>{};
    int remaining = target;
    for (final WeighedItem item in sorted) {
      final int limit = item.quantity ?? remaining;
      while (item.weight > 0 && item.weight <= remaining) {
        if ((used[item.id] ?? 0) >= limit) break;
        chosen.add(item);
        used[item.id] = (used[item.id] ?? 0) + 1;
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

    final List<String> itemIds = roundReader.optionalStringList('itemIds');
    final List<PackItem> items = pack.select(
      itemIds,
      debugPath: '$where.itemIds',
    );
    // Optional parallel list: itemQtys[i] caps how many times itemIds[i] may
    // be placed on the pan. Omit the list (or make it shorter) for unlimited.
    final List<int> rawQtys = roundReader.optionalIntList('itemQtys');
    final List<WeighedItem> weighed = <WeighedItem>[];
    for (int i = 0; i < items.length; i++) {
      final PackItem item = items[i];
      final String? rawWeight = item.attribute(attribute);
      final int? weight = rawWeight == null ? null : int.tryParse(rawWeight);
      if (weight == null || weight <= 0) {
        throw ActivityContentException(
          '$where.itemIds',
          'item "${item.id}" has no usable "$attribute" attribute, so it '
          'cannot be put on a scale',
        );
      }
      final int? qty =
          (i < rawQtys.length && rawQtys[i] > 0) ? rawQtys[i] : null;
      weighed.add(WeighedItem(item: item, weight: weight, quantity: qty));
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
