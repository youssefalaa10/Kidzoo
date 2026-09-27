import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_cubit.dart';

/// Repeating patterns: read the rule, then use it on a position you cannot see.
///
/// The one learning domain the contract has always declared and nothing has
/// ever claimed. It is not an oversight worth leaving: pre-K repeating-pattern
/// skill predicts fifth-grade mathematics after controlling for the rest of
/// early maths, reading and demographics, and no amount of content on any
/// existing engine produces it.
///
/// **Why this is not `sorting` with a different picture.** `sorting` judges
/// category membership — this thing is a fruit, that bin takes fruit — and the
/// verdict for an item is the same wherever it is dropped. Here the same tile
/// is right in one hole and wrong in the next one along, because what is being
/// judged is *position within a sequence*. There is no arrangement of bins that
/// expresses that.
///
/// Like every engine here it names no subject. A unit is a list of item ids; a
/// strip is that unit repeated; a gap is an index. Vine beads, awning stripes,
/// a current, the spacing of stars and a tiled floor are all the same file with
/// a different pack.
class PatternsEngine extends ActivityEngine<PatternsContent> {
  const PatternsEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'patterns',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.patterning},
        // The same interaction `sorting` declares, and for the same reason:
        // drag is the primary route and tap-then-tap is a first-class
        // alternative rather than a fallback. The capability *key* is still
        // unique, because the domain is not classification.
        interactionModes: <InteractionMode>{InteractionMode.dragToTarget},
        contentParameters: <ContentParameter>[
          ContentParameter.text('itemsRef', isRequired: true),
          ContentParameter.list('itemIds',
              description: 'narrow the pack to the tiles this ledge is built '
                  'from'),
          ContentParameter.list('rounds',
              isRequired: true,
              description: 'each with id, unit (2-4 item ids), repeats, gaps, '
                  'an optional mode, its own wording and an optional '
                  'revealLine spoken once the pattern is whole'),
          ContentParameter.enumeration(
            'mode',
            <String>['extend', 'fillGap'],
            description: 'the default for rounds that do not say. `extend` '
                'opens the end of the strip and can be answered by carrying '
                'on; `fillGap` opens the middle and cannot',
          ),
          ContentParameter.integer('revealedRepeats',
              minValue: 1,
              maxValue: 4,
              description: 'whole repetitions guaranteed visible before the '
                  'first gap — the errorless-fading dial, and checked against '
                  'the gaps rather than merely believed'),
          ContentParameter.integer('trayExtraCount',
              minValue: 0,
              maxValue: 4,
              description: 'tiles in the tray that belong in no gap. Without '
                  'at least one, the last gap can be filled by elimination'),
        ],
        adaptationAxis: 'revealedRepeats',
        // No glyphs, no words of its own: a unit is item ids and the wording
        // around it is authored per locale, exactly as `trace_path` is.
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  PatternsContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parsePatternsContent(spec, packs);

  @override
  Iterable<String> assetsFor(PatternsContent content) => content.assetPaths;

  @override
  ActivityCubit<PatternsContent, dynamic> createCubit(
    ActivitySession<PatternsContent> session,
  ) =>
      PatternsCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! PatternStep) {
        return const SizedBox.shrink();
      }
      return PatternsBoard(step: step, state: state, submit: submit);
    };
  }
}
