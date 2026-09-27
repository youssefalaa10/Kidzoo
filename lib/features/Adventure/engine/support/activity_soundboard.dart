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

  /// Plays a sound **content** named, by asset path under `assets/`.
  ///
  /// The named [ActivitySound] set stays closed on purpose: it is the app's
  /// vocabulary of feedback, and an engine reaching for an asset path is how
  /// every game ended up with its own idea of what "correct" sounds like.
  /// This is the other case — a voice in a rhythm, where *which* sound plays
  /// is the content of the question rather than a reaction to an answer, and
  /// authoring five distinct tones must not require five new enum values.
  ///
  /// Never throws and never blocks the activity. A muted device, a busy audio
  /// session or a path that is not bundled all resolve the same way: nothing
  /// is heard, and the board's visual beat carries the round on its own.
  Future<void> playAsset(String assetPath);

  Future<void> dispose();
}

class AudioActivitySoundboard implements ActivitySoundboard {
  AudioActivitySoundboard({AudioPlayer? player, bool Function()? isEnabled})
      : _player = player ?? AudioPlayer(),
        _isEnabled = isEnabled;

  /// Asked before every sound, rather than read once at construction.
  ///
  /// The child can turn sound off from the settings sheet while an Adventure
  /// is open, and a flag captured in the constructor would keep playing until
  /// they left the chapter. Null means "always on", which is what a host with
  /// no settings of its own wants.
  final bool Function()? _isEnabled;

  bool get _enabled {
    final bool Function()? check = _isEnabled;
    if (check == null) {
      return true;
    }
    // A host whose settings are not in the tree must not take the activity
    // down with it; the sound is the thing that is optional here.
    try {
      return check();
    } catch (error) {
      debugPrint('ActivitySoundboard: could not read the sound setting '
          '($error); playing anyway');
      return true;
    }
  }

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
    if (asset == null || !_enabled) {
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
  Future<void> playAsset(String assetPath) async {
    if (!_enabled) {
      return;
    }
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (error) {
      debugPrint('ActivitySoundboard: could not play $assetPath ($error)');
    }
  }

  @override
  Future<void> dispose() => _player.dispose();
}

/// Records instead of playing. Used by every engine test.
class RecordingActivitySoundboard implements ActivitySoundboard {
  final List<ActivitySound> played = <ActivitySound>[];

  /// Asset paths content asked for, in order. Kept apart from [played] because
  /// they answer different questions: one is "did the app react", the other is
  /// "did the gate sing the right rhythm".
  final List<String> playedAssets = <String>[];

  @override
  Future<void> play(ActivitySound sound) async => played.add(sound);

  @override
  Future<void> playAsset(String assetPath) async => playedAssets.add(assetPath);

  @override
  Future<void> dispose() async {}
}

/// A soundboard with no audio device behind it at all.
///
/// Not a test double: it is what a host installs when audio is unavailable or
/// the child has the app muted. It exists so "no crash when audio is muted" is
/// a state the app can actually be put into and tested in, rather than a
/// property nobody can exercise.
class SilentActivitySoundboard implements ActivitySoundboard {
  const SilentActivitySoundboard();

  @override
  Future<void> play(ActivitySound sound) async {}

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> dispose() async {}
}
