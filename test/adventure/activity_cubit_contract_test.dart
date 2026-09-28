import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_step.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';

import 'support/echo_engine.dart';

/// The shared suite every engine must satisfy.
///
/// It runs against [EchoEngine] here; each real engine re-runs it in its own
/// test file. The invariants below are the ones the story depends on, and the
/// most important is the third: **a child who reaches the last step completes,
/// even having answered every step wrong three times.** If that ever fails, the
/// narrative becomes gated on performance, which is the one thing this design
/// refuses to do.
void main() {
  late RecordingActivityNarrator narrator;
  late RecordingActivitySoundboard soundboard;
  late RecordingActivityAttemptSink attempts;

  ActivityServices makeServices({String languageCode = 'en', int seed = 7}) {
    narrator = RecordingActivityNarrator();
    soundboard = RecordingActivitySoundboard();
    attempts = RecordingActivityAttemptSink();
    return ActivityServices(
      narrator: narrator,
      soundboard: soundboard,
      random: Random(seed),
      attemptSink: attempts,
      languageCode: languageCode,
    );
  }

  EchoCubit makeCubit({
    int stepCount = 3,
    int optionCount = 4,
    String languageCode = 'en',
  }) {
    const EchoEngine engine = EchoEngine();
    final ActivitySpec spec =
        echoSpec(stepCount: stepCount, optionCount: optionCount);
    return EchoCubit(ActivitySession<EchoContent>(
      spec: spec,
      content: engine.parseContent(
          spec, const MapItemPackResolver(<String, ItemPack>{})),
      services: makeServices(languageCode: languageCode),
      storyNodeId: 'test.node',
    ));
  }

  String correctOptionFor(EchoCubit cubit) =>
      (cubit.currentStep).correctOptionId;

  String wrongOptionFor(EchoCubit cubit) => cubit.currentStep.optionIds
      .firstWhere((String id) => id != cubit.currentStep.correctOptionId);

  group('Lifecycle', () {
    test('start runs the first step and speaks its prompt', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();

      expect(cubit.state.status, ActivityStatus.running);
      expect(cubit.state.stepIndex, 0);
      expect(cubit.state.stepCount, 3);
      expect(cubit.state.isBoardLocked, isFalse,
          reason: 'the board must be live once narration has finished');
      expect(narrator.spoken, isNotEmpty);
      await cubit.close();
    });

    test('answering every step correctly completes the activity', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();

      for (int step = 0; step < 3; step++) {
        await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      }

      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      expect(cubit.state.result.stepsIndependent, 3);
      expect(cubit.state.result.hintsUsed, 0);
      expect(cubit.state.result.masterySignal, 1.0);
      await cubit.close();
    });

    test('start is idempotent', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();
      final int spokenAfterFirst = narrator.spoken.length;
      await cubit.start();
      expect(narrator.spoken.length, spokenAfterFirst);
      await cubit.close();
    });
  });

  group('No-fail guarantee', () {
    test(
        'completes even when every step is answered wrong three times, '
        'and still scores above zero', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();

      for (int step = 0; step < 3; step++) {
        for (int wrong = 0; wrong < 3; wrong++) {
          await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
        }
        expect(cubit.state.scaffoldLevel, ScaffoldLevel.modelled);
        await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      }

      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed,
          reason: 'the story must never be gated on performance');
      expect(cubit.state.result.score, greaterThan(0),
          reason: 'never-zero is the house rule');
      expect(cubit.state.result.stepsIndependent, 0);
      expect(cubit.state.result.masterySignal, 0.0);
      await cubit.close();
    });

    test('the ladder escalates one level per wrong attempt', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();
      expect(cubit.state.scaffoldLevel, ScaffoldLevel.initial);

      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      expect(cubit.state.scaffoldLevel, ScaffoldLevel.gentleRetry);

      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      expect(cubit.state.scaffoldLevel, ScaffoldLevel.narrowed);

      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      expect(cubit.state.scaffoldLevel, ScaffoldLevel.modelled);
      await cubit.close();
    });

    test('narrowing keeps the correct option and shrinks the live set',
        () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();
      final String correct = correctOptionFor(cubit);

      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));

      final ActivityStepView? view = cubit.state.view;
      expect(view!.liveOptionIds, contains(correct));
      expect(view.liveOptionIds.length, 2);
      expect(view.dimmedOptionIds.length, 2,
          reason: 'dimmed options keep their slot so the tray cannot reflow');
      await cubit.close();
    });

    test('modelled leaves only the correct option live', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();
      final String correct = correctOptionFor(cubit);

      for (int i = 0; i < 3; i++) {
        await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      }

      expect(cubit.state.view!.liveOptionIds, <String>[correct]);
      expect(cubit.state.view!.highlightOptionId, correct);
      expect(cubit.state.isBoardLocked, isFalse,
          reason: 'the child still performs the action themselves');
      await cubit.close();
    });

    test(
        'a step that can never be judged correct still completes, so a child '
        'is never trapped', () async {
      // The hard version of the guarantee. An engine whose judge() rejects the
      // attempt type a board happens to send would otherwise loop forever, and
      // a four-year-old meets that as the app being broken. After the correct
      // action has been modelled, the next attempt credits the step whatever
      // it was.
      final EchoCubit cubit = makeCubit(stepCount: 2);
      await cubit.start();

      int guard = 0;
      while (cubit.state.status == ActivityStatus.running && guard < 40) {
        guard++;
        await cubit.submit(const ChoiceAttempt('__never_correct__'));
      }

      expect(cubit.state.status, ActivityStatus.finished);
      expect(cubit.state.result.completion, ActivityCompletion.completed);
      expect(cubit.state.result.score, greaterThan(0),
          reason: 'never zero, even here');
      expect(cubit.state.result.stepsIndependent, 0,
          reason: 'the mastery signal must stay honest about what happened');
      await cubit.close();
    });

    test('a wrong attempt never reduces the score', () async {
      final EchoCubit cubit = makeCubit(stepCount: 1);
      await cubit.start();
      final int before = cubit.state.result.score;
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      expect(cubit.state.result.score, before);
      await cubit.close();
    });

    test('hintsUsed accumulates across steps', () async {
      final EchoCubit cubit = makeCubit(stepCount: 2);
      await cubit.start();
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      expect(cubit.state.result.hintsUsed, 2);
      await cubit.close();
    });
  });

  group('Input guards', () {
    test('a locked board ignores attempts', () async {
      final EchoCubit cubit = makeCubit();
      // Deliberately not started: status is loading, so nothing may be
      // submitted. A child tapping during narration must not burn the ladder.
      await cubit.submit(const ChoiceAttempt('anything'));
      expect(cubit.state.status, ActivityStatus.loading);
      await cubit.close();
    });

    test('nothing is emitted after close', () async {
      final EchoCubit cubit = makeCubit();
      await cubit.start();
      final List<ActivityState> seen = <ActivityState>[];
      final sub = cubit.stream.listen(seen.add);
      await cubit.close();
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      await sub.cancel();
      expect(seen, isEmpty);
    });

    test('submitting after finishing is ignored', () async {
      final EchoCubit cubit = makeCubit(stepCount: 1);
      await cubit.start();
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      expect(cubit.state.status, ActivityStatus.finished);
      final int score = cubit.state.result.score;
      await cubit.submit(const ChoiceAttempt('late'));
      expect(cubit.state.result.score, score);
      await cubit.close();
    });
  });

  group('Telemetry', () {
    test('every attempt is recorded with its outcome and story node', () async {
      final EchoCubit cubit = makeCubit(stepCount: 1);
      await cubit.start();
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));

      expect(attempts.recorded.length, 2);
      expect(attempts.recorded.first.outcome, AttemptOutcome.wrongItem);
      expect(attempts.recorded.last.outcome, AttemptOutcome.correct);
      expect(
          attempts.recorded.every((r) => r.storyNodeId == 'test.node'), isTrue);
      expect(attempts.recorded.first.activityId, 'test.echo');
      await cubit.close();
    });

    test('asking for help counts as a hint, not a wrong answer', () async {
      final EchoCubit cubit = makeCubit(stepCount: 1);
      await cubit.start();
      await cubit.submit(const HelpRequestedAttempt());

      expect(cubit.state.result.hintsUsed, 1);
      expect(cubit.state.wrongAttemptsOnStep, 0);
      expect(attempts.recorded.single.outcome, AttemptOutcome.helpRequested);

      // Still counts as independent: asking for the prompt again is not an error.
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      expect(cubit.state.result.stepsIndependent, 1);
      await cubit.close();
    });
  });

  group('Localization', () {
    test('narration follows the session language', () async {
      final EchoCubit cubit = makeCubit(languageCode: 'ar', stepCount: 1);
      await cubit.start();
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      expect(
          narrator.spoken.any((String line) => line.contains('حاول')), isTrue,
          reason:
              'the Arabic hint should have been spoken, not the English one');
      await cubit.close();
    });
  });

  group('Sound', () {
    test('a wrong attempt plays the gentle sound, never a buzzer', () async {
      final EchoCubit cubit = makeCubit(stepCount: 1);
      await cubit.start();
      await cubit.submit(ChoiceAttempt(wrongOptionFor(cubit)));
      expect(soundboard.played, contains(ActivitySound.gentle));
      await cubit.close();
    });

    test('finishing celebrates', () async {
      final EchoCubit cubit = makeCubit(stepCount: 1);
      await cubit.start();
      await cubit.submit(ChoiceAttempt(correctOptionFor(cubit)));
      expect(soundboard.played, contains(ActivitySound.celebrate));
      await cubit.close();
    });
  });
}
