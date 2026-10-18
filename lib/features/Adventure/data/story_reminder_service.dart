import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// What kind of nudge is being sent.
enum StoryReminderKind {
  /// There is a story part-finished. The strongest reason to come back.
  continueStory,

  /// Nothing started yet, or everything finished. A gentler invitation.
  startStory,
}

/// The copy for one reminder, resolved by the caller so this service never
/// touches localization itself.
@immutable
class StoryReminderCopy {
  const StoryReminderCopy({required this.title, required this.body});
  final String title;
  final String body;
}

/// Schedules the "let's continue the story" reminder.
///
/// Deliberately restrained, for two reasons. The audience is a child using a
/// parent's device, so a notification is really addressed to the parent; and
/// this app has no ads, no analytics SDK and nothing to sell, so a reminder has
/// no job other than being useful. Hence: **one** pending reminder at a time,
/// a fixed early-evening slot rather than a nag, and nothing at all until the
/// child has actually started a story.
abstract class StoryReminderService {
  Future<void> initialize();

  /// Asks for permission. Returns false if the parent declines, in which case
  /// scheduling silently does nothing rather than retrying.
  Future<bool> requestPermission();

  /// Replaces any pending reminder with one for [kind].
  Future<void> scheduleReminder({
    required StoryReminderKind kind,
    required StoryReminderCopy copy,
    Duration delay = const Duration(days: 1),
  });

  Future<void> cancelAll();

  Future<List<int>> pendingIds();
}

class LocalStoryReminderService implements StoryReminderService {
  LocalStoryReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// One id, reused. Re-scheduling overwrites rather than stacking, so a child
  /// who plays every day can never accumulate a queue of stale nudges.
  static const int reminderId = 4001;

  static const String _channelId = 'kidzo_story_reminders';
  static const String _channelName = 'Story reminders';
  static const String _channelDescription =
      'Gentle reminders to continue an unfinished adventure.';

  /// Early evening: after school, before bed. Not first thing in the morning,
  /// and never late at night.
  static const int preferredHour = 18;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      // Asked for explicitly later, so the very first launch is not a
      // permission prompt before the child has seen anything.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // API 33+ requires POST_NOTIFICATIONS at runtime; older Android grants
        // it at install time and returns null here.
        return await android.requestNotificationsPermission() ?? true;
      }
      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      return false;
    } catch (error) {
      debugPrint('StoryReminderService: permission request failed ($error)');
      return false;
    }
  }

  @override
  Future<void> scheduleReminder({
    required StoryReminderKind kind,
    required StoryReminderCopy copy,
    Duration delay = const Duration(days: 1),
  }) async {
    await initialize();
    // Only ever one pending reminder.
    await cancelAll();

    final tz.TZDateTime when = _nextSlotAfter(delay);

    try {
      await _plugin.zonedSchedule(
        id: reminderId,
        title: copy.title,
        body: copy.body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact on purpose. An exact alarm needs a special permission on
        // Android 12+, and "around six in the evening" is entirely good enough
        // for a story reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: kind.name,
      );
    } catch (error) {
      // A device that refuses exact alarms, or a parent who revoked the
      // permission, must never break the story flow.
      debugPrint('StoryReminderService: could not schedule ($error)');
    }
  }

  /// The next [preferredHour] at or after `now + delay`.
  ///
  /// Exposed for testing because "tomorrow evening" is exactly the kind of date
  /// arithmetic that is quietly wrong across a month boundary.
  @visibleForTesting
  static tz.TZDateTime nextSlotAfter(
    Duration delay, {
    required tz.TZDateTime from,
  }) {
    final tz.TZDateTime target = from.add(delay);
    final tz.TZDateTime sameDaySlot = tz.TZDateTime(
      target.location,
      target.year,
      target.month,
      target.day,
      preferredHour,
    );
    if (sameDaySlot.isAfter(from)) {
      return sameDaySlot;
    }
    return sameDaySlot.add(const Duration(days: 1));
  }

  tz.TZDateTime _nextSlotAfter(Duration delay) =>
      nextSlotAfter(delay, from: tz.TZDateTime.now(tz.local));

  @override
  Future<void> cancelAll() async {
    await initialize();
    try {
      await _plugin.cancel(id: reminderId);
    } catch (error) {
      debugPrint('StoryReminderService: could not cancel ($error)');
    }
  }

  @override
  Future<List<int>> pendingIds() async {
    await initialize();
    final List<PendingNotificationRequest> pending =
        await _plugin.pendingNotificationRequests();
    return pending
        .map((PendingNotificationRequest request) => request.id)
        .toList(growable: false);
  }
}

/// Records calls instead of scheduling. Used by tests.
class RecordingStoryReminderService implements StoryReminderService {
  final List<StoryReminderKind> scheduled = <StoryReminderKind>[];
  final List<StoryReminderCopy> copies = <StoryReminderCopy>[];
  int cancelCount = 0;
  bool permissionGranted = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleReminder({
    required StoryReminderKind kind,
    required StoryReminderCopy copy,
    Duration delay = const Duration(days: 1),
  }) async {
    // Mirrors the real service: one pending reminder at a time.
    scheduled
      ..clear()
      ..add(kind);
    copies
      ..clear()
      ..add(copy);
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
    scheduled.clear();
    copies.clear();
  }

  @override
  Future<List<int>> pendingIds() async =>
      scheduled.isEmpty ? const <int>[] : const <int>[1];
}
