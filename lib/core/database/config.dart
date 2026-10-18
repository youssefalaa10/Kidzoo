import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:kidzo/core/database/tables/badge_tables.dart';
import 'package:kidzo/core/database/tables/game_scores_table.dart';
import 'package:kidzo/core/database/tables/profile_table.dart';
import 'package:kidzo/core/database/tables/story_tables.dart';
import 'package:path_provider/path_provider.dart';

part 'config.g.dart';

@DriftDatabase(tables: [
  Profiles,
  GameScores,
  StoryNodeProgress,
  StoryChapterProgress,
  StoryRewards,
  ActivityAttemptLogs,
  EarnedBadges,
])
class AppDatabase extends _$AppDatabase {
  // After generating code, this class needs to define a `schemaVersion` getter
  // and a constructor telling drift where the database should be stored.
  // These are described in the getting started guide: https://drift.simonbinder.eu/setup/
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(profiles, profiles.age);
          }
          if (from < 3) {
            // Adventure Mode. A pure-add migration: no existing column
            // changes, so an install that rolls back keeps working.
            await m.createTable(storyNodeProgress);
            await m.createTable(storyChapterProgress);
            await m.createTable(storyRewards);
            await m.createTable(activityAttemptLogs);
            // GameScores gains the columns a story result can fill in. All
            // nullable, so rows written by the older games stay valid.
            await m.addColumn(gameScores, gameScores.maxScore);
            await m.addColumn(gameScores, gameScores.starsEarned);
            await m.addColumn(gameScores, gameScores.durationSeconds);
            await m.addColumn(gameScores, gameScores.storyNodeId);
          }
          if (from < 4) {
            // Durable Adventure resume. Two nullable columns on the chapter
            // row the resume point already lived on, rather than a second
            // table: where a child is in a story and where they are inside the
            // activity they are on are the same fact at two zoom levels, and
            // splitting them across tables is how the two drift apart.
            await m.addColumn(
                storyChapterProgress, storyChapterProgress.currentBeat);
            await m.addColumn(storyChapterProgress,
                storyChapterProgress.activityCheckpoint);
          }
          if (from < 5) {
            // Badges. Pure-add, the safest shape a migration has: one new
            // table, no column changes, so an install that rolls back to v4
            // keeps working and only loses the badge wall.
            await m.createTable(earnedBadges);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'kidzoo_database',
      native: const DriftNativeOptions(
        // By default, `driftDatabase` from `package:drift_flutter` stores the
        // database files in `getApplicationDocumentsDirectory()`.
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // If you need web support, see https://drift.simonbinder.eu/platforms/web/
    );
  }
}
