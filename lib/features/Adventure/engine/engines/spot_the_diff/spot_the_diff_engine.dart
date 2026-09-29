import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_cubit.dart';

/// Two views of one scene, and the child finds what differs.
///
/// Visual discrimination — comparing two things held side by side — is a
/// different skill from searching one scene (`hidden_clue`) or lighting a
/// dark one (`flashlight`), which is what [InteractionMode.compareScene]
/// records. The differences are found in whatever order the child sees them.
class SpotDiffEngine extends ActivityEngine<SpotDiffContent> {
  const SpotDiffEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'spot_the_diff',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.visualSearch},
        interactionModes: <InteractionMode>{InteractionMode.compareScene},
        contentParameters: <ContentParameter>[
          ContentParameter.text('imageLeft',
              isRequired: true,
              description: 'the reference picture; drawn square'),
          ContentParameter.text('imageRight',
              isRequired: true,
              description: 'the same picture with the differences; square'),
          ContentParameter.list('spots',
              isRequired: true,
              description: 'each difference: id, posLeft [x,y], posRight '
                  '[x,y] as 0..1 fractions, hitRadius, label, revealLine'),
        ],
        adaptationAxis: null,
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  SpotDiffContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseSpotDiffContent(spec);

  @override
  Iterable<String> assetsFor(SpotDiffContent content) => content.assetPaths;

  @override
  ActivityCubit<SpotDiffContent, dynamic> createCubit(
    ActivitySession<SpotDiffContent> session,
  ) =>
      SpotDiffCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! SpotDiffStep) {
        return const SizedBox.shrink();
      }
      return SpotDiffBoard(step: step, state: state, submit: submit);
    };
  }
}
