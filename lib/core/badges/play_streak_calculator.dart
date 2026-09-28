/// Consecutive days a child has played.
///
/// Lifted out of `ProfileAnalyticsCubit` so the streak badges and the streak
/// figure on the Profile read the same number from the same code. Two
/// implementations of "how many days in a row" would eventually disagree, and
/// the one a child notices is the one that says their streak is gone.
class PlayStreakCalculator {
  const PlayStreakCalculator();

  /// Counts back from today, or from yesterday when today has no play yet.
  ///
  /// Not yet playing today must not read as a broken streak: for most of the
  /// day it simply means the child has not opened the app since breakfast.
  ///
  /// [today] is injectable so this can be tested without depending on the wall
  /// clock, which is why the original had no test.
  int countConsecutiveDays(List<DateTime> playDates, {DateTime? today}) {
    if (playDates.isEmpty) {
      return 0;
    }
    final Set<DateTime> days = playDates
        .map((DateTime d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final DateTime now = today ?? DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) {
        return 0;
      }
    }
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
