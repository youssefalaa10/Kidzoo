import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// The smallest possible engine, existing only to exercise the base contract.
///
/// Phase 1 ships the whole engine layer with **no real engine**, deliberately:
/// a contract designed against one engine's convenience fits that engine and
/// nothing else. This one asks the child to pick the option whose id matches
/// the step, which is enough to drive every lifecycle path — escalation,
/// narrowing, modelling, scoring, completion — without any domain at all.
class EchoContent extends ActivityContent {
  const EchoContent({required this.stepCount, required this.optionCount});
  final int stepCount;
  final int optionCount;
}

class EchoStep extends ActivityStep {
  const EchoStep({
    required String stepId,
    required this.correctOptionId,
    required this.optionIds,
  }) : super(stepId);

  final String correctOptionId;
  final List<String> optionIds;
}

class EchoCubit extends ActivityCubit<EchoContent, EchoStep> {
  EchoCubit(super.session);

  @override
  List<EchoStep> buildSteps() {
    return List<EchoStep>.generate(content.stepCount, (int index) {
      final List<String> options = List<String>.generate(
        content.optionCount,
        (int option) => 'step${index}_opt$option',
      );
      return EchoStep(
        stepId: 'step$index',
        correctOptionId: options.first,
        optionIds: options,
      );
    });
  }

  @override
  ActivityJudgement judge(EchoStep step, ActivityAttempt attempt) {
    if (attempt is! ChoiceAttempt) {
      return const ActivityJudgement.wrongItem();
    }
    return attempt.optionId == step.correctOptionId
        ? const ActivityJudgement.correct()
        : const ActivityJudgement.wrongItem();
  }

  @override
  ActivityStepView describe(EchoStep step, ScaffoldLevel level) {
    final List<String> live = services.coach.liveOptionsFor(
      level: level,
      allOptionIds: step.optionIds,
      correctOptionId: step.correctOptionId,
      random: services.random,
    );
    return ActivityStepView(
      prompt: LocalizedText(<String, String>{
        'en': 'Pick ${step.correctOptionId}',
        'ar': 'اختر ${step.correctOptionId}',
      }),
      liveOptionIds: live,
      dimmedOptionIds:
          step.optionIds.where((String id) => !live.contains(id)).toList(),
      highlightOptionId:
          level == ScaffoldLevel.modelled ? step.correctOptionId : null,
    );
  }
}

class EchoEngine extends ActivityEngine<EchoContent> {
  const EchoEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'echo',
        kind: EngineKind.bespoke,
        learningDomains: <LearningDomain>{LearningDomain.matching},
        interactionModes: <InteractionMode>{InteractionMode.chooseOne},
        contentParameters: <ContentParameter>[
          ContentParameter.integer('stepCount', minValue: 1, maxValue: 20),
          ContentParameter.integer('optionCount', minValue: 2, maxValue: 8),
        ],
        adaptationAxis: 'stepCount',
        supportedLocales: <String>{'en', 'ar'},
        justification: 'test-only harness for the base contract',
      );

  @override
  EchoContent parseContent(ActivitySpec spec, ItemPackResolver packs) {
    final JsonReader reader = spec.payloadReader;
    return EchoContent(
      stepCount: reader.optionalInt('stepCount') ?? 3,
      optionCount: reader.optionalInt('optionCount') ?? 4,
    );
  }

  @override
  ActivityCubit<EchoContent, dynamic> createCubit(
    ActivitySession<EchoContent> session,
  ) =>
      EchoCubit(session);

  @override
  ActivityBoardBuilder createBoard() => (
        BuildContext context,
        state,
        ActivityAttemptCallback submit,
      ) =>
          const SizedBox.shrink();
}

/// Builds a spec for the echo engine with full narration in both locales.
ActivitySpec echoSpec({
  int stepCount = 3,
  int optionCount = 4,
  List<String> locales = const <String>['en', 'ar'],
}) {
  return ActivitySpec.fromJson(<String, dynamic>{
    'instanceId': 'test.echo',
    'engineId': 'echo',
    'schemaVersion': 1,
    'locales': locales,
    'narration': const <String, dynamic>{
      'prompt': <String, String>{'en': 'Pick one', 'ar': 'اختر واحدة'},
      'hint1': <String, String>{'en': 'Try again', 'ar': 'حاول مرة أخرى'},
      'hint2': <String, String>{'en': 'Look here', 'ar': 'انظر هنا'},
      'model': <String, String>{'en': 'This one', 'ar': 'هذه هي'},
      'success': <String, String>{'en': 'You did it', 'ar': 'أحسنت'},
    },
    'payload': <String, dynamic>{
      'stepCount': stepCount,
      'optionCount': optionCount,
    },
  });
}
