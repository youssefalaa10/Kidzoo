import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/helpers/speech.dart';
import 'package:kidzo/core/services/cubit/music_cubit.dart';

/// Both games share the app's installed voice selection and sound preference.
class PlayAudio {
  final _player = AudioPlayer();
  int _revision = 0;
  bool _disposed = false;
  Future<void> cue(BuildContext context, String ar, String en,
      {String? effect}) async {
    final revision = ++_revision;
    if (_disposed ||
        !(context.read<MusicCubit?>()?.state.isSoundEnabled ?? true)) {
      return;
    }
    final language = Localizations.localeOf(context).languageCode;
    try {
      await Speech.stop();
      if (_disposed || revision != _revision) return;
      if (effect != null) {
        await _player.play(AssetSource('audio/$effect'), volume: .55);
      }
      if (ar.isEmpty && en.isEmpty) return;
      await Speech.configureLanguage(language);
      if (!_disposed && revision == _revision) {
        await Speech.speakAndWait(language == 'ar' ? ar : en);
      }
    } catch (_) {/* Device audio/voice availability is handled by Speech. */}
  }

  Future<void> stop() async {
    _revision++;
    await _player.stop();
    await Speech.stop();
  }

  void dispose() {
    _disposed = true;
    unawaited(stop().whenComplete(_player.dispose));
  }
}

class CandyButton extends StatelessWidget {
  const CandyButton(
      {required this.icon,
      required this.label,
      super.key,
      this.onTap,
      this.orange = false,
      this.size = 64});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool orange;
  final double size;
  @override
  Widget build(BuildContext context) {
    final original = icon == Icons.home_rounded
        ? 'home_button'
        : icon == Icons.lightbulb_outline_rounded
            ? 'hint_button'
            : icon == Icons.arrow_back_rounded
                ? 'back_button'
                : icon == Icons.pause_rounded
                    ? 'pause_button'
                    : orange && icon == Icons.sports_soccer_rounded
                        ? 'shoot_button'
                        : null;
    if (original != null) {
      return Semantics(
          button: true,
          label: label,
          child: Tooltip(
              message: label,
              child: GestureDetector(
                  onTap: onTap,
                  child: Opacity(
                      opacity: onTap == null ? .45 : 1,
                      child: SizedBox(
                          width: size,
                          height: size,
                          child: ClipOval(
                              child: Sprite(original, fit: BoxFit.cover)))))));
    }
    return Semantics(
        button: true,
        label: label,
        child: Tooltip(
            message: label,
            child: GestureDetector(
                onTap: onTap,
                child: Opacity(
                    opacity: onTap == null ? .45 : 1,
                    child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: orange
                                    ? [
                                        const Color(0xffffe855),
                                        const Color(0xffff9300),
                                        const Color(0xffff5300)
                                      ]
                                    : [
                                        const Color(0xff42e8ff),
                                        const Color(0xff006fff),
                                        const Color(0xff0038b0)
                                      ]),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color: orange
                                      ? Colors.orangeAccent
                                      : Colors.lightBlueAccent,
                                  blurRadius: 12),
                              const BoxShadow(
                                  color: Colors.black38,
                                  offset: Offset(0, 4),
                                  blurRadius: 4)
                            ]),
                        child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white54, width: 2)),
                                child: Icon(icon,
                                    color: Colors.white,
                                    size: size * .53))))))));
  }
}

class Sprite extends StatelessWidget {
  const Sprite(this.name, {super.key, this.fit = BoxFit.contain});
  final String name;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/gen/images/play/$name.png',
          fit: fit, gaplessPlayback: true);
}
