import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/mix_lab/mix_lab_cubit.dart';

/// Put things together and see what they make.
///
/// **Why this is not `sorting` or `balance_experiment`.** Both judge parts:
/// where each one went, or how many there are. Here the parts disappear into
/// the whole and only the whole is judged, so the same ink is right in one
/// round and wrong in the next depending on what it is with. That is
/// [InteractionMode.combine], and the domain is cause and effect because the
/// rule — yellow and blue make green — is found by trying, never stated.
///
/// Five themes: stardust colours · jungle berry paint · market juice stall ·
/// ocean coral dyes · a potion workshop.
class MixLabEngine extends ActivityEngine<MixLabContent> {
  const MixLabEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'mix_lab',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.causeAndEffect},
        interactionModes: <InteractionMode>{InteractionMode.combine},
        contentParameters: <ContentParameter>[
          ContentParameter.list('inks',
              isRequired: true,
              description: '2..4 things to mix: id, color "#RRGGBB", label'),
          ContentParameter.list('mixes',
              isRequired: true,
              description: 'what every combination makes: of [ids], color, '
                  'label. Must cover every combination'),
          ContentParameter.list('rounds',
              isRequired: true,
              description: 'each: id, make [ink ids], label, revealLine'),
          ContentParameter.text('emptyColor',
              description: 'the vessel with nothing in it, "#RRGGBB"'),
          ContentParameter.text('vesselImage',
              description: 'a white picture the mix tints'),
        ],
        // Nothing here gets easier by being smaller: fewer inks change the
        // question, not its difficulty. The ladder points at the right inks.
        adaptationAxis: null,
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  MixLabContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseMixLabContent(spec);

  @override
  Iterable<String> assetsFor(MixLabContent content) => content.assetPaths;

  @override
  ActivityCubit<MixLabContent, dynamic> createCubit(
    ActivitySession<MixLabContent> session,
  ) =>
      MixLabCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! MixStep) {
        return const SizedBox.shrink();
      }
      return MixLabBoard(step: step, state: state, submit: submit);
    };
  }
}
