import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';

/// What the child is asked to do with the quantity.
enum CountingMode {
  /// "How many?" — count the scene, then pick the numeral.
  countAndPick,

  /// "Bring me five." — produce a set of the requested size.
  ///
  /// Strictly harder than [countAndPick] and the real test of cardinality:
  /// a child can recite "one, two, three" over three objects without yet
  /// understanding that "three" *is* the set.
  giveN,
}

/// How the countable items are arranged.
///
/// The order is the difficulty ladder and it is not arbitrary — structured
/// arrangements are recognised faster and more accurately than scattered ones,
/// and the progression below is the one the evidence supports.
enum CountingLayout {
  /// Dice pips. The most recognisable pattern of all.
  dice,

  /// Two rows of five. Builds the base-ten anchor.
  tenFrame,

  /// A single straight row.
  linear,

  /// Loose clusters.
  scatter,

  /// Freely placed. Hardest: nothing supports the one-to-one sweep.
  random,
}

class CountingContent extends ActivityContent {
  const CountingContent({
    required this.mode,
    required this.roundCount,
    required this.minCount,
    required this.maxCount,
    required this.layout,
    required this.items,
    required this.optionSpread,
    this.fixedTargetCount,
  });

  final CountingMode mode;
  final int roundCount;
  final int minCount;
  final int maxCount;
  final CountingLayout layout;
  final List<PackItem> items;

  /// How far the numeral options spread either side of the answer. This is the
  /// errorless-fading dial: a spread of 1 offers near-neighbours only.
  final int optionSpread;

  /// Set when the author wants one specific count rather than a range — used
  /// when the count has to mean something in the story.
  final int? fixedTargetCount;

  Iterable<String> get assetPaths =>
      items.map((PackItem item) => item.imageAsset);
}

/// Parses the `counting` payload.
///
/// Every name here is the thing the author actually means — `targetCount`,
/// `countRange`, `layout` — never a difficulty tier. "Medium counting" would
/// have to encode both how many things there are *and* how they are arranged,
/// and those two ladders are independent.
CountingContent parseCountingContent(ActivitySpec spec, ItemPackResolver packs) {
  final JsonReader reader = spec.payloadReader;
  final String path = '${spec.sourcePath} > payload';

  final CountingMode mode = _parseEnum<CountingMode>(
    reader.optionalString('mode') ?? 'countAndPick',
    CountingMode.values,
    '$path.mode',
  );
  final CountingLayout layout = _parseEnum<CountingLayout>(
    reader.optionalString('layout') ?? 'scatter',
    CountingLayout.values,
    '$path.layout',
  );

  final ItemPack pack = packs.require(
    reader.optionalString('itemsRef') ?? 'packs/animals',
    debugPath: '$path.itemsRef',
  );
  final List<PackItem> items = pack.select(
    reader.optionalStringList('itemIds'),
    debugPath: '$path.itemIds',
  );

  final int? fixedTarget = reader.optionalInt('targetCount');
  final List<int> range = reader.optionalIntList('countRange');
  final int minCount = fixedTarget ?? (range.isNotEmpty ? range.first : 2);
  final int maxCount =
      fixedTarget ?? (range.length > 1 ? range[1] : (minCount + 3));

  if (minCount < 1) {
    throw ActivityContentException('$path.countRange', 'counts start at 1');
  }
  if (maxCount < minCount) {
    throw ActivityContentException(
      '$path.countRange',
      'countRange max ($maxCount) is below min ($minCount)',
    );
  }

  final int roundCount = reader.optionalInt('roundCount') ?? 4;
  if (roundCount < 1) {
    throw ActivityContentException('$path.roundCount', 'need at least 1 round');
  }

  return CountingContent(
    mode: mode,
    roundCount: roundCount,
    minCount: minCount,
    maxCount: maxCount,
    layout: layout,
    items: items,
    optionSpread: reader.optionalInt('optionSpread') ?? 2,
    fixedTargetCount: fixedTarget,
  );
}

T _parseEnum<T extends Enum>(String raw, List<T> values, String path) {
  for (final T value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  throw ActivityContentException(
    path,
    '"$raw" is not one of ${values.map((T v) => v.name).toList()}',
  );
}
