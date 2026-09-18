import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

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

/// One authored round: a named set, a fixed size, its own words.
///
/// The alternative — a count drawn at random from a range, over an item picked
/// at random from a list — is what this replaces, and it was wrong in three
/// separate ways. It could deal the same number twice running, so the second
/// round asked a question the child had just answered. It could deal the same
/// animal every round, so three rounds looked like one. And because the number
/// was only known at runtime, **no story line could ever refer to it**: the beat
/// after the activity had to stay vague about the very quantity the child had
/// just worked out, which is the opposite of a count that means something.
@immutable
class CountingRound {
  const CountingRound({
    required this.item,
    required this.targetCount,
    this.prompt,
    this.revealLine,
  });

  final PackItem item;
  final int targetCount;

  /// This round's own wording. Falls back to `narration.prompt` when absent.
  final LocalizedText? prompt;

  /// Spoken once the round is answered. "Three monkeys saw it go by."
  final LocalizedText? revealLine;
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
    this.rounds = const <CountingRound>[],
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

  /// Authored rounds. When non-empty these **are** the activity, and the
  /// generated path is not used at all.
  final List<CountingRound> rounds;

  bool get isAuthored => rounds.isNotEmpty;

  /// What the whole activity adds up to, for a story line that wants to say it.
  int get authoredTotal => rounds.fold<int>(
        0,
        (int sum, CountingRound round) => sum + round.targetCount,
      );

  Iterable<String> get assetPaths => <String>{
        ...items.map((PackItem item) => item.imageAsset),
        ...rounds.map((CountingRound round) => round.item.imageAsset),
      };
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

  final List<CountingRound> rounds = _parseRounds(reader, pack, path);
  if (rounds.isNotEmpty) {
    final List<int> targets =
        rounds.map((CountingRound round) => round.targetCount).toList();
    return CountingContent(
      mode: mode,
      roundCount: rounds.length,
      minCount: targets.reduce((int a, int b) => a < b ? a : b),
      maxCount: targets.reduce((int a, int b) => a > b ? a : b),
      layout: layout,
      items: items.isEmpty ? pack.items : items,
      optionSpread: reader.optionalInt('optionSpread') ?? 2,
      rounds: rounds,
    );
  }

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

List<CountingRound> _parseRounds(
  JsonReader reader,
  ItemPack pack,
  String path,
) {
  final List<Map<String, dynamic>> raw = reader.optionalMapList('rounds');
  if (raw.isEmpty) {
    return const <CountingRound>[];
  }

  final List<CountingRound> rounds = <CountingRound>[];
  final Set<String> seen = <String>{};
  for (int index = 0; index < raw.length; index++) {
    final String roundPath = '$path.rounds[$index]';
    final Map<String, dynamic> entry = raw[index];
    final JsonReader roundReader = JsonReader(entry, roundPath);
    final String itemId = roundReader.requireString('itemId');
    final PackItem? item = pack.findById(itemId);
    if (item == null) {
      throw ActivityContentException(
        '$roundPath.itemId',
        'pack "${pack.packId}" has no item "$itemId"',
      );
    }
    final int? target = roundReader.optionalInt('targetCount');
    if (target == null || target < 1 || target > 10) {
      throw ActivityContentException(
        '$roundPath.targetCount',
        'a countable scene holds 1 to 10 things; got $target',
      );
    }

    // Two rounds that ask for the same number of the same thing are the same
    // question asked twice, and a child rightly reads that as the app being
    // stuck. Rejected here rather than in a content test so every future
    // activity that reuses this engine inherits the guarantee.
    final String signature = '$itemId:$target';
    if (!seen.add(signature)) {
      throw ActivityContentException(
        roundPath,
        'round repeats "$target x $itemId", which an earlier round already '
        'asked; vary the item or the count',
      );
    }

    rounds.add(CountingRound(
      item: item,
      targetCount: target,
      prompt: entry['prompt'] == null
          ? null
          : LocalizedText.fromJson(entry['prompt'],
              debugPath: '$roundPath.prompt'),
      revealLine: entry['revealLine'] == null
          ? null
          : LocalizedText.fromJson(entry['revealLine'],
              debugPath: '$roundPath.revealLine'),
    ));
  }
  return rounds;
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
