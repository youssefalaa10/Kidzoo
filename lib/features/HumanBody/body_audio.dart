import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kidzo/core/helpers/speech.dart';

enum BodyAudioCue { correct, retry, celebrate }

abstract class BodyAudio {
  Future<bool> say(String text, {BodyAudioCue? cue});
  Future<void> stop();
  Future<void> dispose();
}

/// Uses Kidzo's configured device/Azure voice; no nonexistent recording paths.
/// A quiet piano note replaces the app's harsher wrong-answer buzzer.
class SpeechBodyAudio implements BodyAudio {
  SpeechBodyAudio({required AudioPlayer effects, required String languageCode})
      : _effects = effects,
        _voiceReady = Speech.configureLanguage(languageCode);
  final AudioPlayer _effects;
  final Future<SpeechRoute> _voiceReady;
  int _revision = 0;
  bool _disposed = false;

  @override
  Future<bool> say(String text, {BodyAudioCue? cue}) async {
    final int revision = ++_revision;
    try {
      await Speech.stop();
      if (_disposed || revision != _revision) return true;
      try {
        await _effects.stop();
        if (cue != null) {
          final String asset = switch (cue) {
            BodyAudioCue.correct => 'audio/success.mp3',
            BodyAudioCue.retry => 'audio/piano-d.wav',
            BodyAudioCue.celebrate => 'audio/score.mp3',
          };
          if (_disposed || revision != _revision) return true;
          await _effects.play(AssetSource(asset), volume: 0.25);
        }
      } catch (error) {
        debugPrint('Human Body effect unavailable: $error');
      }
      if (_disposed || revision != _revision) return true;
      await _voiceReady;
      if (_disposed || revision != _revision) return true;
      final SpeechOutcome outcome = await Speech.speakAndWait(text);
      return outcome != SpeechOutcome.failed &&
          outcome != SpeechOutcome.skipped;
    } catch (error) {
      debugPrint('Human Body audio unavailable: $error');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _revision++;
    await Speech.stop();
    // Stop effects as well as speech, including when muted or backgrounded.
    try {
      await _effects.stop();
    } catch (error) {
      debugPrint('Human Body effect stop: $error');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _effects.dispose();
  }
}
