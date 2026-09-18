// `drift` and `matcher` both export isNull/isNotNull. Only Value is needed
// from drift here, so hide the rest rather than prefixing every matcher.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';

/// Story persistence, against a real in-memory SQLite.
///
/// Resume is the reason this is worth testing properly rather than by hand: a
/// child of this age abandons an app mid-activity constantly, and a story that
/// restarts from the beginning each time is a story they never finish.
void main() {
  late AppDatabase database;
  late StoryDao dao;
  late int profileId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = StoryDao(database);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  group('Resume', () {
    test('an untouched adventure has no chapter row', () async {
      expect(await dao.chapterFor(profileId, 'jungle'), isNull);
    });

    test('entering a node records where to come back to', () async {
      await dao.saveResumePoint(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n3',
      );
      final chapter = await dao.chapterFor(profileId, 'jungle');
      expect(chapter, isNotNull);
      expect(chapter!.currentNodeId, 'jungle.n3');
      expect(chapter.isCompleted, isFalse);
    });

    test('moving on updates the resume point rather than adding a row',
        () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n1');
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n2');

      final chapters = await dao.chaptersFor(profileId);
      expect(chapters.length, 1);
      expect(chapters.single.currentNodeId, 'jungle.n2');
    });

    test('completing clears the resume point and stamps the time', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n8');
      await dao.markChapterCompleted(
          profileId: profileId, adventureId: 'jungle');

      final chapter = await dao.chapterFor(profileId, 'jungle');
      expect(chapter!.isCompleted, isTrue);
      expect(chapter.currentNodeId, isNull);
      expect(chapter.completedAt, isNotNull);
    });

    test('two profiles keep separate stories', () async {
      final int otherProfile = await database.into(database.profiles).insert(
            ProfilesCompanion.insert(name: 'Sibling'),
          );
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n2');
      await dao.saveResumePoint(
          profileId: otherProfile, adventureId: 'jungle', nodeId: 'jungle.n6');

      expect((await dao.chapterFor(profileId, 'jungle'))!.currentNodeId,
          'jungle.n2');
      expect((await dao.chapterFor(otherProfile, 'jungle'))!.currentNodeId,
          'jungle.n6');
    });
  });

  group('Node results', () {
    test('a completed node is recorded with its mastery signals', () async {
      await dao.saveNodeResult(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n2',
        completion: 'completed',
        stepsTotal: 3,
        stepsIndependent: 2,
        hintsUsed: 1,
        score: 26,
        durationSeconds: 48,
      );

      final rows = await dao.nodesFor(profileId, 'jungle');
      expect(rows.single.stepsIndependent, 2);
      expect(rows.single.hintsUsed, 1);
      expect(rows.single.score, 26);
    });

    test('replaying a node updates it rather than duplicating it', () async {
      await dao.saveNodeResult(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n2',
        completion: 'completed',
        score: 10,
      );
      await dao.saveNodeResult(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n2',
        completion: 'completed',
        score: 30,
      );

      final rows = await dao.nodesFor(profileId, 'jungle');
      expect(rows.length, 1);
      expect(rows.single.score, 30);
    });

    test('completedNodeIds ignores abandoned nodes', () async {
      await dao.saveNodeResult(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n2',
        completion: 'completed',
      );
      await dao.saveNodeResult(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n3',
        completion: 'abandoned',
      );

      expect(await dao.completedNodeIds(profileId, 'jungle'),
          <String>{'jungle.n2'});
    });
  });

  group('Rewards', () {
    test('a page is granted once and stays granted', () async {
      await dao.grantReward(
          profileId: profileId, rewardId: 'green_page', adventureId: 'jungle');
      await dao.grantReward(
          profileId: profileId, rewardId: 'green_page', adventureId: 'jungle');

      final rewards = await dao.rewardsFor(profileId);
      expect(rewards.length, 1,
          reason: 'replaying an Adventure must not duplicate its page');
      expect(rewards.single.rewardId, 'green_page');
    });

    test('resetting an adventure keeps the page already earned', () async {
      await dao.grantReward(
          profileId: profileId, rewardId: 'green_page', adventureId: 'jungle');
      await dao.saveNodeResult(
        profileId: profileId,
        adventureId: 'jungle',
        nodeId: 'jungle.n2',
        completion: 'completed',
      );
      await dao.resetAdventure(profileId: profileId, adventureId: 'jungle');

      expect(await dao.nodesFor(profileId, 'jungle'), isEmpty);
      expect(await dao.chapterFor(profileId, 'jungle'), isNull);
      expect((await dao.rewardsFor(profileId)).length, 1,
          reason: 'pages are not scarce; replaying must not take one back');
    });
  });

  group('Telemetry', () {
    test('motor and knowledge errors are stored distinctly', () async {
      await dao.recordAttempt(
        profileId: profileId,
        activityId: 'jungle.sort_watchers',
        stepIndex: 0,
        attemptIndex: 1,
        outcome: 'wrongSlotButRightItem',
        scaffoldLevel: 'gentleRetry',
        elapsedMilliseconds: 1200,
        storyNodeId: 'jungle.n4',
      );
      await dao.recordAttempt(
        profileId: profileId,
        activityId: 'jungle.sort_watchers',
        stepIndex: 0,
        attemptIndex: 2,
        outcome: 'wrongItem',
        scaffoldLevel: 'narrowed',
        elapsedMilliseconds: 2400,
        storyNodeId: 'jungle.n4',
      );

      final attempts = await dao.attemptsFor(profileId);
      expect(attempts.length, 2);
      expect(
        attempts.map((a) => a.outcome).toSet(),
        <String>{'wrongSlotButRightItem', 'wrongItem'},
        reason: 'one means the targets are too small, the other means more '
            'teaching — collapsing them loses the only useful signal',
      );
      expect(attempts.every((a) => a.storyNodeId == 'jungle.n4'), isTrue);
    });

    test('attempts can be filtered to one activity', () async {
      await dao.recordAttempt(
        profileId: profileId,
        activityId: 'a',
        stepIndex: 0,
        attemptIndex: 1,
        outcome: 'correct',
        scaffoldLevel: 'initial',
        elapsedMilliseconds: 100,
      );
      await dao.recordAttempt(
        profileId: profileId,
        activityId: 'b',
        stepIndex: 0,
        attemptIndex: 1,
        outcome: 'correct',
        scaffoldLevel: 'initial',
        elapsedMilliseconds: 100,
      );

      expect((await dao.attemptsFor(profileId, activityId: 'a')).length, 1);
    });
  });

  group('Schema', () {
    test('the database reports schema v3', () {
      expect(database.schemaVersion, 3);
    });

    test('GameScores accepts the new nullable story columns', () async {
      await database.into(database.gameScores).insert(
            GameScoresCompanion.insert(
              profileId: profileId,
              gameKey: 'jungle.count_watchers',
              score: 30,
              maxScore: const Value<int?>(40),
              starsEarned: const Value<int?>(2),
              durationSeconds: const Value<int?>(55),
              storyNodeId: const Value<String?>('jungle.n3'),
            ),
          );
      final rows = await database.select(database.gameScores).get();
      expect(rows.single.storyNodeId, 'jungle.n3');
      expect(rows.single.maxScore, 40);
    });

    test('rows written the old way still work', () async {
      // Every GameScores row that already exists has none of the v3 columns.
      await database.into(database.gameScores).insert(
            GameScoresCompanion.insert(
              profileId: profileId,
              gameKey: 'fruits',
              score: 12,
            ),
          );
      final rows = await database.select(database.gameScores).get();
      expect(rows.single.maxScore, isNull);
      expect(rows.single.storyNodeId, isNull);
    });
  });
}
