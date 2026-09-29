import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/engines/spot_the_diff/spot_the_diff_content.dart';

/// "Find one more." Every step is the same question; what changes between
/// them is which differences are already found, and that is the child's
/// choice, not the content's.
@immutable
class SpotDiffStep extends ActivityStep {
  const SpotDiffStep({
    required String stepId,
    required this.content,
    required this.findNumber,
  }) : super(stepId);

  final SpotDiffContent content;

  /// 1-based, for tests and semantics. Not a target: any unfound spot counts.
  final int findNumber;
}

/// Tracks what has been found, because the child finds things in their own
/// order and a step list built up front cannot know it.
///
/// The previous version precomputed each step's "already found" set from a
/// shuffled order, so a child who found the second difference first was
/// later told a correct tap was wrong.
class SpotDiffCubit extends ActivityCubit<SpotDiffContent, SpotDiffStep> {
  SpotDiffCubit(super.session);

  final List<String> _found = <String>[];

  /// The spot that finished the step now being revealed.
  DiffSpot? _justFound;

  /// Found so far, in the order the child found them.
  List<String> get foundIds => List<String>.unmodifiable(_found);

  @override
  List<SpotDiffStep> buildSteps() => <SpotDiffStep>[
        for (int index = 0; index < content.spots.length; index++)
          SpotDiffStep(
            stepId: 'find_${index + 1}',
            content: content,
            findNumber: index + 1,
          ),
      ];

  @override
  Iterable<String> get assetsToPrecache => content.assetPaths;

  /// The one hints point at: the first unfound in authored order, so the
  /// ladder walks the scene the same way on every run.
  DiffSpot get _nextHinted =>
      content.spots.firstWhere((DiffSpot spot) => !_found.contains(spot.id));

  @override
  ActivityJudgement judge(SpotDiffStep step, ActivityAttempt attempt) {
    if (attempt is ChoiceAttempt &&
        content.spotNamed(attempt.optionId) != null &&
        !_found.contains(attempt.optionId)) {
      return const ActivityJudgement.correct();
    }
    return const ActivityJudgement.wrongItem();
  }

  @override
  bool onStepCompleted(
    SpotDiffStep step,
    ActivityAttempt attempt, {
    required bool credited,
  }) {
    final DiffSpot spot = !credited && attempt is ChoiceAttempt
        ? content.spotNamed(attempt.optionId)!
        : _nextHinted;
    _found.add(spot.id);
    _justFound = spot;
    return true;
  }

  @override
  ActivityStepView describe(SpotDiffStep step, ScaffoldLevel level) {
    final List<String> unfound = <String>[
      for (final DiffSpot spot in content.spots)
        if (!_found.contains(spot.id)) spot.id,
    ];
    final bool named =
        level == ScaffoldLevel.narrowed || level == ScaffoldLevel.modelled;
    final DiffSpot? hinted = unfound.isEmpty ? null : _nextHinted;
    return ActivityStepView(
      // The banner names a spot only once the child has needed help twice.
      // Before that, finding it is the activity.
      prompt: named && hinted != null && !hinted.label.isEmpty
          ? hinted.label
          : spec.narration.prompt,
      // After a find, what the child last heard is the find itself, and
      // that is the prompt: every step asks the same thing, and saying the
      // instruction again after each find turns it into wallpaper. The base
      // cubit never repeats the line just spoken, so this is silence.
      spokenPrompt: named ? null : _justFound?.revealLine,
      revealLine: _justFound?.revealLine,
      liveOptionIds: unfound,
      dimmedOptionIds: List<String>.unmodifiable(_found),
      highlightOptionId: level == ScaffoldLevel.initial ? null : hinted?.id,
    );
  }

  @override
  Map<String, dynamic>? captureResumePayload() =>
      <String, dynamic>{'found': List<String>.of(_found)};

  @override
  void restoreResumePayload(Map<String, dynamic> payload) {
    final Object? raw = payload['found'];
    if (raw is! List) {
      return;
    }
    for (final Object? id in raw) {
      if (id is String && content.spotNamed(id) != null && !_found.contains(id)) {
        _found.add(id);
      }
    }
  }
}
