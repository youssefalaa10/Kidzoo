import 'package:kidzo/core/database/config.dart';
import 'package:kidzo/core/database/daos/story_dao.dart';
import 'package:kidzo/features/Adventure/data/story_reminder_service.dart';

/// Decides whether a reminder is warranted, and which one.
///
/// Split from [StoryReminderService] on purpose: the decision is the part with
/// rules worth testing, and it should be testable without a notification
/// plugin, a timezone database or a device.
class StoryReminderPlanner {
  const StoryReminderPlanner({
    required this.storyDao,
    required this.service,
  });

  final StoryDao storyDao;
  final StoryReminderService service;

  /// Don't nag a child who is mid-session. A reminder is for tomorrow, not for
  /// twenty minutes after they put the tablet down.
  static const Duration minimumQuietPeriod = Duration(hours: 18);

  /// Chooses a reminder for [profileId], or null when none is warranted.
  ///
  /// Returns null — meaning *say nothing* — when the child has never started a
  /// story. An app that has not yet earned attention should not be asking for
  /// it, and "Let's play the story" to someone who has never seen the story is
  /// an advert, not a reminder.
  Future<StoryReminderKind?> decide({
    required int profileId,
    DateTime? now,
  }) async {
    final List<StoryChapterProgressData> chapters =
        await storyDao.chaptersFor(profileId);
    if (chapters.isEmpty) {
      return null;
    }

    final DateTime moment = now ?? DateTime.now();
    final bool hasUnfinished = chapters.any(
      (StoryChapterProgressData chapter) =>
          !chapter.isCompleted && chapter.currentNodeId != null,
    );

    final DateTime lastPlayed = chapters
        .map((StoryChapterProgressData chapter) => chapter.lastPlayedAt)
        .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);

    if (moment.difference(lastPlayed) < minimumQuietPeriod) {
      return null;
    }

    return hasUnfinished
        ? StoryReminderKind.continueStory
        : StoryReminderKind.startStory;
  }

  /// Decides and schedules in one call. [copyFor] supplies localized text, so
  /// this class never touches `AppLocalizations`.
  Future<StoryReminderKind?> planFor({
    required int profileId,
    required StoryReminderCopy Function(StoryReminderKind kind) copyFor,
    DateTime? now,
    Duration delay = const Duration(days: 1),
  }) async {
    final StoryReminderKind? kind =
        await decide(profileId: profileId, now: now);
    if (kind == null) {
      // Nothing to say. Clear any stale reminder rather than leaving one that
      // no longer matches where the child actually is.
      await service.cancelAll();
      return null;
    }
    await service.scheduleReminder(
      kind: kind,
      copy: copyFor(kind),
      delay: delay,
    );
    return kind;
  }
}
