import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/badges/play_streak_calculator.dart';

/// Consecutive play days, with the clock injected.
///
/// The original lived inside ProfileAnalyticsCubit and read DateTime.now()
/// directly, which is why it had no test: every case would have been
/// unwritable or flaky.
void main() {
  const PlayStreakCalculator calculator = PlayStreakCalculator();
  final DateTime today = DateTime(2026, 9, 28, 14, 30);

  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  test('no plays is no streak', () {
    expect(
      calculator.countConsecutiveDays(<DateTime>[], today: today),
      0,
    );
  });

  test('playing today alone is a streak of one', () {
    expect(
      calculator.countConsecutiveDays(<DateTime>[today], today: today),
      1,
    );
  });

  test('not having played yet today does not break the streak', () {
    // For most of the day, "nothing today" just means "not since breakfast".
    expect(
      calculator.countConsecutiveDays(
        <DateTime>[daysAgo(1), daysAgo(2)],
        today: today,
      ),
      2,
    );
  });

  test('counts a run of five', () {
    expect(
      calculator.countConsecutiveDays(
        <DateTime>[today, daysAgo(1), daysAgo(2), daysAgo(3), daysAgo(4)],
        today: today,
      ),
      5,
    );
  });

  test('stops at a gap', () {
    expect(
      calculator.countConsecutiveDays(
        <DateTime>[today, daysAgo(1), daysAgo(3), daysAgo(4)],
        today: today,
      ),
      2,
    );
  });

  test('a streak that ended days ago is over', () {
    expect(
      calculator.countConsecutiveDays(
        <DateTime>[daysAgo(5), daysAgo(6), daysAgo(7)],
        today: today,
      ),
      0,
    );
  });

  test('several plays on one day still count as one day', () {
    expect(
      calculator.countConsecutiveDays(
        <DateTime>[
          DateTime(2026, 9, 28, 9),
          DateTime(2026, 9, 28, 12),
          DateTime(2026, 9, 28, 18),
        ],
        today: today,
      ),
      1,
    );
  });

  test('order does not matter', () {
    expect(
      calculator.countConsecutiveDays(
        <DateTime>[daysAgo(2), today, daysAgo(1)],
        today: today,
      ),
      3,
    );
  });
}
