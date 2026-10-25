import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kidzo/core/helpers/speech.dart';
import 'body_audio_clips.dart';

enum BodyAudioCue { correct, retry, celebrate }

abstract class BodyAudio {
  Future<bool> say(String text, {BodyAudioCue? cue});
  Future<void> stop();
  Future<void> dispose();
}

/// Uses VoiceTut-TTS (Yasmin) pre-rendered clips for Arabic voice narration,
/// falling back to Kidzo's configured device/Azure voice for other locales.
/// A quiet piano note replaces the app's harsher wrong-answer buzzer.
class SpeechBodyAudio implements BodyAudio {
  SpeechBodyAudio({
    required AudioPlayer effects,
    required String languageCode,
    AudioPlayer? voice,
  })  : _effects = effects,
        _voice = voice ?? AudioPlayer(),
        _voiceReady = Speech.configureLanguage(languageCode);

  final AudioPlayer _effects;
  final AudioPlayer _voice;
  final Future<SpeechRoute> _voiceReady;
  int _revision = 0;
  bool _disposed = false;
  Completer<bool>? _voiceCompleter;

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

      // Use pre-rendered Arabic clip if available (synthesized with Yasmin via voicetut-tts)
      final String? arabicClip = bodyArabicAudioClips[text];
      if (arabicClip != null) {
        return await _playVoiceAsset(arabicClip, revision);
      }

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

  Future<bool> _playVoiceAsset(String asset, int revision) async {
    try {
      await _voice.stop();
      if (_disposed || revision != _revision) return true;
      final Completer<bool> completer = Completer<bool>();
      _voiceCompleter = completer;
      late final StreamSubscription<void> sub;
      sub = _voice.onPlayerComplete.listen((_) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(true);
      });
      await _voice.play(AssetSource(asset));
      return await completer.future;
    } catch (error) {
      debugPrint('Human Body voice unavailable: $error');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _revision++;
    if (_voiceCompleter != null && !_voiceCompleter!.isCompleted) {
      _voiceCompleter!.complete(true);
    }
    await Speech.stop();
    // Stop effects as well as speech, including when muted or backgrounded.
    try {
      await _effects.stop();
    } catch (error) {
      debugPrint('Human Body effect stop: $error');
    }
    try {
      await _voice.stop();
    } catch (error) {
      debugPrint('Human Body voice stop: $error');
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _effects.dispose();
    await _voice.dispose();
  }
}
