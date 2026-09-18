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
  /// Speaks [text], resolving when it has plausibly finished. Returns early if
  /// [cancel] is called.
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

  @override
  Future<void> speak(String text) async {
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
