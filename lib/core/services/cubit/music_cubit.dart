import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Music State
class MusicState {
  const MusicState({
    this.isInitialized = false,
    this.isMusicEnabled = true,
    this.isSoundEnabled = true,
    this.isPlaying = false,
    this.shouldPause = false,
    this.volume = 0.3,
    this.isLoading = false,
    this.error,
    this.pauseRequestCount = 0,
    this.musicTrack = 'audio/ton.mp3',
  });
  final bool isInitialized;
  final bool isMusicEnabled;
  final bool isSoundEnabled;
  final bool isPlaying;
  final bool shouldPause;
  final double volume;
  final bool isLoading;
  final String? error;
  final int pauseRequestCount;
  final String musicTrack;

  MusicState copyWith({
    bool? isInitialized,
    bool? isMusicEnabled,
    bool? isSoundEnabled,
    bool? isPlaying,
    bool? shouldPause,
    double? volume,
    bool? isLoading,
    String? error,
    int? pauseRequestCount,
    String? musicTrack,
  }) {
    return MusicState(
      isInitialized: isInitialized ?? this.isInitialized,
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isPlaying: isPlaying ?? this.isPlaying,
      shouldPause: shouldPause ?? this.shouldPause,
      volume: volume ?? this.volume,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pauseRequestCount: pauseRequestCount ?? this.pauseRequestCount,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }
}

// Music Cubit
class MusicCubit extends Cubit<MusicState> with WidgetsBindingObserver {
  MusicCubit() : super(const MusicState()) {
    _initialize();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    super.didChangeAppLifecycleState(appState);
    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.hidden ||
        appState == AppLifecycleState.inactive ||
        appState == AppLifecycleState.detached) {
      if (state.isPlaying) {
        _audioPlayer.pause();
      }
    } else if (appState == AppLifecycleState.resumed) {
      if (state.isMusicEnabled &&
          state.pauseRequestCount == 0 &&
          !state.shouldPause &&
          state.isPlaying) {
        _audioPlayer.resume();
      } else if (state.isMusicEnabled &&
          state.pauseRequestCount == 0 &&
          !state.shouldPause &&
          !state.isPlaying) {
        _playBackgroundMusic();
      }
    }
  }

  late AudioPlayer _audioPlayer;
  static const String _musicEnabledKey = 'music_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _volumeKey = 'music_volume';
  static const String _musicTrackKey = 'music_track';
  bool _hasPlayerListener = false;
  Timer? _musicTimer;

  // Initialize the music service
  Future<void> _initialize() async {
    emit(state.copyWith(isLoading: true));
    print('🎵 MusicCubit: Starting initialization...');

    try {
      // Initialize audio player
      _audioPlayer = AudioPlayer();
      print('🎵 MusicCubit: AudioPlayer created');

      // Load settings
      await _loadSettings();
      print(
          '🎵 MusicCubit: Settings loaded - isMusicEnabled: ${state.isMusicEnabled}, volume: ${state.volume}');

      // Set up audio player configuration
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      print('🎵 MusicCubit: Audio player configured');

      // Test if audio player is working
      print('🎵 MusicCubit: Testing audio player...');
      try {
        await _audioPlayer.setVolume(0.1); // Low volume for testing
        print('🎵 MusicCubit: Volume set successfully');
      } catch (e) {
        print('🎵 MusicCubit: Error setting volume: $e');
      }

      emit(state.copyWith(
        isInitialized: true,
        isLoading: false,
        shouldPause: false,
      ));

      // Start music if enabled
      if (state.isMusicEnabled) {
        print('🎵 MusicCubit: Music is enabled, starting playback...');
        // Add a small delay to ensure audio player is ready
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await _playBackgroundMusic();
      } else {
        print('🎵 MusicCubit: Music is disabled, not starting playback');
      }

      // Force play music after initialization regardless of previous calls
      if (state.isMusicEnabled && !state.isPlaying) {
        print('🎵 MusicCubit: Force playing music after initialization...');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await _playBackgroundMusic();
      }

      // Final attempt to play music
      if (state.isMusicEnabled && !state.isPlaying) {
        print('🎵 MusicCubit: Final attempt to play music...');
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        await _playBackgroundMusic();
      }

      // Set up a timer to ensure music plays after app is fully loaded
      _musicTimer = Timer(const Duration(seconds: 3), () {
        if (state.isMusicEnabled && !state.isPlaying) {
          print('🎵 MusicCubit: Timer-based music start...');
          _playBackgroundMusic();
        }
      });
    } catch (e) {
      print('🎵 MusicCubit: Error during initialization: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to initialize music: $e',
      ));
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      final volume = prefs.getDouble(_volumeKey) ?? 0.3;
      final musicTrack = prefs.getString(_musicTrackKey) ?? 'audio/ton.mp3';

      emit(state.copyWith(
        isMusicEnabled: musicEnabled,
        isSoundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
        volume: volume,
        musicTrack: musicTrack,
      ));
    } catch (e) {
      // Use default values if loading fails
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicEnabledKey, state.isMusicEnabled);
      await prefs.setBool(_soundEnabledKey, state.isSoundEnabled);
      await prefs.setDouble(_volumeKey, state.volume);
      await prefs.setString(_musicTrackKey, state.musicTrack);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to save music settings: $e'));
    }
  }

  // Set background music track and restart playback
  Future<void> setMusicTrack(String track) async {
    emit(state.copyWith(musicTrack: track, isPlaying: false));
    await _saveSettings();
    if (state.isMusicEnabled) {
      await _audioPlayer.stop();
      await _playBackgroundMusic();
    }
  }

  // Set music enabled
  Future<void> setMusicEnabled(bool value) async {
    emit(state.copyWith(isMusicEnabled: value));
    await _saveSettings();

    if (value) {
      await _playBackgroundMusic();
    } else {
      await _stopMusic();
    }
  }

  // Set sound enabled (SFX)
  Future<void> setSoundEnabled(bool value) async {
    emit(state.copyWith(isSoundEnabled: value));
    await _saveSettings();
  }

  // Set volume
  Future<void> setVolume(double value) async {
    emit(state.copyWith(volume: value));
    await _audioPlayer.setVolume(value);
    await _saveSettings();
  }

  // Play background music
  Future<void> playBackgroundMusic() async {
    await _playBackgroundMusic();
  }

  // Internal method to play background music
  Future<void> _playBackgroundMusic() async {
    print(
        '🎵 MusicCubit: _playBackgroundMusic called - initialized: ${state.isInitialized}, enabled: ${state.isMusicEnabled}, shouldPause: ${state.shouldPause}, pauseRequestCount: ${state.pauseRequestCount}');

    if (!state.isInitialized ||
        !state.isMusicEnabled ||
        state.shouldPause ||
        state.pauseRequestCount > 0) {
      print('🎵 MusicCubit: Not playing music - conditions not met');
      return;
    }

    // Prevent multiple simultaneous calls
    if (state.isPlaying) {
      print('🎵 MusicCubit: Music already playing, skipping');
      return;
    }

    try {
      print('🎵 MusicCubit: Attempting to play ton.mp3...');

      // Stop any current playback first
      print('🎵 MusicCubit: Stopping any current playback...');
      await _audioPlayer.stop();

      // Set volume
      print('🎵 MusicCubit: Setting volume to ${state.volume}...');
      await _audioPlayer.setVolume(state.volume);
      print('🎵 MusicCubit: Volume set to ${state.volume}');

      // Play the audio
      print('🎵 MusicCubit: Playing AssetSource: ${state.musicTrack}');
      try {
        await _audioPlayer.play(AssetSource(state.musicTrack));
        print('🎵 MusicCubit: Audio playback started successfully');
      } catch (playError) {
        print('🎵 MusicCubit: Play error: $playError');
        // Try alternative path
        print('🎵 MusicCubit: Trying alternative path...');
        try {
          await _audioPlayer.play(AssetSource('assets/${state.musicTrack}'));
          print('🎵 MusicCubit: Alternative play successful');
        } catch (altError) {
          print('🎵 MusicCubit: Alternative play error: $altError');
          throw playError; // Re-throw original error
        }
      }

      // Add a listener to check player state (only once)
      if (!_hasPlayerListener) {
        _audioPlayer.onPlayerStateChanged.listen((PlayerState playerState) {
          print('🎵 MusicCubit: Player state changed to: $playerState');
        });
        _hasPlayerListener = true;
      }

      emit(state.copyWith(isPlaying: true, shouldPause: false));
    } catch (e, stackTrace) {
      print('🎵 MusicCubit: Error playing music: $e');
      print('🎵 MusicCubit: Stack trace: $stackTrace');
      emit(state.copyWith(error: 'Failed to play music: $e'));
    }
  }

  // Stop music (public method)
  Future<void> stopMusic() async {
    try {
      await _audioPlayer.stop();
      emit(state.copyWith(isPlaying: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to stop music: $e'));
    }
  }

  // Request pause (for educational screens) - increments counter
  Future<void> requestPause() async {
    final newCount = state.pauseRequestCount + 1;
    print('🎵 MusicCubit: Request pause - count: $newCount');
    emit(state.copyWith(pauseRequestCount: newCount));

    if (state.isPlaying) {
      await _audioPlayer.stop();
      emit(state.copyWith(isPlaying: false, shouldPause: true));
    }
  }

  // Release pause (for educational screens) - decrements counter
  Future<void> releasePause() async {
    if (state.pauseRequestCount <= 0) {
      print('🎵 MusicCubit: Release pause - count already 0, ignoring');
      return;
    }

    final newCount = state.pauseRequestCount - 1;
    print('🎵 MusicCubit: Release pause - count: $newCount');

    if (newCount == 0) {
      // All pause requests released, resume music if enabled
      emit(state.copyWith(pauseRequestCount: 0, shouldPause: false));
      if (state.isMusicEnabled && !state.isPlaying) {
        await _playBackgroundMusic();
      }
    } else {
      // Still have pause requests, keep music stopped
      emit(state.copyWith(pauseRequestCount: newCount));
    }
  }

  // Internal stop music method
  Future<void> _stopMusic() async {
    try {
      await _audioPlayer.stop();
      emit(state.copyWith(isPlaying: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to stop music: $e'));
    }
  }

  // Pause music (for TTS or educational sections)
  Future<void> pauseMusic() async {
    if (state.isPlaying) {
      await _audioPlayer.pause();
      emit(state.copyWith(shouldPause: true));
    }
  }

  // Resume music (public method)
  Future<void> resumeMusic() async {
    print(
        '🎵 MusicCubit: resumeMusic called - initialized: ${state.isInitialized}, enabled: ${state.isMusicEnabled}, playing: ${state.isPlaying}, pauseRequestCount: ${state.pauseRequestCount}');

    if (!state.isInitialized) {
      print(
          '🎵 MusicCubit: Not initialized yet, will play after initialization');
      return;
    }

    // Don't resume if there are active pause requests
    if (state.pauseRequestCount > 0) {
      print(
          '🎵 MusicCubit: Not resuming - pause requests active (count: ${state.pauseRequestCount})');
      return;
    }

    if (state.isMusicEnabled && !state.isPlaying) {
      print('🎵 MusicCubit: Conditions met, calling _playBackgroundMusic');
      // Clear shouldPause flag when resuming
      emit(state.copyWith(shouldPause: false));
      await _playBackgroundMusic();
    } else {
      print('🎵 MusicCubit: Not resuming - conditions not met');
    }
  }

  // Test method to manually play audio
  Future<void> testAudio() async {
    print('🎵 MusicCubit: Testing audio playback...');
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(0.5);
      print('🎵 MusicCubit: Test - Playing AssetSource: audio/ton.mp3');
      await _audioPlayer.play(AssetSource('audio/ton.mp3'));
      print('🎵 MusicCubit: Test audio started');
    } catch (e, stackTrace) {
      print('🎵 MusicCubit: Test audio failed: $e');
      print('🎵 MusicCubit: Test audio stack trace: $stackTrace');
    }
  }

  // Force play music (for debugging)
  Future<void> forcePlayMusic() async {
    print('🎵 MusicCubit: Force playing music...');
    emit(state.copyWith(shouldPause: false, isMusicEnabled: true));
    await _playBackgroundMusic();
  }

  // Get current audio player state
  void logAudioState() {
    print(
        '🎵 MusicCubit: Current state - initialized: ${state.isInitialized}, enabled: ${state.isMusicEnabled}, playing: ${state.isPlaying}, shouldPause: ${state.shouldPause}, volume: ${state.volume}');
  }

  // Check if audio file exists
  Future<void> checkAudioFile() async {
    print('🎵 MusicCubit: Checking audio file...');
    try {
      // Try to get duration of the audio file
      final duration = await _audioPlayer.getDuration();
      print('🎵 MusicCubit: Audio file duration: $duration');

      // Try to set source without playing
      await _audioPlayer.setSource(AssetSource('audio/ton.mp3'));
      print('🎵 MusicCubit: Audio file source set successfully');
    } catch (e) {
      print('🎵 MusicCubit: Audio file check failed: $e');
    }
  }

  // Dispose resources
  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _musicTimer?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
