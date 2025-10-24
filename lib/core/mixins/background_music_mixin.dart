import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/cubit/music_cubit.dart';

/// Mixin for screens that should have background music
/// Use this for game screens, home screen, settings, etc.
mixin BackgroundMusicMixin<T extends StatefulWidget> on State<T> {
  MusicCubit? _musicCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _musicCubit = context.read<MusicCubit>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeBackgroundMusic();
    });
  }

  @override
  void dispose() {
    // Don't stop music when disposing, let it continue for other screens
    super.dispose();
  }

  /// Resume background music when entering this screen
  void _resumeBackgroundMusic() {
    print('🎵 BackgroundMusicMixin: Resuming background music');
    _musicCubit?.resumeMusic();
  }
}

/// Mixin for educational screens or screens with TTS
/// Use this for alphabet learning, number learning, etc.
/// This completely stops background music to avoid تداخل (interference)
mixin TTSMusicMixin<T extends StatefulWidget> on State<T> {
  MusicCubit? _musicCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _musicCubit = context.read<MusicCubit>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stopBackgroundMusic();
    });
  }

  @override
  void dispose() {
    // Resume music when leaving educational screen
    _resumeBackgroundMusic();
    super.dispose();
  }

  /// Stop background music completely for TTS screens
  void _stopBackgroundMusic() {
    print('🎵 TTSMusicMixin: Stopping background music');
    _musicCubit?.stopMusic();
  }

  /// Resume background music after leaving TTS screen
  void _resumeBackgroundMusic() {
    _musicCubit?.resumeMusic();
  }

  /// Stop music completely for TTS speech (no interference)
  void stopForSpeech() {
    _musicCubit?.stopMusic();
  }

  /// Resume music after speech is done
  void resumeAfterSpeech() {
    _musicCubit?.resumeMusic();
  }
}
