import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 3, max: 16)();
  IntColumn get avatarIndex => integer().withDefault(const Constant(0))();
  IntColumn get age => integer().withDefault(const Constant(7))();
  IntColumn get totalPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
