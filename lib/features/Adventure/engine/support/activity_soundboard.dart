import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The small fixed set of sounds an activity can make.
///
/// Named by intent rather than by file, so an engine never reaches for an asset
/// path and the whole app can be re-scored by editing one map. Note there is no
/// "failure" sound: the no-fail regime has no buzzer.
enum ActivitySound {
  /// A correct step.
  success,

  /// A wrong attempt. Encouraging, not punitive.
  gentle,

  /// A token picked up or a card turned.
  tap,

  /// The whole activity finished.
  celebrate,
}

/// Plays short effects. An interface so engine tests stay silent and fast.
abstract class ActivitySoundboard {
  Future<void> play(ActivitySound sound);
  Future<void> dispose();
}

class AudioActivitySoundboard implements ActivitySoundboard {
  AudioActivitySoundboard({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  static const Map<ActivitySound, String> _assetForSound =
      <ActivitySound, String>{
    ActivitySound.success: 'audio/success.mp3',
    ActivitySound.gentle: 'audio/wrong.mp3',
    ActivitySound.tap: 'audio/boop.wav',
    ActivitySound.celebrate: 'audio/score.mp3',
  };

  final AudioPlayer _player;

  @override
  Future<void> play(ActivitySound sound) async {
    final String? asset = _assetForSound[sound];
    if (asset == null) {
      return;
    }
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (error) {
      // A missing or busy audio device must never take down an activity.
      debugPrint('ActivitySoundboard: could not play $asset ($error)');
    }
  }

  @override
  Future<void> dispose() => _player.dispose();
}

/// Records instead of playing. Used by every engine test.
class RecordingActivitySoundboard implements ActivitySoundboard {
  final List<ActivitySound> played = <ActivitySound>[];

  @override
  Future<void> play(ActivitySound sound) async => played.add(sound);

  @override
  Future<void> dispose() async {}
}
