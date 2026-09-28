import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/engine/support/no_fail_coach.dart';
import 'package:kidzo/features/Adventure/story/models/story_resume.dart';

/// One recorded attempt, on its way to persistence.
@immutable
class ActivityAttemptRecord {
  const ActivityAttemptRecord({
    required this.activityId,
    required this.stepIndex,
    required this.attemptIndex,
    required this.outcome,
    required this.scaffoldLevel,
    required this.elapsedMilliseconds,
    this.storyNodeId,
  });

  final String activityId;
  final int stepIndex;
  final int attemptIndex;
  final AttemptOutcome outcome;
  final ScaffoldLevel scaffoldLevel;
  final int elapsedMilliseconds;
  final String? storyNodeId;
}

/// Where per-step telemetry goes.
///
/// Separate from `GameScores`, which stores one row per play and so cannot
/// carry the motor-versus-knowledge distinction that makes the data useful.
abstract class ActivityAttemptSink {
  Future<void> record(ActivityAttemptRecord attempt);
}

/// Discards attempts. The default in tests and in any host without a database.
class NullActivityAttemptSink implements ActivityAttemptSink {
  const NullActivityAttemptSink();

  @override
  Future<void> record(ActivityAttemptRecord attempt) async {}
}

/// Collects attempts in memory so a test can assert on them.
class RecordingActivityAttemptSink implements ActivityAttemptSink {
  final List<ActivityAttemptRecord> recorded = <ActivityAttemptRecord>[];

  @override
  Future<void> record(ActivityAttemptRecord attempt) async =>
      recorded.add(attempt);
}

/// Where an in-flight activity's position is stored.
///
/// Separate from [ActivityAttemptSink] because the two answer different
/// questions and have opposite lifetimes: attempts are an append-only history
/// that outlives the run, a checkpoint is a single mutable "here" that is
/// deleted the moment the run ends.
///
/// The base cubit writes through this at every step boundary. Nothing an engine
/// does reaches it directly — an engine that wanted to choose its own save
/// points would be deciding when a child's progress is safe, which is the
/// lifecycle's job.
abstract class ActivityCheckpointSink {
  Future<void> save(ActivityCheckpoint checkpoint);

  /// Called once the activity is over, so a later replay of the same story
  /// node starts it fresh rather than resuming a finished run.
  Future<void> clear();
}

/// Discards checkpoints. The default for free play, where there is no story to
/// come back to, and for any host without a database.
class NullActivityCheckpointSink implements ActivityCheckpointSink {
  const NullActivityCheckpointSink();

  @override
  Future<void> save(ActivityCheckpoint checkpoint) async {}

  @override
  Future<void> clear() async {}
}

/// Keeps the latest checkpoint in memory so a test can assert on it — and so a
/// test can simulate a cold start by feeding [latest] back into a new session.
class RecordingActivityCheckpointSink implements ActivityCheckpointSink {
  final List<ActivityCheckpoint> saved = <ActivityCheckpoint>[];
  bool wasCleared = false;

  ActivityCheckpoint? get latest => saved.isEmpty ? null : saved.last;

  @override
  Future<void> save(ActivityCheckpoint checkpoint) async {
    saved.add(checkpoint);
    wasCleared = false;
  }

  @override
  Future<void> clear() async {
    wasCleared = true;
  }
}

/// Everything an engine cubit is allowed to reach for.
///
/// Note what is **absent**: no `BuildContext`, no `AppLocalizations`, no
/// `Navigator`, no theme. An engine that needed any of those would be building
/// its own screen, which is the exact failure that left `quiz_engine_screen`
/// written but never instantiated. Keeping them out means every engine cubit is
/// unit-testable with no widget tree at all.
///
/// [random] is injected so generation is deterministic under a seed: an engine
/// that shuffles options must be reproducible or its tests are theatre.
@immutable
class ActivityServices {
  const ActivityServices({
    required this.narrator,
    required this.soundboard,
    required this.random,
    this.coach = const NoFailCoach(),
    this.attemptSink = const NullActivityAttemptSink(),
    this.checkpointSink = const NullActivityCheckpointSink(),
    this.languageCode = 'en',
  });

  /// Convenience for tests: recording narrator and soundboard, seeded random.
  factory ActivityServices.forTest({
    int seed = 7,
    String languageCode = 'en',
    ActivityAttemptSink? attemptSink,
    ActivityCheckpointSink? checkpointSink,
  }) {
    return ActivityServices(
      narrator: RecordingActivityNarrator(),
      soundboard: RecordingActivitySoundboard(),
      random: Random(seed),
      attemptSink: attemptSink ?? const NullActivityAttemptSink(),
      checkpointSink: checkpointSink ?? const NullActivityCheckpointSink(),
      languageCode: languageCode,
    );
  }

  final ActivityNarrator narrator;
  final ActivitySoundboard soundboard;
  final Random random;
  final NoFailCoach coach;
  final ActivityAttemptSink attemptSink;
  final ActivityCheckpointSink checkpointSink;

  /// The locale the child is playing in, so content can resolve its own text
  /// without the engine ever touching Flutter's localization machinery.
  final String languageCode;

  ActivityServices copyWith({String? languageCode}) => ActivityServices(
        narrator: narrator,
        soundboard: soundboard,
        random: random,
        coach: coach,
        attemptSink: attemptSink,
        checkpointSink: checkpointSink,
        languageCode: languageCode ?? this.languageCode,
      );
}
