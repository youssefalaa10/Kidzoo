import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

/// Where one child is inside one Adventure, precisely enough to put them back.
///
/// There is exactly **one** of these. Before it, "where was I" was spread over
/// a nullable column on a chapter row, an index held in a cubit field, and —
/// for anything inside an activity — nowhere at all, which is why a child who
/// left in the middle of a mini-game came back to its first step with a
/// different board. A single cursor is what makes "never restart from the
/// beginning" a property that can be stated and tested rather than an
/// aspiration spread across three layers.
///
/// It records **logical** progress only. Which step, which seed, what has been
/// earned. Never an animation frame, a drag offset or a TTS playback position:
/// those describe how the screen looked a moment ago, not where the child got
/// to, and restoring them would put a four-year-old back into the middle of a
/// gesture they have long since forgotten making.
@immutable
class StoryResumePoint {
  const StoryResumePoint({
    required this.profileId,
    required this.adventureId,
    required this.nodeId,
    required this.beat,
    required this.updatedAt,
    this.activity,
    this.isChapterCompleted = false,
  });

  /// Which child. Every read and write is scoped by this, so two children on
  /// one tablet keep separate stories.
  final int profileId;

  /// Which Adventure.
  final String adventureId;

  /// The node to reopen at, or null when the Adventure was played to its end.
  final String? nodeId;

  /// The beat [nodeId] belonged to when it was written.
  ///
  /// Kept so a renamed or reordered node does not send the child back to the
  /// first line of the story. See [StoryResumeResolver].
  final StoryBeat? beat;

  /// The activity in flight, or null on a narration beat.
  final ActivityCheckpoint? activity;

  /// True once the Adventure has been finished at least once. A finished
  /// chapter with a live [nodeId] is a **replay in progress**, which is a
  /// different thing from a finished one and used not to be distinguished.
  final bool isChapterCompleted;

  final DateTime updatedAt;

  bool get hasNode => nodeId != null;
}

/// Where a child is inside one run of one activity.
///
/// Written every time the activity reaches a step boundary — a *safe* point,
/// where nothing is half-placed and no narration is mid-sentence — rather than
/// on the way out. Relying on an exit callback to save this is what makes
/// progress evaporate on a force-kill, which at this age is not the edge case
/// but most of how a session ends.
@immutable
class ActivityCheckpoint {
  const ActivityCheckpoint({
    required this.activityId,
    required this.engineId,
    required this.engineSchemaVersion,
    required this.seed,
    required this.stepIndex,
    required this.score,
    required this.stepsIndependent,
    required this.hintsUsed,
    required this.elapsedSeconds,
    this.enginePayload,
    this.cursorVersion = currentCursorVersion,
  });

  /// The cursor format's own version, independent of both the Drift schema and
  /// any engine's content schema.
  ///
  /// Bump this and every checkpoint in the field stops parsing, which is the
  /// intended behaviour: the child restarts the mini-game they were on and
  /// keeps the rest of the story. Silently reinterpreting an old cursor under
  /// new rules is how a child gets dropped onto a step that no longer exists.
  static const int currentCursorVersion = 1;

  /// `ActivitySpec.instanceId`. A checkpoint for one activity must never be
  /// applied to another, however similar.
  final String activityId;

  final String engineId;

  /// `ActivityEngineDescriptor.schemaVersion` when this was written. An engine
  /// that changes how it builds its steps bumps this, and every checkpoint it
  /// wrote before becomes unusable rather than wrong.
  final int engineSchemaVersion;

  /// The seed `buildSteps` was run with.
  ///
  /// This is what makes step-level resume *exact* rather than approximate.
  /// Steps are generated, often with shuffling; replaying generation under the
  /// same seed reproduces the same board, so resuming at step three means the
  /// same step three. Without it the child would return to a differently
  /// arranged activity with three of its rounds silently skipped.
  final int seed;

  /// The step to reopen at. Always a boundary the activity actually reached.
  final int stepIndex;

  final int score;
  final int stepsIndependent;
  final int hintsUsed;
  final int elapsedSeconds;

  /// Reserved for an engine that genuinely has board state worth restoring and
  /// cannot express it as a step index.
  ///
  /// No engine writes one today, and that is the intended steady state: an
  /// engine reaching for this should first ask whether the thing it wants to
  /// restore is a *step*. It exists so that the first engine that truly needs
  /// it is a change to that engine, not to the cursor format every Adventure
  /// already depends on.
  final Map<String, dynamic>? enginePayload;

  final int cursorVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': cursorVersion,
        'activityId': activityId,
        'engineId': engineId,
        'engineSchemaVersion': engineSchemaVersion,
        'seed': seed,
        'stepIndex': stepIndex,
        'score': score,
        'stepsIndependent': stepsIndependent,
        'hintsUsed': hintsUsed,
        'elapsedSeconds': elapsedSeconds,
        if (enginePayload != null) 'enginePayload': enginePayload,
      };

  String encode() => json.encode(toJson());

  /// Parses a stored cursor, or returns null for anything it does not fully
  /// understand.
  ///
  /// Never throws and never guesses. A corrupt row, a cursor from a future
  /// build, a field that changed type — all of them land on the same, safe
  /// outcome: no checkpoint, so the current activity starts over and the rest
  /// of the Adventure is untouched.
  static ActivityCheckpoint? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = json.decode(raw);
      if (decoded is! Map) {
        return null;
      }
      final Map<String, dynamic> map = decoded
          .map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v));
      if (map['v'] != currentCursorVersion) {
        return null;
      }
      final Object? activityId = map['activityId'];
      final Object? engineId = map['engineId'];
      if (activityId is! String || engineId is! String) {
        return null;
      }
      final int? engineSchemaVersion = _int(map['engineSchemaVersion']);
      final int? seed = _int(map['seed']);
      final int? stepIndex = _int(map['stepIndex']);
      if (engineSchemaVersion == null || seed == null || stepIndex == null) {
        return null;
      }
      if (stepIndex < 0) {
        return null;
      }
      final Object? payload = map['enginePayload'];
      return ActivityCheckpoint(
        activityId: activityId,
        engineId: engineId,
        engineSchemaVersion: engineSchemaVersion,
        seed: seed,
        stepIndex: stepIndex,
        score: _int(map['score']) ?? 0,
        stepsIndependent: _int(map['stepsIndependent']) ?? 0,
        hintsUsed: _int(map['hintsUsed']) ?? 0,
        elapsedSeconds: _int(map['elapsedSeconds']) ?? 0,
        enginePayload: payload is Map
            ? payload.map(
                (Object? k, Object? v) => MapEntry<String, dynamic>('$k', v))
            : null,
      );
    } on FormatException {
      return null;
    }
  }

  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  /// Whether this cursor may be applied to the run described by the arguments.
  ///
  /// Every mismatch means the same thing — restart this activity, keep the
  /// story — so they are checked together rather than reported separately.
  bool appliesTo({
    required String activityId,
    required String engineId,
    required int engineSchemaVersion,
    required int stepCount,
  }) {
    return cursorVersion == currentCursorVersion &&
        this.activityId == activityId &&
        this.engineId == engineId &&
        this.engineSchemaVersion == engineSchemaVersion &&
        stepIndex < stepCount;
  }

  ActivityCheckpoint copyWith({
    int? stepIndex,
    int? score,
    int? stepsIndependent,
    int? hintsUsed,
    int? elapsedSeconds,
    Map<String, dynamic>? enginePayload,
  }) {
    return ActivityCheckpoint(
      activityId: activityId,
      engineId: engineId,
      engineSchemaVersion: engineSchemaVersion,
      seed: seed,
      stepIndex: stepIndex ?? this.stepIndex,
      score: score ?? this.score,
      stepsIndependent: stepsIndependent ?? this.stepsIndependent,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      enginePayload: enginePayload ?? this.enginePayload,
      cursorVersion: cursorVersion,
    );
  }
}

/// Turns a stored [StoryResumePoint] into the index to reopen at.
///
/// Pulled out of the runner so the rule is one pure function with a table of
/// tests against it, rather than three conditions tangled into a `start()` that
/// also does I/O. Each branch here is a bug that was reproduced before it was
/// fixed.
class StoryResumeResolver {
  const StoryResumeResolver();

  /// The node index to reopen [adventure] at. Never negative.
  int resolve({
    required Adventure adventure,
    required StoryResumePoint? resume,
    required Set<String> completedNodeIds,
  }) {
    if (resume == null) {
      return 0;
    }

    // A finished Adventure with no live node is a *replay*, and a replay does
    // start at the first line. A finished Adventure that still has one is a
    // replay already under way — which used to be treated as the first case
    // and threw away every beat the child had just played again.
    if (resume.isChapterCompleted && resume.nodeId == null) {
      return 0;
    }

    final String? nodeId = resume.nodeId;
    if (nodeId != null) {
      final int index = adventure.indexOfNode(nodeId);
      if (index >= 0) {
        return index;
      }
    }

    // The node is gone: renamed, reordered, or removed by a content update
    // shipped since the child last played. Falling back to zero here is the
    // second way an Adventure silently restarted itself, and it is the way that
    // would have fired for every child on the next content release.
    return _firstUnfinishedIndex(
      adventure: adventure,
      completedNodeIds: completedNodeIds,
      beat: resume.beat,
    );
  }

  /// The earliest node the child has not finished, preferring the beat they
  /// were last on.
  int _firstUnfinishedIndex({
    required Adventure adventure,
    required Set<String> completedNodeIds,
    required StoryBeat? beat,
  }) {
    if (beat != null) {
      for (int index = 0; index < adventure.nodes.length; index++) {
        final StoryNode node = adventure.nodes[index];
        if (node.beat == beat && !completedNodeIds.contains(node.nodeId)) {
          return index;
        }
      }
    }
    for (int index = 0; index < adventure.nodes.length; index++) {
      if (!completedNodeIds.contains(adventure.nodes[index].nodeId)) {
        return index;
      }
    }
    // Everything is finished but the chapter was never marked so. The last
    // node is the honest answer; it will complete and close the chapter out.
    return adventure.nodes.isEmpty ? 0 : adventure.nodes.length - 1;
  }
}
