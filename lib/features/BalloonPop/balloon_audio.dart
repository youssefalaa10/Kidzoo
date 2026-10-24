import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kidzo/core/helpers/speech.dart';

abstract class BalloonAudio {
  Future<void> speak(List<String> clips);
  Future<void> effect(String name);
  Future<void> stop();
  Future<void> dispose();
}

/// Short effects stay on their own lane; spoken guidance uses shared TTS.
class TtsBalloonAudio implements BalloonAudio {
  TtsBalloonAudio({required this.enabled});
  final bool Function() enabled;
  final _effect = AudioPlayer();
  int _voiceRevision = 0, _effectRevision = 0;
  bool _disposed = false;
  Future<void> _effectLane = Future.value();

  @override
  Future<void> speak(List<String> clips) async {
    final revision = ++_voiceRevision;
    if (_disposed || !enabled()) return;
    await Speech.stop();
    for (final clip in clips) {
      if (_disposed || !enabled() || revision != _voiceRevision) return;
      await Speech.speakAndWait(_textForClip(clip));
    }
  }

  String _textForClip(String clip) {
    const values = <String, String>{
      'en_welcome': 'Welcome to Balloon Park! Tap a balloon to pop it!',
      'ar_welcome': 'يلا نلعب في حديقة البالونات! دوس على بالونة وفرقعها!',
      'en_free': 'Pop any balloon. Let us play!',
      'ar_free': 'اختار أي بالونة وفرقعها! يلا نلعب!',
      'en_correct': 'Wonderful!',
      'ar_correct': 'عاش يا شاطر!',
      'en_guidance': 'Nice pop! Let us find this one.',
      'ar_guidance': 'حلوة دي! يلا ندور على البالونة المطلوبة.',
      'en_complete': 'Hooray! You made a balloon party!',
      'ar_complete': 'يا سلام! حفلة بالونات جميلة!',
      'en_challenge':
          'Open challenge! Pop quickly to build your combo. Finish whenever you like!',
      'ar_challenge':
          'تحدي مفتوح! فرقع بسرعة عشان تزود نقاطك، واخلص وقت ما تحب!',
      'en_challenge_wave': 'A new wave! The balloons are getting faster!',
      'ar_challenge_wave': 'موجة جديدة! البالونات بقت أسرع!',
      'en_challenge_combo': 'Amazing combo! Five times the points!',
      'ar_challenge_combo': 'إيه الحلاوة دي! نقاطك بقت خمسة أضعاف!',
      'en_challenge_complete': 'What a challenge! Look at all your points!',
      'ar_challenge_complete': 'يا لهوي على الشطارة! شوف جبت كام نقطة!',
    };
    final target = RegExp(r'^(en|ar)_(colors|numbers|english|arabic)_(\d+)$')
        .firstMatch(clip);
    if (target != null) {
      final index = int.parse(target.group(3)!);
      final value = switch (target.group(2)) {
        'colors' => (target.group(1) == 'ar'
            ? ['الأحمر', 'الأزرق', 'الأصفر', 'البنفسجي', 'الأخضر', 'الوردي']
            : ['red', 'blue', 'yellow', 'purple', 'green', 'pink'])[index],
        'numbers' => '${index + 1}',
        'english' => String.fromCharCode(65 + index),
        _ => ['ألف', 'باء', 'تاء', 'ثاء', 'جيم', 'حاء'][index],
      };
      if (target.group(1) == 'ar') {
        return switch (target.group(2)) {
          'colors' => 'فرقع البالونة $value!',
          'numbers' => 'دور على الرقم $value!',
          'english' => 'فرقع بالونة حرف $value!',
          _ => 'فرقع بالونة حرف $value!',
        };
      }
      return 'Pop the $value balloon!';
    }
    return values[clip] ?? clip;
  }

  @override
  Future<void> effect(String name) {
    final revision = ++_effectRevision;
    _effectLane = _effectLane.then((_) async {
      if (_disposed || revision != _effectRevision || !enabled()) return;
      await _effect.stop();
      if (_disposed || revision != _effectRevision || !enabled()) return;
      await _effect.play(AssetSource('audio/balloon/$name'), volume: .38);
    }).catchError((Object error) => debugPrint('Balloon effect: $error'));
    return _effectLane;
  }

  @override
  Future<void> stop() async {
    _voiceRevision++;
    _effectRevision++;
    await Speech.stop();
    _effectLane = _effectLane.then((_) => _effect.stop());
    await _effectLane;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _effect.dispose();
  }
}
