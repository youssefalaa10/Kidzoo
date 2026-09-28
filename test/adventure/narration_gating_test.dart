import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/helpers/speech.dart';
import 'package:kidzo/features/Adventure/data/adventure_content_loader.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_attempt.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_cubit.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_registry.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_state.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/default_engines.dart';
import 'package:kidzo/features/Adventure/engine/engines/hidden_clue/hidden_clue_engine.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_narrator.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_services.dart';
import 'package:kidzo/features/Adventure/engine/support/activity_soundboard.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';
import 'package:kidzo/features/Adventure/story/ui/story_beat_view.dart';

import 'support/disk_content_source.dart';
import 'support/echo_engine.dart';

/// A narrator that only finishes when the test says so.
///
/// Every other narrator in the suite resolves synchronously, which is exactly
/// why none of them ever caught the story running ahead of the voice: with an
/// instant narrator there is no window in which to transition early. This one
/// holds the window open.
class ControllableNarrator implements ActivityNarrator {
  final List<String> spoken = <String>[];
  final List<Completer<void>> _pending = <Completer<void>>[];
  int cancelCount = 0;

  /// Order matters: `cancel` must stop the audio before it releases a waiter,
  /// so the test records what happened and in which order.
  final List<String> log = <String>[];

  bool get isPending => _pending.any((Completer<void> c) => !c.isCompleted);

  @override
  bool get isSpeaking => isPending;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    log.add('speak:$text');
    final Completer<void> completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
    log.add('cancel');
    finishAll();
  }

  /// Finishes the utterance started [index] calls ago (0 = the first).
  void finish(int index) {
    final Completer<void> completer = _pending[index];
    if (!completer.isCompleted) {
      log.add('finished:${spoken[index]}');
      completer.complete();
    }
  }

  void finishLast() => finish(_pending.length - 1);

  void finishAll() {
    for (int index = 0; index < _pending.length; index++) {
      finish(index);
    }
  }
}

StoryNode _beat(List<String> lines) {
  return StoryNode(
    nodeId: 'test.beat',
    beat: StoryBeat.openingProblem,
    kind: StoryNodeKind.storyBeat,
    lines: lines
        .map((String line) => LocalizedText(<String, String>{'en': line}))
        .toList(),
  );
}

void main() {
  Widget host({
    required StoryNode node,
    required Future<void> Function(String) onSpeak,
    required VoidCallback onContinue,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StoryBeatView(
          node: node,
          languageCode: 'en',
          onSpeak: onSpeak,
          onContinue: onContinue,
          continueLabel: 'Play',
          nextLabel: 'Next',
          replayLabel: 'Say it again',
        ),
      ),
    );
  }

  group('A beat never hands off while it is still talking', () {
    testWidgets('taps during narration are absorbed, not queued',
        (WidgetTester tester) async {
      // The acceptance criterion, as a test: story starts, narration finishes,
      // *then* the transition. Before this gate existed a single tap handed off
      // mid-sentence, so the next activity spoke its prompt over the line that
      // was introducing it.
      final ControllableNarrator narrator = ControllableNarrator();
      int continued = 0;

      await tester.pumpWidget(host(
        node: _beat(<String>['The only line.']),
        onSpeak: narrator.speak,
        onContinue: () => continued++,
      ));
      await tester.pump();

      expect(narrator.spoken, <String>['The only line.']);

      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.tap(find.text('Play'));
      await tester.pump();
      await tester.tap(find.text('Play'));
      await tester.pump();

      expect(continued, 0,
          reason: 'the narrator is still speaking; nothing may transition');

      narrator.finishLast();
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(continued, 1, reason: 'once the voice stops, the tap works');
    });

    testWidgets('a mid-beat line does not advance while it is speaking',
        (WidgetTester tester) async {
      final ControllableNarrator narrator = ControllableNarrator();

      await tester.pumpWidget(host(
        node: _beat(<String>['First line.', 'Second line.']),
        onSpeak: narrator.speak,
        onContinue: () {},
      ));
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Second line.'), findsNothing,
          reason: 'the first line has not finished being spoken');
      expect(narrator.spoken.length, 1);

      narrator.finish(0);
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Second line.'), findsOneWidget);
      expect(narrator.spoken.length, 2);
    });

    testWidgets('a superseded line resolving late cannot unlock a newer one',
        (WidgetTester tester) async {
      // The stale-waiter race. The replay button starts a second utterance for
      // the same line; when the first one's future finally resolves it must not
      // be mistaken for the second one finishing, or the beat unlocks while the
      // replay is still audible.
      final ControllableNarrator narrator = ControllableNarrator();
      int continued = 0;

      await tester.pumpWidget(host(
        node: _beat(<String>['The only line.']),
        onSpeak: narrator.speak,
        onContinue: () => continued++,
      ));
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Say it again'));
      await tester.pump();
      expect(narrator.spoken.length, 2);

      // The *first* utterance resolves, late. The second is still going.
      narrator.finish(0);
      await tester.pump();

      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(continued, 0,
          reason: 'the stale future says nothing about the line now playing');

      narrator.finish(1);
      await tester.pump();
      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(continued, 1);
    });

    testWidgets('an empty line never locks the child out',
        (WidgetTester tester) async {
      // A missing string is a content bug. It must not become a child stuck on
      // a button that will never light up.
      final ControllableNarrator narrator = ControllableNarrator();
      int continued = 0;

      await tester.pumpWidget(host(
        node: _beat(<String>['']),
        onSpeak: narrator.speak,
        onContinue: () => continued++,
      ));
      await tester.pump();

      expect(narrator.spoken, isEmpty);

      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(continued, 1);
    });

    testWidgets('the beat still hands off exactly once, however fast the taps',
        (WidgetTester tester) async {
      final ControllableNarrator narrator = ControllableNarrator();
      int continued = 0;

      await tester.pumpWidget(host(
        node: _beat(<String>['The only line.']),
        onSpeak: narrator.speak,
        onContinue: () => continued++,
      ));
      await tester.pump();
      narrator.finishLast();
      await tester.pump();

      await tester.tap(find.text('Play'), warnIfMissed: false);
      await tester.tap(find.text('Play'), warnIfMissed: false);
      await tester.tap(find.text('Play'), warnIfMissed: false);
      await tester.pump();

      expect(continued, 1);
    });
  });

  group('An activity step waits for its reveal line', () {
    ActivityCubit<EchoContent, dynamic> echoCubit(ActivityNarrator narrator) {
      const EchoEngine engine = EchoEngine();
      return engine.createCubit(engine.createSession(
        spec: echoSpec(stepCount: 2, optionCount: 2),
        services: ActivityServices(
          narrator: narrator,
          soundboard: RecordingActivitySoundboard(),
          random: Random(7),
        ),
        packs: const MapItemPackResolver(<String, ItemPack>{}),
      ));
    }

    test('the prompt is awaited before the board unlocks', () async {
      final ControllableNarrator narrator = ControllableNarrator();
      final ActivityCubit<EchoContent, dynamic> cubit = echoCubit(narrator);

      final Future<void> started = cubit.start();
      await pumpEventQueue();

      expect(cubit.state.isBoardLocked, isTrue,
          reason: 'a child must not be able to answer over the question');

      narrator.finishAll();
      await started;

      expect(cubit.state.isBoardLocked, isFalse);
      await cubit.close();
    });

    test('a step boundary is never instantaneous, even when nothing is said',
        () async {
      // The silent path. `_speak` drops an empty or repeated line and returns
      // at once, so without a deliberate settle the next step replaced the
      // board in the very frame the child tapped.
      final RecordingActivityNarrator narrator = RecordingActivityNarrator();
      final ActivityCubit<EchoContent, dynamic> cubit = echoCubit(narrator);
      await cubit.start();

      final int firstStep = cubit.state.stepIndex;
      final Future<void> submitted =
          cubit.submit(const ChoiceAttempt('step0_opt0'));
      await pumpEventQueue();

      expect(cubit.state.stepIndex, firstStep,
          reason: 'the echo engine publishes no reveal line, so the only '
              'thing separating the two steps is the settle');

      await submitted;
      expect(cubit.state.stepIndex, greaterThan(firstStep));
      await cubit.close();
    });
  });

  group('The find-the-page activity finishes only after it stops talking', () {
    late AdventureContentBundle bundle;
    late ActivityEngineRegistry registry;

    setUpAll(() async {
      registry = buildDefaultEngineRegistry();
      bundle =
          await const AdventureContentLoader(DiskAdventureContentSource())
              .load();
    });

    test('the reveal and the closing line both gate the result screen',
        () async {
      // The last stage of Adventure 1, end to end against real content. The
      // host shows its result view the moment the cubit reports `finished`, and
      // the story advances from there - so reporting finished while the closing
      // line is still playing is the whole bug, one screen further along.
      final ControllableNarrator narrator = ControllableNarrator();
      final ActivitySpec spec = bundle.requireActivity('jungle_find_page');
      final ActivityEngine<ActivityContent> engine =
          registry.require(spec.engineId);
      final ActivityCubit<ActivityContent, dynamic> cubit =
          engine.createCubit(engine.createSession(
        spec: spec,
        services: ActivityServices(
          narrator: narrator,
          soundboard: RecordingActivitySoundboard(),
          random: Random(3),
        ),
        packs: bundle.packResolver,
        storyNodeId: 'jungle.n6',
      ));

      final Future<void> started = cubit.start();
      await pumpEventQueue();
      expect(cubit.state.isBoardLocked, isTrue,
          reason: 'the child cannot search over the question');
      narrator.finishAll();
      await started;
      expect(cubit.state.isBoardLocked, isFalse);

      final HiddenClueStep step = cubit.state.engineStep! as HiddenClueStep;
      final Future<void> found = cubit.submit(ChoiceAttempt(step.clue.id));

      await pumpEventQueue();
      expect(cubit.state.status, ActivityStatus.running,
          reason: 'the page has just been named aloud; that line must finish');

      narrator.finishAll();
      await pumpEventQueue();
      expect(cubit.state.status, ActivityStatus.running,
          reason: 'the closing line is now playing, and it gates the result '
              'screen exactly as the reveal did');

      narrator.finishAll();
      await found;
      expect(cubit.state.status, ActivityStatus.finished);
      await cubit.close();
    });
  });

  group('Speech always resolves, and never while audio may be playing', () {
    setUp(Speech.reset);
    tearDown(Speech.reset);

    test('an empty line is skipped outright', () async {
      expect(await Speech.speakAndWait('   '), SpeechOutcome.skipped);
    });

    test('with no engine attached it fails rather than hanging', () async {
      // The liveness guarantee. A caller awaiting this is a child looking at a
      // button, so "never resolves" is not an acceptable failure mode.
      expect(
        await Speech.speakAndWait('anything').timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw StateError('speakAndWait hung'),
        ),
        SpeechOutcome.failed,
      );
      expect(Speech.isSpeaking, isFalse,
          reason: 'a failed utterance must not leave a waiter behind');
    });

    test('the watchdog always outlasts the estimate it is sized from', () {
      // It is a liveness guard, not the transition signal, so it must never be
      // the thing that ends a healthy utterance. A watchdog at or below the
      // estimate would just be the capped timer this work set out to remove.
      for (final String line in <String>[
        'Hi.',
        'Noor had a book, and the Green Page blew into the jungle.',
        'x' * 400,
      ]) {
        expect(Speech.watchdogFor(line), greaterThan(Speech.estimateFor(line)));
      }
      // A long line is where the old estimate failed worst: it was capped at
      // eight seconds and released the story while the voice was still going.
      // The watchdog has to leave generous room beyond that cap.
      expect(Speech.watchdogFor('x' * 400),
          greaterThan(Speech.maximumUtterance * 2));
    });

    test('stop settles a pending utterance rather than stranding it', () async {
      // `stop` is what backgrounding, superseding and abandoning all funnel
      // into, and each of them has a caller awaiting the narration.
      await Speech.stop();
      expect(Speech.isSpeaking, isFalse);
    });
  });

  group('The narrator releases its waiter only once audio has stopped', () {
    test('cancel stops the engine before it lets the waiter go', () async {
      // Ordering is the whole guarantee. A waiter released while sound is
      // still coming out is the bug, not the fix.
      Speech.reset();
      addTearDown(Speech.reset);

      final SpeechActivityNarrator narrator = SpeechActivityNarrator();
      bool resolved = false;
      final Future<void> speaking =
          narrator.speak('a line').then((_) => resolved = true);

      await pumpEventQueue();
      await narrator.cancel();
      await speaking;

      expect(resolved, isTrue);
      expect(Speech.isSpeaking, isFalse);
    });

    test('a superseded line releases at once instead of waking up late',
        () async {
      Speech.reset();
      addTearDown(Speech.reset);

      final SpeechActivityNarrator narrator = SpeechActivityNarrator();
      final Future<void> first = narrator.speak('the first line');
      final Future<void> second = narrator.speak('the second line');

      await first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw StateError('the superseded line never released'),
      );
      await second;
    });
  });
}
