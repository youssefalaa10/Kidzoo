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
  }) : super(stepId);

  final int targetCount;
  final PackItem item;

  /// The numerals offered, in ascending order so the row never reshuffles
  /// between attempts — a moving answer is its own difficulty.
  final List<int> numeralOptions;

  final CountingLayout layout;
  final CountingMode mode;

  String optionIdFor(int value) => 'count_$value';
  int valueOfOptionId(String id) => int.parse(id.split('_').last);
}

class CountingCubit extends ActivityCubit<CountingContent, CountingStep> {
  CountingCubit(super.session);

  @override
  List<CountingStep> buildSteps() {
    final List<CountingStep> steps = <CountingStep>[];
    for (int round = 0; round < content.roundCount; round++) {
      final int target = content.fixedTargetCount ??
          (content.minCount +
              services.random
                  .nextInt(content.maxCount - content.minCount + 1));
      final PackItem item =
          content.items[services.random.nextInt(content.items.length)];
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

    // The prompt is authored whole per locale on the spec. It is not assembled
    // here, and that is a hard rule rather than a style preference: Arabic
    // number-noun agreement is irregular (3-10 take a broken plural, 11+ a
    // singular accusative), so "How many {n} {noun}?" cannot be built by
    // substitution without producing wrong Arabic.
    return ActivityStepView(
      prompt: spec.narration.prompt.isEmpty
          ? const LocalizedText(<String, String>{'en': 'How many?'})
          : spec.narration.prompt,
      liveOptionIds: live,
      dimmedOptionIds:
          allIds.where((String id) => !live.contains(id)).toList(growable: false),
      highlightOptionId: level == ScaffoldLevel.modelled
          ? step.optionIdFor(step.targetCount)
          : null,
    );
  }
}
