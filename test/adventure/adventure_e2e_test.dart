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
import 'package:kidzo/features/Adventure/engine/engines/counting/counting_cubit.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/hidden_clue_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/multiple_choice/multiple_choice_engine.dart';
import 'package:kidzo/features/Adventure/engine/engines/sorting/sorting_engine.dart';
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
    bundle =
        await const AdventureContentLoader(DiskAdventureContentSource()).load();
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
    throw StateError('no correct attempt known for ${step.runtimeType}');
  }

  /// One whole run. Returns everything that was said, in order.
  Future<List<String>> playAdventure({
    required String languageCode,
    bool answerEverythingWrong = false,
    bool tapFast = false,
  }) async {
    final RecordingActivityNarrator narrator = RecordingActivityNarrator();
    final AdventureRunnerCubit runner = AdventureRunnerCubit(
      bundle: bundle,
      adventureId: 'jungle',
      profileId: profileId,
      storyDao: dao,
    );
    await runner.start();

    int guard = 0;
    while (runner.state.status == AdventureRunnerStatus.playing && guard < 60) {
      guard++;
      final StoryNode? node = runner.state.node;

      if (!node!.isActivity) {
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
        final List<String> spoken = await playAdventure(languageCode: locale);

        expect(spoken, isNotEmpty);
        // The page is in the book, which is the entire point of the chapter.
        final List<StoryReward> rewards = await dao.rewardsFor(profileId);
        expect(
            rewards.map((StoryReward r) => r.rewardId), contains('green_page'));
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
                reason:
                    'an Arabic run said "$line", which has no Arabic in it');
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
          final String reveal = (question['revealLine']
              as Map<dynamic, dynamic>)[locale] as String;
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
        expect(
            rewards.map((StoryReward r) => r.rewardId), contains('green_page'));
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
