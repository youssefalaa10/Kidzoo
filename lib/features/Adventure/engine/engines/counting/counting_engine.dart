import 'package:flutter/widgets.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_board.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';

/// Counting and quantity matching.
///
/// This engine is the platform's own proof: the same code counts animals in the
/// Jungle, fruit in the Market and stars among the stars, and the only thing
/// that changes between them is `itemsRef` and `presentation`. **It never names
/// a domain** — if the word "animal" ever appears in this folder, the
/// abstraction has leaked and the registry test is about to have a bad day.
class CountingEngine extends ActivityEngine<CountingContent> {
  const CountingEngine();

  @override
  ActivityEngineDescriptor get descriptor => const ActivityEngineDescriptor(
        engineId: 'counting',
        kind: EngineKind.reusable,
        learningDomains: <LearningDomain>{LearningDomain.counting},
        interactionModes: <InteractionMode>{InteractionMode.stateQuantity},
        contentParameters: <ContentParameter>[
          ContentParameter.enumeration(
              'mode', <String>['countAndPick', 'giveN'],
              description: 'countAndPick asks "how many"; giveN asks the child '
                  'to produce a set, which is the real cardinality test'),
          ContentParameter.integer('targetCount',
              minValue: 1,
              maxValue: 10,
              description:
                  'a fixed count, when the number matters to the story'),
          ContentParameter.list('countRange',
              description: '[min, max] when the count may vary per round'),
          ContentParameter.enumeration(
            'layout',
            <String>['dice', 'tenFrame', 'linear', 'scatter', 'random'],
            description: 'ordered easiest to hardest; structured arrangements '
                'are recognised faster than scattered ones',
          ),
          ContentParameter.integer('roundCount', minValue: 1, maxValue: 12),
          ContentParameter.integer('optionSpread',
              minValue: 1,
              maxValue: 5,
              description: 'how far the numeral choices spread either side of '
                  'the answer; the errorless-fading dial'),
          ContentParameter.text('itemsRef', description: 'e.g. packs/animals'),
          ContentParameter.list('itemIds',
              description: 'narrow the pack to specific items'),
          ContentParameter.list('rounds',
              description: 'authored rounds: each names its own itemId, '
                  'targetCount and wording. Present them and the generated '
                  'path is not used at all. Use these whenever the number '
                  'matters to the story — a later beat cannot say "nine '
                  'watchers" about a count drawn at random, and two random '
                  'rounds can land on the same answer, which reads to a child '
                  'as the app repeating itself'),
        ],
        adaptationAxis: 'targetCount',
        supportedLocales: <String>{'en', 'ar'},
      );

  @override
  CountingContent parseContent(ActivitySpec spec, ItemPackResolver packs) =>
      parseCountingContent(spec, packs);

  @override
  Iterable<String> assetsFor(CountingContent content) => content.assetPaths;

  @override
  ActivityCubit<CountingContent, dynamic> createCubit(
    ActivitySession<CountingContent> session,
  ) =>
      CountingCubit(session);

  @override
  ActivityBoardBuilder createBoard() {
    return (
      BuildContext context,
      ActivityState state,
      ActivityAttemptCallback submit,
    ) {
      final Object? step = state.engineStep;
      if (step is! CountingStep) {
        return const SizedBox.shrink();
      }
      return CountingBoard(
        step: step,
        state: state,
        submit: submit,
        languageCode: state.languageCode,
      );
    };
  }
}
