import 'package:drift/drift.dart';
import 'package:kidzo/core/database/tables/profile_table.dart';

class GameScores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get gameKey => text()();
  IntColumn get score => integer()();
  IntColumn get level => integer().nullable()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
}
