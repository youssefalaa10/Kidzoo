// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_dao.dart';

// ignore_for_file: type=lint
mixin _$StoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProfilesTable get profiles => attachedDatabase.profiles;
  $StoryNodeProgressTable get storyNodeProgress =>
      attachedDatabase.storyNodeProgress;
  $StoryChapterProgressTable get storyChapterProgress =>
      attachedDatabase.storyChapterProgress;
  $StoryRewardsTable get storyRewards => attachedDatabase.storyRewards;
  $ActivityAttemptLogsTable get activityAttemptLogs =>
      attachedDatabase.activityAttemptLogs;
  StoryDaoManager get managers => StoryDaoManager(this);
}

class StoryDaoManager {
  final _$StoryDaoMixin _db;
  StoryDaoManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db.attachedDatabase, _db.profiles);
  $$StoryNodeProgressTableTableManager get storyNodeProgress =>
      $$StoryNodeProgressTableTableManager(
          _db.attachedDatabase, _db.storyNodeProgress);
  $$StoryChapterProgressTableTableManager get storyChapterProgress =>
      $$StoryChapterProgressTableTableManager(
          _db.attachedDatabase, _db.storyChapterProgress);
  $$StoryRewardsTableTableManager get storyRewards =>
      $$StoryRewardsTableTableManager(_db.attachedDatabase, _db.storyRewards);
  $$ActivityAttemptLogsTableTableManager get activityAttemptLogs =>
      $$ActivityAttemptLogsTableTableManager(
          _db.attachedDatabase, _db.activityAttemptLogs);
}
