import 'dart:async';

import 'package:kidzo/core/helpers/speech.dart';

/// Speaks story and activity lines, one at a time, and **waits**.
///
/// The contract every caller depends on: **when `speak` resolves, the audio
/// has stopped.** Sequencing in this feature is built on that — the cubit does
/// `await _speakReveal(); await _advance();` — so the promise has to be real.
///
/// It used to be a guess. `Speech.speak` returns on dispatch, so this class
/// waited out `55ms × characters`, capped at eight seconds. A line longer than
/// about 145 characters therefore released the story *while the narrator was
/// still talking*, which is exactly the bug a child sees as the game running
/// away from the voice. The wait now comes from `Speech.speakAndWait`, which
/// resolves off the engine's own completion callback.
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

  /// True while something is being spoken. For UI that needs to show a
  /// "listening" state without owning the narration itself.
  bool get isSpeaking;
}

/// The real narrator, over the app's existing [Speech] facade.
class SpeechActivityNarrator implements ActivityNarrator {
  SpeechActivityNarrator();

  int _generation = 0;

  /// Completed to release the current waiter early when it is superseded.
  ///
  /// Without this, a superseded call kept waiting on audio that had already
  /// been replaced, woke up late, and ran its caller's `_advance()` on top of
  /// the line that replaced it. Checking the generation *before* the wait was
  /// never enough: the damage is done by what happens *after* it.
  Completer<void>? _abandoned;

  @override
  bool get isSpeaking => Speech.isSpeaking;

  @override
  Future<void> speak(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final int generation = ++_generation;
    // Silence first, release second. Letting the previous waiter go while its
    // line is still audible would hand a caller permission to start the next
    // scene over the tail of the last one - the exact overlap this class
    // exists to prevent, just moved one step earlier.
    await Speech.stop();
    _releaseCurrentWaiter();
    if (generation != _generation) {
      return;
    }

    final Completer<void> abandoned = Completer<void>();
    _abandoned = abandoned;

    // `speakAndWait` stops whatever is playing before it starts, so two lines
    // can never overlap, and it resolves only once the audio has stopped.
    final Future<void> spoken = Speech.speakAndWait(trimmed);

    // Whichever comes first: the utterance ending, or this call being
    // superseded. Both mean "audio belonging to me is no longer playing",
    // which is the only thing the caller is waiting to hear.
    await Future.any<void>(<Future<void>>[spoken, abandoned.future]);

    if (generation == _generation) {
      _abandoned = null;
    }
  }

  @override
  Future<void> cancel() async {
    _generation++;
    // Stop the audio first, then release the waiter - a waiter let go while
    // sound is still coming out is the whole failure mode being fixed here.
    await Speech.stop();
    _releaseCurrentWaiter();
  }

  void _releaseCurrentWaiter() {
    final Completer<void>? abandoned = _abandoned;
    _abandoned = null;
    if (abandoned != null && !abandoned.isCompleted) {
      abandoned.complete();
    }
  }
}

/// A narrator that records instead of speaking. Used by every engine test.
class RecordingActivityNarrator implements ActivityNarrator {
  final List<String> spoken = <String>[];
  int cancelCount = 0;

  @override
  bool get isSpeaking => false;

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
