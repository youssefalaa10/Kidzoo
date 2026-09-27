import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/balance_experiment/balance_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_content.dart';
import 'package:kidzo/features/Adventure/engine/engines/code_path/code_path_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/hidden_clue_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/multiple_choice/multiple_choice_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/patterns/patterns_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/trace_path/trace_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/story/adventure_runner_cubit.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

import 'support/disk_content_source.dart';

/// Adventure 1, played start to finish, in both languages.
///
/// Every other suite tests a layer. This one is the thing a person would
/// actually do: open the Adventure, hear the beats, play each activity with the
/// **real** engines, and come out the other side with the page. It exists
/// because each layer passing its own tests never caught that the reveal lines
/// were silent, or that the closing line of an activity was authored and never
/// said — both of which are only visible when you listen to a whole run.
///
/// The spoken transcript is the main assertion. It is the only representation
/// of the Adventure that matches what a child actually receives, since most of
/// them cannot read a word on the screen.
void main() {
  late AppDatabase database;
  late StoryDao dao;
  late AdventureContentBundle bundle;
  late ActivityEngineRegistry registry;
  late int profileId;

  /// Any Arabic letter. Used to check a run never mixes its languages.
  final RegExp arabic = RegExp('[؀-ۿ]');

  setUpAll(() async {
    registry = buildDefaultEngineRegistry();
    bundle = await const AdventureContentLoader(DiskAdventureContentSource())
        .load();
  });

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = StoryDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  /// The attempt a child who knows the answer would make.
  ///
  /// Written out per engine rather than derived from the view, because
  /// "whatever the board highlighted" is how the *scaffolded* path is tested
  /// and would quietly turn this into a test of the hint system.
  ActivityAttempt correctAttemptFor(ActivityState state) {
    final Object? step = state.engineStep;
    if (step is CountingStep) {
      return QuantityAttempt(step.targetCount);
    }
    if (step is MultipleChoiceStep) {
      return ChoiceAttempt(step.question.correctItem.id);
    }
    if (step is SortingStep) {
      return ChoiceAttempt(step.correctBinId);
    }
    if (step is HiddenClueStep) {
      return ChoiceAttempt(step.clue.id);
    }
    if (step is CodePathStep) {
      return SequenceAttempt(
        step.solution.map((PathCommand command) => command.name).toList(),
      );
    }
    if (step is BalanceStep) {
      return QuantityAttempt(step.round.target);
    }
    if (step is PatternStep) {
      return ChoiceAttempt(step.correctItemId);
    }
    if (step is TraceStep) {
      // The tap route, not the drag: a whole stroke is what the board sends
      // for a finger travelling across the figure, and a child who taps the
      // points in order gets there the same way.
      return ChoiceAttempt(step.figure.lastAnchor.id);
    }
    throw StateError('no correct attempt known for ${step.runtimeType}');
  }

  /// One whole run. Returns everything that was said, in order.
  Future<List<String>> playAdventure({
    required String languageCode,
    String adventureId = 'jungle',
    bool answerEverythingWrong = false,
    bool tapFast = false,
  }) async {
    final RecordingActivityNarrator narrator = RecordingActivityNarrator();
    final AdventureRunnerCubit runner = AdventureRunnerCubit(
      bundle: bundle,
      adventureId: adventureId,
      profileId: profileId,
      storyDao: dao,
    );
    await runner.start();

    int guard = 0;
    while (runner.state.status == AdventureRunnerStatus.playing && guard < 90) {
      guard++;
      final StoryNode node = runner.state.node!;

      if (!node.isActivity) {
        // A narration beat: the runner screen speaks each line, then moves on.
        for (final line in node.lines) {
          await narrator.speak(line.resolve(languageCode));
        }
        await runner.continueStory();
        if (tapFast) {
          // The extra taps a real child lands while the app is still moving.
          await runner.continueStory();
        }
        continue;
      }

      final ActivitySpec spec = bundle.requireActivity(node.activityRef!);
      final ActivityEngine<ActivityContent> engine =
          registry.require(spec.engineId);
      final ActivityCubit<ActivityContent, dynamic> cubit =
          engine.createCubit(engine.createSession(
        spec: spec,
        services: ActivityServices(
          narrator: narrator,
          soundboard: RecordingActivitySoundboard(),
          random: Random(7),
          languageCode: languageCode,
        ),
        packs: bundle.packResolver,
        storyNodeId: node.nodeId,
      ));
      await cubit.start();

      int stepGuard = 0;
      while (cubit.state.status == ActivityStatus.running && stepGuard < 120) {
        stepGuard++;
        if (answerEverythingWrong) {
          await cubit.submit(const ChoiceAttempt('__definitely_wrong__'));
        } else {
          await cubit.submit(correctAttemptFor(cubit.state));
          if (tapFast) {
            await cubit.submit(correctAttemptFor(cubit.state));
          }
        }
      }

      expect(cubit.state.status, ActivityStatus.finished,
          reason: '${node.nodeId} never terminated');
      await runner.completeActivity(cubit.state.result);
      await cubit.close();
    }

    expect(runner.state.status, AdventureRunnerStatus.finished,
        reason: 'the Adventure did not reach its end');
    await runner.close();
    return narrator.spoken;
  }

  for (final String locale in <String>['en', 'ar']) {
    group('Adventure 1 in $locale', () {
      test('plays from the first beat to the page, answering well', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale);

        expect(spoken, isNotEmpty);
        // The page is in the book, which is the entire point of the chapter.
        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(rewards.map((StoryReward r) => r.rewardId), contains('green_page'));
      });

      test('never mixes the two languages in one run', () async {
        // The real failure this guards against is not a missing translation -
        // the parity tests cover that - but a line assembled in code, which
        // would come out English inside an Arabic run and be invisible to every
        // per-file check.
        final List<String> spoken = await playAdventure(languageCode: locale);

        for (final String line in spoken) {
          if (locale == 'ar') {
            expect(arabic.hasMatch(line), isTrue,
                reason: 'an Arabic run said "$line", which has no Arabic in it');
          } else {
            expect(arabic.hasMatch(line), isFalse,
                reason: 'an English run said "$line"');
          }
        }
      });

      test('never says the same thing twice in a row', () async {
        // A repeat back to back is the signature of a double-fired beat or a
        // prompt re-spoken on a rebuild, and it reads to a child as the app
        // being stuck.
        final List<String> spoken = await playAdventure(languageCode: locale);

        for (int index = 1; index < spoken.length; index++) {
          expect(spoken[index], isNot(spoken[index - 1]),
              reason: 'said "${spoken[index]}" twice running');
        }
      });

      test('speaks every authored clue on the way through', () async {
        final List<String> spoken = await playAdventure(languageCode: locale);

        final ActivitySpec ask = bundle.requireActivity('jungle_ask_animals');
        final List<dynamic> questions =
            ask.payload['questions'] as List<dynamic>;
        for (final dynamic raw in questions) {
          final Map<dynamic, dynamic> question = raw as Map<dynamic, dynamic>;
          final String reveal =
              (question['revealLine'] as Map<dynamic, dynamic>)[locale]
                  as String;
          expect(spoken, contains(reveal),
              reason: 'the clue from "${question['id']}" was never said, so '
                  'the beat that depends on it talks about something the '
                  'child was never told');
        }
      });

      test('a child who gets everything wrong still reaches the page',
          () async {
        // The house rule, end to end: the story is never gated on performance.
        await playAdventure(
          languageCode: locale,
          answerEverythingWrong: true,
        );

        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(rewards.map((StoryReward r) => r.rewardId),
            contains('green_page'));
      });

      test('fast repeated taps do not skip a beat or double a page', () async {
        await playAdventure(languageCode: locale, tapFast: true);

        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
          rewards.where((StoryReward r) => r.rewardId == 'green_page').length,
          1,
          reason: 'the page must be granted exactly once however hard the '
              'child taps',
        );
      });
    });
  }

  for (final String locale in <String>['en', 'ar']) {
    group('Adventure 2 in $locale', () {
      // The same run, over a chapter twice the length and three engines that
      // did not exist when the first one was written. It is here rather than in
      // a market-only file because the thing worth checking is that nothing
      // about the story layer needed to know a second Adventure had arrived.
      test('plays from the first beat to the page, answering well', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'market');

        expect(spoken, isNotEmpty);
        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(rewards.map((StoryReward r) => r.rewardId),
            contains('amber_page'));
      });

      test('never mixes the two languages in one run', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'market');

        for (final String line in spoken) {
          if (locale == 'ar') {
            expect(arabic.hasMatch(line), isTrue,
                reason: 'an Arabic run said "$line", which has no Arabic in it');
          } else {
            expect(arabic.hasMatch(line), isFalse,
                reason: 'an English run said "$line"');
          }
        }
      });

      test('never says the same thing twice in a row', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'market');

        for (int index = 1; index < spoken.length; index++) {
          expect(spoken[index], isNot(spoken[index - 1]),
              reason: 'said "${spoken[index]}" twice running');
        }
      });

      test('every activity result changes the market, out loud', () async {
        // The test that separates a story from a themed list of drills: each
        // activity's reveal line is spoken, so what the child did is what the
        // next beat is about. An activity whose outcome nothing refers to is
        // decoration.
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'market');

        for (final String activityId in <String>[
          'market_deliver',
          'market_weigh_orders',
          'market_mend_sign',
          'market_fruit_bowl',
          'market_lend_a_hand',
        ]) {
          final ActivitySpec spec = bundle.requireActivity(activityId);
          final List<String> reveals = <String>[];
          void collect(Object? node) {
            if (node is Map) {
              final Object? reveal = node['revealLine'];
              if (reveal is Map && reveal[locale] is String) {
                reveals.add(reveal[locale] as String);
              }
              node.values.forEach(collect);
            } else if (node is List) {
              node.forEach(collect);
            }
          }

          collect(spec.payload);
          expect(reveals, isNotEmpty,
              reason: '$activityId authored no reveal lines, so finishing it '
                  'tells the child nothing');
          for (final String reveal in reveals) {
            expect(spoken, contains(reveal),
                reason: '$activityId never said "$reveal", so the thing the '
                    'child just did changed nothing the story mentions');
          }
        }
      });

      test('a child who gets everything wrong still reaches the page',
          () async {
        await playAdventure(
          languageCode: locale,
          adventureId: 'market',
          answerEverythingWrong: true,
        );

        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
            rewards.map((StoryReward r) => r.rewardId), contains('amber_page'));
      });

      test('fast repeated taps do not skip a beat or double a page', () async {
        await playAdventure(
          languageCode: locale,
          adventureId: 'market',
          tapFast: true,
        );

        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
          rewards.where((StoryReward r) => r.rewardId == 'amber_page').length,
          1,
        );
      });
    });
  }

  for (final String locale in <String>['en', 'ar']) {
    group('Adventure 3 in $locale', () {
      // The ocean, and the first chapter whose climax is an engine that did not
      // exist when the chapter before it shipped. Same battery as the market,
      // because the point of the battery is that a new chapter should need no
      // new kind of assurance.
      test('plays from the first beat to the page, answering well', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'ocean');

        expect(spoken, isNotEmpty);
        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
            rewards.map((StoryReward r) => r.rewardId), contains('blue_page'));
      });

      test('never mixes the two languages in one run', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'ocean');

        for (final String line in spoken) {
          if (locale == 'ar') {
            expect(arabic.hasMatch(line), isTrue,
                reason: 'an Arabic run said "$line", which has no Arabic in it');
          } else {
            expect(arabic.hasMatch(line), isFalse,
                reason: 'an English run said "$line"');
          }
        }
      });

      test('never says the same thing twice in a row', () async {
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'ocean');

        for (int index = 1; index < spoken.length; index++) {
          expect(spoken[index], isNot(spoken[index - 1]),
              reason: 'said "${spoken[index]}" twice running');
        }
      });

      test('every activity result changes the sea, out loud', () async {
        // The chain the chapter is built on, checked out loud: the floats
        // become the lift, the lift carries the light, the light shows the
        // wall, the wall shows the gate. An activity whose outcome nothing
        // refers to is decoration, however good it looks.
        final List<String> spoken =
            await playAdventure(languageCode: locale, adventureId: 'ocean');

        for (final String activityId in <String>[
          'ocean_load_the_basket',
          'ocean_light_her_shell',
          'ocean_light_the_wall',
          'ocean_read_the_current',
        ]) {
          final ActivitySpec spec = bundle.requireActivity(activityId);
          final List<String> reveals = <String>[];
          void collect(Object? node) {
            if (node is Map) {
              final Object? reveal = node['revealLine'];
              if (reveal is Map && reveal[locale] is String) {
                reveals.add(reveal[locale] as String);
              }
              node.values.forEach(collect);
            } else if (node is List) {
              node.forEach(collect);
            }
          }

          collect(spec.payload);
          expect(reveals, isNotEmpty,
              reason: '$activityId authored no reveal lines, so finishing it '
                  'tells the child nothing');
          for (final String reveal in reveals) {
            expect(spoken, contains(reveal),
                reason: '$activityId never said "$reveal", so the thing the '
                    'child just did changed nothing the story mentions');
          }
        }
      });

      test('a child who gets everything wrong still reaches the page',
          () async {
        await playAdventure(
          languageCode: locale,
          adventureId: 'ocean',
          answerEverythingWrong: true,
        );

        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
            rewards.map((StoryReward r) => r.rewardId), contains('blue_page'));
      });

      test('fast repeated taps do not skip a beat or double a page', () async {
        await playAdventure(
          languageCode: locale,
          adventureId: 'ocean',
          tapFast: true,
        );

        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
          rewards.where((StoryReward r) => r.rewardId == 'blue_page').length,
          1,
        );
      });
    });
  }

  group('The arc plays as one journey', () {
    test('all three chapters run back to back and every page comes home',
        () async {
      // Finishing the jungle is what opens the market, and the market is what
      // opens the ocean, so all three have to work in sequence against one
      // profile rather than only in isolation.
      await playAdventure(languageCode: 'en');
      await playAdventure(languageCode: 'en', adventureId: 'market');
      await playAdventure(languageCode: 'en', adventureId: 'ocean');

      final List<StoryReward> rewards = await dao.rewardsFor(profileId);
      expect(
        rewards.map((StoryReward r) => r.rewardId).toSet(),
        <String>{'green_page', 'amber_page', 'blue_page'},
      );
    });

    test('each chapter uses a mechanic the one before it did not', () async {
      // The rule that keeps a second Adventure from being the first one
      // repainted: every chapter has to bring an interaction the child has not
      // met yet, or it is content pretending to be progress.
      final Set<String> jungleEngines = <String>{
        for (final StoryNode node in bundle.requireAdventure('jungle').nodes)
          if (node.isActivity)
            bundle.requireActivity(node.activityRef!).engineId,
      };
      final Set<String> marketEngines = <String>{
        for (final StoryNode node in bundle.requireAdventure('market').nodes)
          if (node.isActivity)
            bundle.requireActivity(node.activityRef!).engineId,
      };
      final Set<String> oceanEngines = <String>{
        for (final StoryNode node in bundle.requireAdventure('ocean').nodes)
          if (node.isActivity)
            bundle.requireActivity(node.activityRef!).engineId,
      };

      expect(marketEngines.difference(jungleEngines), isNotEmpty,
          reason: 'the market is the jungle repainted');
      expect(marketEngines.intersection(jungleEngines), isNotEmpty,
          reason: 'nothing was reused, which means the engines are not '
              'actually reusable');
      expect(
          oceanEngines.difference(marketEngines.union(jungleEngines)),
          isNotEmpty,
          reason: 'the ocean brings nothing the child has not already met');
      expect(oceanEngines.intersection(marketEngines), isNotEmpty,
          reason: 'the ocean reused nothing, which would mean every chapter '
              'costs a new engine');
    });

    test('no chapter repeats an interaction inside itself', () async {
      // Variety within one sitting, not only between chapters. Six activities
      // that are six rounds of the same interaction is the failure this
      // catches, and it is invisible to every per-activity test.
      for (final String adventureId in <String>['jungle', 'market', 'ocean']) {
        final List<String> engines = <String>[
          for (final StoryNode node
              in bundle.requireAdventure(adventureId).nodes)
            if (node.isActivity)
              bundle.requireActivity(node.activityRef!).engineId,
        ];
        expect(engines.toSet().length, engines.length,
            reason: '$adventureId asks for the same interaction twice: '
                '$engines');
      }
    });
  });

  group('Interrupting a run', () {
    test('backing out mid-Adventure resumes on the same beat', () async {
      final AdventureRunnerCubit first = AdventureRunnerCubit(
        bundle: bundle,
        adventureId: 'jungle',
        profileId: profileId,
        storyDao: dao,
      );
      await first.start();
      await first.continueStory();
      final String? leftOn = first.state.node?.nodeId;
      expect(leftOn, isNotNull);
      await first.close();

      final AdventureRunnerCubit second = AdventureRunnerCubit(
        bundle: bundle,
        adventureId: 'jungle',
        profileId: profileId,
        storyDao: dao,
      );
      await second.start();
      expect(second.state.node?.nodeId, leftOn);
      await second.close();
    });

    test('an abandoned activity does not advance the story', () async {
      final AdventureRunnerCubit runner = AdventureRunnerCubit(
        bundle: bundle,
        adventureId: 'jungle',
        profileId: profileId,
        storyDao: dao,
      );
      await runner.start();
      await runner.continueStory();
      final String? activityNode = runner.state.node?.nodeId;
      expect(runner.state.isOnActivity, isTrue);

      await runner.completeActivity(const ActivityResult(
        completion: ActivityCompletion.abandoned,
        score: 0,
        maxScore: 0,
        stepsTotal: 0,
        stepsIndependent: 0,
        hintsUsed: 0,
        durationSeconds: 0,
      ));

      expect(runner.state.node?.nodeId, activityNode,
          reason: 'a beat the child never played must not be skipped');
      await runner.close();
    });
  });
}
