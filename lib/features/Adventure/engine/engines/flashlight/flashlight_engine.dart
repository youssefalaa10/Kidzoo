import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/flashlight/flashlight_cubit.dart';

/// Searching a place that is dark, with a light the child aims.
///
/// **Why this is not `hidden_clue` with the brightness turned down.** There,
/// the scene is fully painted and the child's whole job is discrimination:
/// everything is visible at once and the answer is merely small, or behind a
/// leaf. The search is over the picture. Here the picture does not exist until
/// the child makes it — what is visible is a function of where they put the
/// beam — so the search is over *space*, and the skill is covering ground
/// systematically rather than picking a target out of clutter. Those are
/// different enough that no arrangement of hidden-clue content produces this
/// one: `hidden_clue` has no light to move, and giving it one would make every
/// existing scene in the app darker.
///
/// It declares [InteractionMode.sweepScene] alongside [InteractionMode.tapInScene]
/// for exactly that reason. Claiming only `tapInScene` would collide with
/// `hidden_clue`'s capability key — correctly, because it would be describing
/// `hidden_clue`.
///
/// Like every engine here it names no subject. A find is an image, a position
/// and a label; the dark is the chapter's accent taken down to almost black. A
/// cave, a night forest, a power cut and the bottom of the sea are the same
/// file with different art.
class FlashlightEngine extends ActivityEngine<FlashlightContent> {
  const FlashlightEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'flashlight',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.visualSearch},
        interactionModes: <InteractionMode>{
          InteractionMode.sweepScene,
          InteractionMode.tapInScene,
        },
        contentParameters: <ContentParameter>[
          ContentParameter.list('finds',
              isRequired: true,
              description: 'what is waiting in the dark, in the order it is '
                  'asked for: id, positionPercent, image, label, an optional '
                  'revealLine, and a kind of find, creature or exit'),
          ContentParameter.list('beamStartPercent',
              isRequired: true,
              description: '[x, y] where the light begins, so the opening '
                  'frame is the same on every device and in every test'),
          ContentParameter.integer('beamPercent',
              minValue: 6,
              maxValue: 50,
              description: 'the beam radius as a percentage of the short side'),
          ContentParameter.integer('maxBeamPercent',
              minValue: 6,
              maxValue: 60,
              description: 'how wide the child can open it. The gap between '
                  'this and beamPercent is the room the creature beat needs'),
          ContentParameter.list('props',
              description: 'scenery, as dark as everything else until the beam '
                  'reaches it — which is what makes sweeping worth doing'),
          ContentParameter.text('ground',
              description: 'a soft band along the bottom to stand things on'),
          ContentParameter.text('sceneImage'),
          ContentParameter.text('itemsRef'),
          ContentParameter.integer('hitToleranceFraction'),
        ],
        // The dial that makes the scene easier is the size of the light, not
        // the number of things in it: a child who is struggling needs to see
        // more at once, and removing objects would change what the scene says.
        adaptationAxis: 'beamPercent',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  FlashlightContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseFlashlightContent(spec, packs);

  @override
  Iterable<String> assetsFor(FlashlightContent content) => content.assetPaths;

  @override
  ActivityCubit<FlashlightContent, dynamic> createCubit(
    ActivitySession<FlashlightContent> session,
  ) =>
      FlashlightCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! FlashlightStep) {
        return const SizedBox.shrink();
      }
      return FlashlightBoard(step: step, state: state, submit: submit);
    };
  }
}
