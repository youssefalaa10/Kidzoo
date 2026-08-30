// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_scores_dao.dart';

// ignore_for_file: type=lint
mixin _$GameScoresDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProfilesTable get profiles => attachedDatabase.profiles;
  $GameScoresTable get gameScores => attachedDatabase.gameScores;
  GameScoresDaoManager get managers => GameScoresDaoManager(this);
}

class GameScoresDaoManager {
  final _$GameScoresDaoMixin _db;
  GameScoresDaoManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db.attachedDatabase, _db.profiles);
  $$GameScoresTableTableManager get gameScores =>
      $$GameScoresTableTableManager(_db.attachedDatabase, _db.gameScores);
}
