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
  bool _hasRequestedPause = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _musicCubit = context.read<MusicCubit>();
  }

  @override
  void initState() {
    super.initState();
    // Request pause immediately to stop music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPause();
    });
  }

  @override
  void dispose() {
    // Release pause when leaving educational screen
    _releasePause();
    super.dispose();
  }

  /// Request pause for background music (increments counter)
  void _requestPause() {
    if (!_hasRequestedPause) {
      print('🎵 TTSMusicMixin: Requesting pause for background music');
      _musicCubit?.requestPause();
      _hasRequestedPause = true;
    }
  }

  /// Release pause for background music (decrements counter)
  void _releasePause() {
    if (_hasRequestedPause) {
      print('🎵 TTSMusicMixin: Releasing pause for background music');
      _musicCubit?.releasePause();
      _hasRequestedPause = false;
    }
  }

  /// Stop music completely for TTS speech (no interference)
  void stopForSpeech() {
    _musicCubit?.stopMusic();
  }

  /// Resume music after speech is done (only if no other screens need pause)
  void resumeAfterSpeech() {
    // Don't resume if we still have pause requests
    // The releasePause will handle resuming when all screens are gone
    // This method is kept for compatibility but won't resume if pause is active
    final state = _musicCubit?.state;
    if (state != null && state.pauseRequestCount == 0) {
      _musicCubit?.resumeMusic();
    }
  }
}
