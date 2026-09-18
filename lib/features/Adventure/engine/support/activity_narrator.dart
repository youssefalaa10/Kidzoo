import 'dart:async';

import 'package:kidzo/core/helpers/speech.dart';

/// Speaks story and activity lines, one at a time, and **waits**.
///
/// `Speech.speak` returns on dispatch, not completion. The existing games work
/// around that with scattered magic delays — 500ms in `quiz_cubit.dart:60`,
/// 800ms at :73, 600ms at :81, 550ms and 800ms in `vehicles_game_screen.dart`,
/// 400ms in `sorter_cubit.dart` — and those guesses are why prompts sometimes
/// talk over each other. This centralises the estimate in one place and gives
/// it a cancellation token, so a child who taps ahead silences the queue
/// instead of racing it.
///
/// An interface, not a static facade, so engine cubits are unit-testable with
/// no TTS engine anywhere near them.
abstract class ActivityNarrator {
  /// Speaks [text], resolving when it has plausibly finished.
  ///
  /// **Latest wins.** A second `speak` while one is in flight silences the
  /// first rather than layering over it, and the abandoned call returns early.
  /// That is the only sequencing rule that survives a real child: they tap
  /// ahead, they tap fast, and they re-enter a node while the last line is
  /// still playing. Queueing would make the app talk at them for ten seconds
  /// after they moved on; overlapping would make it unintelligible.
  Future<void> speak(String text);

  /// Abandons anything queued or in flight.
  Future<void> cancel();
}

/// The real narrator, over the app's existing [Speech] facade.
class SpeechActivityNarrator implements ActivityNarrator {
  SpeechActivityNarrator();

  /// Lower bound: even one word needs a beat before the next line starts.
  static const Duration minimumUtterance = Duration(milliseconds: 700);

  /// Upper bound. Nothing a child should sit through is longer than this.
  static const Duration maximumUtterance = Duration(seconds: 8);

  /// Roughly conversational pace for a children's voice.
  static const int millisecondsPerCharacter = 55;

  int _generation = 0;

  static Duration estimateFor(String text) {
    final int estimated = text.characters * millisecondsPerCharacter;
    if (estimated < minimumUtterance.inMilliseconds) {
      return minimumUtterance;
    }
    if (estimated > maximumUtterance.inMilliseconds) {
      return maximumUtterance;
    }
    return Duration(milliseconds: estimated);
  }

  @override
  Future<void> speak(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final int generation = ++_generation;
    // Stop first, always. `Speech.speak` dispatches to a platform engine that
    // happily plays two utterances at once, so without this a child who taps
    // through a beat hears the old line and the new one together. Bumping the
    // generation *before* stopping means an in-flight `speak` sees it lost the
    // race and returns instead of sitting out its own estimate.
    await Speech.stop();
    if (generation != _generation) {
      return;
    }
    await Speech.speak(trimmed);
    if (generation != _generation) {
      return;
    }
    await Future<void>.delayed(estimateFor(trimmed));
  }

  @override
  Future<void> cancel() async {
    _generation++;
    await Speech.stop();
  }
}

/// A narrator that records instead of speaking. Used by every engine test.
class RecordingActivityNarrator implements ActivityNarrator {
  final List<String> spoken = <String>[];
  int cancelCount = 0;

  /// The last thing asked for, whether or not it was empty. Lets a test assert
  /// "nothing new was said" without inferring it from list length.
  String? lastRequested;

  @override
  Future<void> speak(String text) async {
    lastRequested = text;
    if (text.trim().isNotEmpty) {
      spoken.add(text.trim());
    }
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
  }
}

extension on String {
  int get characters => length;
}
