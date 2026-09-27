import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/current_rider/current_rider_cubit.dart';

/// Aim the forces, let go, and live with what they do.
///
/// **Why this is not `code_path`.** That engine composes a list of
/// instructions and the rider obeys them in order; the child is the author of
/// a program and the world is inert. Here the child changes *the world* — two
/// or three gates — and then has no say at all: the rider obeys the water, not
/// them. The reasoning runs the other way round. In `code_path` you ask "what
/// should she do?"; here you ask "what will happen to her?", which is
/// prediction rather than composition, and it is the harder and earlier of the
/// two. No arrangement of `code_path` content produces it, because `code_path`
/// has no notion of a board that acts on its own.
///
/// That is why it declares [InteractionMode.setDirection] rather than
/// `orderSequence`. Claiming `orderSequence` would collide with `code_path`'s
/// capability key — correctly, because it would be describing `code_path`.
///
/// The engine knows nothing about water. A round is a grid, a start, a
/// destination, blockers and some cells that redirect whatever crosses them.
/// Currents, conveyor belts, wind, points on a railway and a marble run are
/// the same file with different art.
class CurrentRiderEngine extends ActivityEngine<CurrentRiderContent> {
  const CurrentRiderEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'current_rider',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.spatialReasoning},
        interactionModes: <InteractionMode>{InteractionMode.setDirection},
        contentParameters: <ContentParameter>[
          ContentParameter.text('itemsRef', isRequired: true),
          ContentParameter.list('rounds',
              isRequired: true,
              description: 'each a board: id, columns, rows, start, startFlow, '
                  'goal, rocks, one to three gates, its own wording and an '
                  'optional revealLine spoken once it is crossed'),
          ContentParameter.text('riderImage',
              description: 'who is carried; defaults to the pack item named by '
                  'riderImageItemId'),
          ContentParameter.text('riderImageItemId'),
          ContentParameter.text('goalImage'),
          ContentParameter.text('goalImageItemId'),
          ContentParameter.text('rockImage'),
          ContentParameter.text('rockImageItemId'),
        ],
        // Boards get harder by having more gates, which is a property of the
        // round rather than a dial on the activity, so there is nothing
        // honest for the between-node nudge to step along. Declaring one
        // anyway would be a knob that moved nothing.
        adaptationAxis: null,
        // Arrows and a grid. No words of its own in either direction, and
        // nothing that mirrors wrongly in Arabic: the board is a map, and a
        // map is not mirrored when the text around it is.
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  CurrentRiderContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseCurrentRiderContent(spec, packs);

  @override
  Iterable<String> assetsFor(CurrentRiderContent content) => content.assetPaths;

  @override
  ActivityCubit<CurrentRiderContent, dynamic> createCubit(
    ActivitySession<CurrentRiderContent> session,
  ) =>
      CurrentRiderCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! CurrentRiderStep) {
        return const SizedBox.shrink();
      }
      return CurrentRiderBoard(step: step, state: state, submit: submit);
    };
  }
}
