import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/deduction/deduction_cubit.dart';

/// Solve a mystery by ruling things out.
///
/// **Why this is not `multiple_choice`.** There, the child picks the answer
/// from the options. Here they never pick it at all: each clue removes the
/// candidates it cannot be, and the answer is whatever the clues leave. Every
/// tap is an application of a stated rule to a picture, and the last card
/// standing is a conclusion rather than a guess — the "Guess Who?" and
/// Outfoxed! shape, which five-year-olds can carry when each clue is one
/// visible fact. That is [LearningDomain.logic] with
/// [InteractionMode.eliminate], and nothing else in the registry is either.
///
/// Five themes: who carried the page across the sky · which animal left the
/// tracks · whose basket was left at the stall · which shell hid the pearl ·
/// which key opens the door.
class DeductionEngine extends ActivityEngine<DeductionContent> {
  const DeductionEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'deduction',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.logic},
        interactionModes: <InteractionMode>{InteractionMode.eliminate},
        contentParameters: <ContentParameter>[
          ContentParameter.text('itemsRef',
              isRequired: true,
              description: 'the pack the candidates and their facts come from'),
          ContentParameter.list('candidateIds',
              isRequired: true, description: '3..8 pack ids, in slot order'),
          ContentParameter.list('clues',
              isRequired: true,
              description: 'in the order they are given: id, attribute, '
                  'value (kept), label, image, revealLine. Each must rule '
                  'someone out and together they must leave exactly one'),
        ],
        // The dial is not the number of suspects: fewer cards make a
        // different mystery. The ladder narrows the cards that can be tapped.
        adaptationAxis: null,
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  DeductionContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseDeductionContent(spec, packs);

  @override
  Iterable<String> assetsFor(DeductionContent content) => content.assetPaths;

  @override
  ActivityCubit<DeductionContent, dynamic> createCubit(
    ActivitySession<DeductionContent> session,
  ) =>
      DeductionCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! DeductionStep) {
        return const SizedBox.shrink();
      }
      return DeductionBoard(step: step, state: state, submit: submit);
    };
  }
}
