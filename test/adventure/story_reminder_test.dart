import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/features/Adventure/data/story_reminder_planner.dart';
import 'package:kidzo/features/Adventure/data/story_reminder_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// When a reminder is warranted, and when saying nothing is the right answer.
///
/// The restraint is the feature. This app has no ads, no analytics and nothing
/// to sell, so a notification that is not genuinely useful is just noise in a
/// parent's tray — and the fastest way to get the whole app muted.
void main() {
  late AppDatabase database;
  late StoryDao dao;
  late RecordingStoryReminderService service;
  late StoryReminderPlanner planner;
  late int profileId;

  const StoryReminderCopy copy =
      StoryReminderCopy(title: 'title', body: 'body');

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    dao = StoryDao(database);
    service = RecordingStoryReminderService();
    planner = StoryReminderPlanner(storyDao: dao, service: service);
    profileId = await database.into(database.profiles).insert(
          ProfilesCompanion.insert(name: 'Test Child'),
        );
  });

  tearDown(() async => database.close());

  /// Backdates the chapter so the quiet period has elapsed.
  Future<void> backdateLastPlayed(Duration ago) async {
    await (database.update(database.storyChapterProgress)
          ..where((t) => t.profileId.equals(profileId)))
        .write(StoryChapterProgressCompanion(
      lastPlayedAt: Value<DateTime>(DateTime.now().subtract(ago)),
    ));
  }

  group('Deciding', () {
    test('says nothing to a child who never started a story', () async {
      expect(await planner.decide(profileId: profileId), isNull,
          reason: '"Let\'s play the story" to someone who has never seen the '
              'story is an advert, not a reminder');
    });

    test('offers to continue an unfinished story', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');
      await backdateLastPlayed(const Duration(days: 1));

      expect(await planner.decide(profileId: profileId),
          StoryReminderKind.continueStory);
    });

    test('offers a new story once everything is finished', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n8');
      await dao.markChapterCompleted(
          profileId: profileId, adventureId: 'jungle');
      await backdateLastPlayed(const Duration(days: 2));

      expect(await planner.decide(profileId: profileId),
          StoryReminderKind.startStory);
    });

    test('stays quiet while the child is still playing', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');

      expect(await planner.decide(profileId: profileId), isNull,
          reason: 'a reminder is for tomorrow, not twenty minutes after they '
              'put the tablet down');
    });

    test('the quiet period is respected to the hour', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');
      await backdateLastPlayed(
          StoryReminderPlanner.minimumQuietPeriod - const Duration(minutes: 30));
      expect(await planner.decide(profileId: profileId), isNull);

      await backdateLastPlayed(
          StoryReminderPlanner.minimumQuietPeriod + const Duration(minutes: 30));
      expect(await planner.decide(profileId: profileId), isNotNull);
    });

    test('one profile playing does not silence another', () async {
      final int other = await database.into(database.profiles).insert(
            ProfilesCompanion.insert(name: 'Sibling'),
          );
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');
      await backdateLastPlayed(const Duration(days: 1));

      expect(await planner.decide(profileId: profileId), isNotNull);
      expect(await planner.decide(profileId: other), isNull);
    });
  });

  group('Scheduling', () {
    test('planFor schedules the reminder it decided on', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');
      await backdateLastPlayed(const Duration(days: 1));

      final StoryReminderKind? kind = await planner.planFor(
        profileId: profileId,
        copyFor: (_) => copy,
      );

      expect(kind, StoryReminderKind.continueStory);
      expect(service.scheduled, <StoryReminderKind>[
        StoryReminderKind.continueStory,
      ]);
    });

    test('nothing to say clears any stale reminder', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');
      await backdateLastPlayed(const Duration(days: 1));
      await planner.planFor(profileId: profileId, copyFor: (_) => copy);
      expect(service.scheduled, isNotEmpty);

      // The child comes back and plays, so lastPlayedAt is now.
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n5');
      await planner.planFor(profileId: profileId, copyFor: (_) => copy);

      expect(service.scheduled, isEmpty,
          reason: 'a reminder that no longer matches where the child is should '
              'be withdrawn, not left pending');
      expect(service.cancelCount, greaterThan(0));
    });

    test('only ever one reminder is pending', () async {
      await dao.saveResumePoint(
          profileId: profileId, adventureId: 'jungle', nodeId: 'jungle.n4');
      await backdateLastPlayed(const Duration(days: 1));

      await planner.planFor(profileId: profileId, copyFor: (_) => copy);
      await planner.planFor(profileId: profileId, copyFor: (_) => copy);
      await planner.planFor(profileId: profileId, copyFor: (_) => copy);

      expect(service.scheduled.length, 1,
          reason: 'a child who plays every day must not accumulate a queue of '
              'stale nudges');
    });
  });

  group('Slot arithmetic', () {
    setUpAll(tz_data.initializeTimeZones);

    tz.TZDateTime at(int year, int month, int day, int hour) =>
        tz.TZDateTime(tz.UTC, year, month, day, hour);

    test('a one-day delay lands on the next evening', () {
      final tz.TZDateTime result = LocalStoryReminderService.nextSlotAfter(
        const Duration(days: 1),
        from: at(2026, 9, 18, 10),
      );
      expect(result.day, 19);
      expect(result.hour, LocalStoryReminderService.preferredHour);
    });

    test('it rolls across a month boundary correctly', () {
      final tz.TZDateTime result = LocalStoryReminderService.nextSlotAfter(
        const Duration(days: 1),
        from: at(2026, 9, 30, 20),
      );
      expect(result.month, 10);
      expect(result.day, 1);
      expect(result.hour, LocalStoryReminderService.preferredHour);
    });

    test('a slot already past today moves to tomorrow', () {
      // 20:00 is after the 18:00 slot, so same-day would be in the past.
      final tz.TZDateTime result = LocalStoryReminderService.nextSlotAfter(
        Duration.zero,
        from: at(2026, 9, 18, 20),
      );
      expect(result.day, 19);
      expect(result.hour, LocalStoryReminderService.preferredHour);
    });

    test('the reminder never lands late at night', () {
      for (int hour = 0; hour < 24; hour++) {
        final tz.TZDateTime result = LocalStoryReminderService.nextSlotAfter(
          const Duration(days: 1),
          from: at(2026, 9, 18, hour),
        );
        expect(result.hour, LocalStoryReminderService.preferredHour);
      }
    });
  });
}
