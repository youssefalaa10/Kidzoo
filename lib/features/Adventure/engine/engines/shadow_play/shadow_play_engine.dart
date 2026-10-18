import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/shadow_play/shadow_play_cubit.dart';

/// Slide something between a light and a wall until its shadow fits.
///
/// **Why this is not `balance_experiment`.** Both let a child act before
/// being judged, but the balance composes a quantity out of parts; here there
/// is one object and one continuous dial, and the thing learned is a
/// relationship — nearer the light, bigger the shadow — that the child finds
/// by moving it and watching. Nothing else in the app has a continuous input
/// whose effect is shown somewhere other than under the finger, which is what
/// [InteractionMode.slideToAdjust] records.
///
/// Five themes: stars being covered · a shadow-puppet show in camp · a
/// sundial in the market · a lantern in a cave · a reading lamp at bedtime.
class ShadowPlayEngine extends ActivityEngine<ShadowPlayContent> {
  const ShadowPlayEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'shadow_play',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.causeAndEffect},
        interactionModes: <InteractionMode>{InteractionMode.slideToAdjust},
        contentParameters: <ContentParameter>[
          ContentParameter.text('itemsRef',
              isRequired: true, description: 'the pack the objects come from'),
          ContentParameter.list('rounds',
              isRequired: true,
              description: 'each: id, itemId, targetPercent, startPercent, '
                  'label, revealLine. At least one must need a bigger shadow '
                  'and one a smaller'),
          ContentParameter.integer('tolerancePercent',
              minValue: 3,
              maxValue: 15,
              description: 'how far from the target still fits, in percent '
                  'of the track'),
          ContentParameter.list('trackPercent',
              description: '[nearest, furthest] the object can go, as percent '
                  'of the way from the light to the wall'),
          ContentParameter.text('lightImage',
              description: 'what is shining'),
          ContentParameter.text('wallImage',
              description: 'what the shadow falls on, drawn behind it'),
        ],
        adaptationAxis: 'tolerancePercent',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  ShadowPlayContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseShadowPlayContent(spec, packs);

  @override
  Iterable<String> assetsFor(ShadowPlayContent content) => content.assetPaths;

  @override
  ActivityCubit<ShadowPlayContent, dynamic> createCubit(
    ActivitySession<ShadowPlayContent> session,
  ) =>
      ShadowPlayCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! ShadowStep) {
        return const SizedBox.shrink();
      }
      return ShadowPlayBoard(step: step, state: state, submit: submit);
    };
  }
}
