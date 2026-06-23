import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 3, max: 16)();
  IntColumn get age => integer().nullable()();
  IntColumn get gender => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
}
