// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_dao.dart';

// ignore_for_file: type=lint
mixin _$BadgeDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProfilesTable get profiles => attachedDatabase.profiles;
  $EarnedBadgesTable get earnedBadges => attachedDatabase.earnedBadges;
  BadgeDaoManager get managers => BadgeDaoManager(this);
}

class BadgeDaoManager {
  final _$BadgeDaoMixin _db;
  BadgeDaoManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db.attachedDatabase, _db.profiles);
  $$EarnedBadgesTableTableManager get earnedBadges =>
      $$EarnedBadgesTableTableManager(_db.attachedDatabase, _db.earnedBadges);
}
