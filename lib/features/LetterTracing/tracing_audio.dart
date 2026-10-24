import 'package:audioplayers/audioplayers.dart';
import 'package:kidzo/core/helpers/speech.dart';

abstract class TracingAudio {
  Future<bool> play(String clip, {bool success = false});
  Future<void> stop();
  Future<void> dispose();
}

/// Letter names and guidance use the shared, locale-aware TTS voice.
class TtsTracingAudio implements TracingAudio {
  TtsTracingAudio({required this.enabled, required this.appLanguageCode});
  final bool Function() enabled;
  final String appLanguageCode;
  final _effect = AudioPlayer();
  int _generation = 0;
  bool _disposed = false;
  String? _voiceLanguageCode;

  @override
  Future<bool> play(String clip, {bool success = false}) async {
    final generation = ++_generation;
    try {
      await Speech.stop();
      await _effect.stop();
      if (_disposed || generation != _generation || !enabled()) return true;
      if (success) {
        await _effect.play(AssetSource('audio/success.mp3'), volume: .25);
      }
      if (_disposed || generation != _generation || !enabled()) return true;
      final languageCode = clip.startsWith('ar_') ? 'ar' : 'en';
      if (_voiceLanguageCode != languageCode) {
        await Speech.configureLanguage(languageCode);
        _voiceLanguageCode = languageCode;
      }
      if (_disposed || generation != _generation || !enabled()) return true;
      final outcome = await Speech.speakAndWait(_textForClip(clip));
      return outcome != SpeechOutcome.failed &&
          outcome != SpeechOutcome.skipped;
    } catch (error) {
      return false;
    }
  }

  String _textForClip(String clip) {
    final parts = clip.split('_');
    final arabic = parts.first == 'ar';
    final cue = parts.length > 1 ? parts[1] : '';
    if (int.tryParse(cue) case final index?) {
      if (arabic) {
        const names = [
          'ألف',
          'باء',
          'تاء',
          'ثاء',
          'جيم',
          'حاء',
          'خاء',
          'دال',
          'ذال',
          'راء',
          'زاي',
          'سين',
          'شين',
          'صاد',
          'ضاد',
          'طاء',
          'ظاء',
          'عين',
          'غين',
          'فاء',
          'قاف',
          'كاف',
          'لام',
          'ميم',
          'نون',
          'هاء',
          'واو',
          'ياء'
        ];
        return names[index.clamp(0, names.length - 1)];
      }
      return String.fromCharCode(65 + index.clamp(0, 25));
    }
    if (!arabic) {
      return switch (cue) {
        'begin' => 'Trace the letter with your finger. Let us go!',
        'hint' => 'Watch the path, then try again.',
        'success' => 'Great job! You did it!',
        _ => cue,
      };
    }
    return switch (cue) {
      'begin' => 'يلا امشي بإصبعك على الحرف!',
      'hint' => 'بص على الطريق وجرب تاني.',
      'success' => 'عاش يا شاطر! الحرف طلع حلو!',
      _ => cue,
    };
  }

  @override
  Future<void> stop() async {
    _generation++;
    await Future.wait([Speech.stop(), _effect.stop()]);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _effect.dispose();
    await Speech.configureLanguage(appLanguageCode);
  }
}
