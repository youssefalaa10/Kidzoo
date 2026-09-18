import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_content.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

class CountingStep extends ActivityStep {
  const CountingStep({
    required String stepId,
    required this.targetCount,
    required this.item,
    required this.numeralOptions,
    required this.layout,
    required this.mode,
    this.prompt,
    this.revealLine,
  }) : super(stepId);

  final int targetCount;
  final PackItem item;

  /// The numerals offered, in ascending order so the row never reshuffles
  /// between attempts — a moving answer is its own difficulty.
  final List<int> numeralOptions;

  final CountingLayout layout;
  final CountingMode mode;

  /// This round's authored wording, when it has its own.
  final LocalizedText? prompt;
  final LocalizedText? revealLine;

  String optionIdFor(int value) => 'count_$value';
  int valueOfOptionId(String id) => int.parse(id.split('_').last);
}

class CountingCubit extends ActivityCubit<CountingContent, CountingStep> {
  CountingCubit(super.session);

  @override
  List<CountingStep> buildSteps() {
    if (content.isAuthored) {
      return _authoredSteps();
    }
    return _generatedSteps();
  }

  List<CountingStep> _authoredSteps() {
    final List<CountingStep> steps = <CountingStep>[];
    for (int round = 0; round < content.rounds.length; round++) {
      final CountingRound authored = content.rounds[round];
      steps.add(CountingStep(
        stepId: 'count_${round}_${authored.item.id}',
        targetCount: authored.targetCount,
        item: authored.item,
        numeralOptions: _optionsAround(authored.targetCount),
        layout: content.layout,
        mode: content.mode,
        prompt: authored.prompt,
        revealLine: authored.revealLine,
      ));
    }
    return steps;
  }

  /// The generated path, for content whose counts carry no story weight.
  ///
  /// It draws **without replacement** where it can. The previous version drew
  /// each round independently, so a three-round activity could legitimately ask
  /// "how many?" about three monkeys, three times — and to a four-year-old that
  /// is not randomness, it is the app repeating itself. Repeats are only
  /// allowed once the range has genuinely run out of distinct answers.
  List<CountingStep> _generatedSteps() {
    final List<int> pool = <int>[
      for (int value = content.minCount; value <= content.maxCount; value++)
        value,
    ]..shuffle(services.random);
    final List<PackItem> itemPool = List<PackItem>.of(content.items)
      ..shuffle(services.random);

    final List<CountingStep> steps = <CountingStep>[];
    for (int round = 0; round < content.roundCount; round++) {
      final int target = content.fixedTargetCount ?? pool[round % pool.length];
      final PackItem item = itemPool[round % itemPool.length];
      steps.add(CountingStep(
        stepId: 'count_$round',
        targetCount: target,
        item: item,
        numeralOptions: _optionsAround(target),
        layout: content.layout,
        mode: content.mode,
      ));
    }
    return steps;
  }

  /// Numerals bracketing the answer.
  ///
  /// Near-neighbours, not random numbers: offering 3 against 9 teaches nothing,
  /// because a child can eliminate 9 without counting. The spread is the
  /// errorless dial — narrow it and a wrong answer becomes nearly impossible.
  List<int> _optionsAround(int target) {
    final Set<int> options = <int>{target};
    int spread = 1;
    while (options.length < content.optionSpread + 1 && spread <= 6) {
      if (target - spread >= 1) {
        options.add(target - spread);
      }
      if (options.length < content.optionSpread + 1) {
        options.add(target + spread);
      }
      spread++;
    }
    final List<int> sorted = options.toList()..sort();
    return sorted;
  }

  @override
  ActivityJudgement judge(CountingStep step, ActivityAttempt attempt) {
    if (attempt is QuantityAttempt) {
      return attempt.value == step.targetCount
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }
    if (attempt is ChoiceAttempt) {
      final int? value = int.tryParse(attempt.optionId.split('_').last);
      return value == step.targetCount
          ? const ActivityJudgement.correct()
          : const ActivityJudgement.wrongItem();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(CountingStep step, ScaffoldLevel level) {
    final List<String> allIds = step.numeralOptions
        .map((int value) => step.optionIdFor(value))
        .toList(growable: false);
    final List<String> live = services.coach.liveOptionsFor(
      level: level,
      allOptionIds: allIds,
      correctOptionId: step.optionIdFor(step.targetCount),
      random: services.random,
    );

    // The prompt is authored whole per locale — per round when the round has
    // its own wording, otherwise on the spec. It is never assembled here, and
    // that is a hard rule rather than a style preference: Arabic number-noun
    // agreement is irregular (dual for 2, a broken plural for 3-10, a singular
    // accusative for 11+), so "How many {n} {noun}?" cannot be built by
    // substitution without producing wrong Arabic.
    final LocalizedText prompt = step.prompt ??
        (spec.narration.prompt.isEmpty
            ? const LocalizedText(<String, String>{'en': 'How many?'})
            : spec.narration.prompt);

    return ActivityStepView(
      prompt: prompt,
      revealLine: step.revealLine,
      liveOptionIds: live,
      dimmedOptionIds:
          allIds.where((String id) => !live.contains(id)).toList(growable: false),
      highlightOptionId: level == ScaffoldLevel.modelled
          ? step.optionIdFor(step.targetCount)
          : null,
    );
  }
}
