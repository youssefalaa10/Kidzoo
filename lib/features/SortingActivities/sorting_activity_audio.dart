import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kidzo/core/helpers/speech.dart';

abstract class SortingActivityAudio {
  /// Reports voice availability so the visible captions can explain silence.
  Future<bool> say(String text, {String? effect});
  Future<void> stop();
  Future<void> dispose();
}

/// Uses the configured Kidzo voice and one quiet effect player. Latest wins.
class SpeechSortingActivityAudio implements SortingActivityAudio {
  SpeechSortingActivityAudio(
      {required AudioPlayer effects, required this.isEnabled})
      : _effects = effects;
  final AudioPlayer _effects;
  final bool Function() isEnabled;
  int _generation = 0;
  bool _disposed = false;

  @override
  Future<bool> say(String text, {String? effect}) async {
    final generation = ++_generation;
    try {
      await Speech.stop();
      if (_disposed || generation != _generation || !isEnabled()) return true;
      await _effects.stop();
      if (_disposed || generation != _generation || !isEnabled()) return true;
      if (effect != null) {
        try {
          await _effects.play(AssetSource(effect), volume: .38);
        } catch (error) {
          debugPrint('Sorting effect unavailable: $error');
        }
      }
      if (_disposed || generation != _generation || !isEnabled()) return true;
      final outcome = await Speech.speakAndWait(text);
      return outcome != SpeechOutcome.failed &&
          outcome != SpeechOutcome.skipped;
    } catch (error) {
      debugPrint('Sorting audio unavailable: $error');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    // Both stop requests happen immediately, even if one platform call fails.
    await Future.wait([
      Speech.stop()
          .catchError((Object e) => debugPrint('Sorting voice stop: $e')),
      _effects
          .stop()
          .catchError((Object e) => debugPrint('Sorting effect stop: $e')),
    ]);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _effects.dispose();
  }
}
