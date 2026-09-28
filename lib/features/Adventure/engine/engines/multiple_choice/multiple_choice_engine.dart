import 'package:flutter/material.dart';
import 'package:kidzo/core/shared/style/kid_ui.dart';
import 'package:kidzo/core/shared/widgets/kid_pick_card.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/multiple_choice/multiple_choice_content.dart';

class MultipleChoiceStep extends ActivityStep {
  const MultipleChoiceStep({
    required String stepId,
    required this.question,
    required this.orderedItems,
  }) : super(stepId);

  final MultipleChoiceQuestion question;

  /// Options in display order, shuffled once at build time so the answer is not
  /// always in the same slot but never moves between attempts.
  final List<PackItem> orderedItems;
}

class MultipleChoiceCubit
    extends ActivityCubit<MultipleChoiceContent, MultipleChoiceStep> {
  MultipleChoiceCubit(super.session);

  @override
  List<MultipleChoiceStep> buildSteps() {
    return content.questions.map((MultipleChoiceQuestion question) {
      final List<PackItem> options = List<PackItem>.of(question.allItems)
        ..shuffle(services.random);
      return MultipleChoiceStep(
        stepId: question.id,
        question: question,
        orderedItems: options,
      );
    }).toList(growable: false);
  }

  @override
  ActivityJudgement judge(MultipleChoiceStep step, ActivityAttempt attempt) {
    if (attempt is! ChoiceAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    return attempt.optionId == step.question.correctItem.id
        ? const ActivityJudgement.correct()
        : const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(MultipleChoiceStep step, ScaffoldLevel level) {
    final List<String> allIds = step.orderedItems
        .map((PackItem item) => item.id)
        .toList(growable: false);
    final List<String> live = services.coach.liveOptionsFor(
      level: level,
      allOptionIds: allIds,
      correctOptionId: step.question.correctItem.id,
      random: services.random,
    );
    return ActivityStepView(
      prompt: step.question.prompt,
      // The authored clue. Without this the animal gets picked, a chime plays
      // and it says nothing — which drops the link the whole Adventure is
      // built on, because the next beat assumes the child was told something.
      revealLine: step.question.revealLine,
      liveOptionIds: live,
      dimmedOptionIds: allIds
          .where((String id) => !live.contains(id))
          .toList(growable: false),
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.question.correctItem.id : null,
    );
  }
}

/// Quiz-shaped activities: pick the one that answers the question.
///
/// Replaces `QuizCubit` plus the `QuizEngineScreen` that nothing ever used. The
/// difference is where the seam sits — this engine owns no chrome at all, so a
/// consumer that needs a different look changes content, not layout.
class MultipleChoiceEngine extends ActivityEngine<MultipleChoiceContent> {
  const MultipleChoiceEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'multiple_choice',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.vocabulary},
        interactionModes: <InteractionMode>{InteractionMode.chooseOne},
        contentParameters: <ContentParameter>[
          ContentParameter.integer('optionCount', minValue: 2, maxValue: 6),
          ContentParameter.text('itemsRef'),
          ContentParameter.list('questions',
              isRequired: true,
              description: 'authored per round; wording carries the story'),
        ],
        adaptationAxis: 'optionCount',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  MultipleChoiceContent parseContent(
          ActivitySpec spec, ItemPackResolver packs) =>
      parseMultipleChoiceContent(spec, packs);

  @override
  Iterable<String> assetsFor(MultipleChoiceContent content) =>
      content.assetPaths;

  @override
  ActivityCubit<MultipleChoiceContent, dynamic> createCubit(
    ActivitySession<MultipleChoiceContent> session,
  ) =>
      MultipleChoiceCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! MultipleChoiceStep) {
        return const SizedBox.shrink();
      }
      return _MultipleChoiceBoard(step: step, state: state, submit: submit);
    };
  }
}

class _MultipleChoiceBoard extends StatelessWidget {
  const _MultipleChoiceBoard({
    required this.step,
    required this.state,
    required this.submit,
  });

  final MultipleChoiceStep step;
  final ActivityState state;
  final ActivityAttemptCallback submit;

  KidCardState _cardStateFor(PackItem item) {
    final ActivityStepView? view = state.view;
    final bool isLive = view == null || view.liveOptionIds.contains(item.id);
    if (!isLive) {
      // Faded but still occupying its slot, so the tray cannot reflow under a
      // finger that is already moving toward a card.
      return KidCardState.done;
    }
    if (view?.highlightOptionId == item.id) {
      return KidCardState.hint;
    }
    if (state.lastAttemptedOptionId == item.id) {
      return state.lastOutcome == AttemptOutcome.correct
          ? KidCardState.correct
          : KidCardState.wrong;
    }
    return KidCardState.idle;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing = constraints.maxWidth * 0.04;
        final double cardSize = kidFitCardSize(
          count: step.orderedItems.length,
          box: Size(constraints.maxWidth, constraints.maxHeight),
          spacing: spacing,
          minSize: KidUi.minTouchYoung,
        );
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: <Widget>[
              for (final PackItem item in step.orderedItems)
                KidPickCard<String>(
                  imageAsset: item.imageAsset,
                  size: cardSize,
                  state: _cardStateFor(item),
                  label: item.label.resolve(state.languageCode),
                  semanticLabel: item.label.resolve(state.languageCode),
                  onTap: () => submit(ChoiceAttempt(item.id)),
                ),
            ],
          ),
        );
      },
    );
  }
}
