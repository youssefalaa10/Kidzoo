import 'package:drift/drift.dart';
import 'package:kidzo/core/database/tables/profile_table.dart';

class GameScores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get gameKey => text()();
  IntColumn get score => integer()();
  IntColumn get level => integer().nullable()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();

  /// Added in schema v3 for Adventure results. All nullable, because every row
  /// the older games already wrote has none of them.
  IntColumn get maxScore => integer().nullable()();
  IntColumn get starsEarned => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();

  /// Joins a score back to the story beat it served, when it came from one.
  TextColumn get storyNodeId => text().nullable()();
}
