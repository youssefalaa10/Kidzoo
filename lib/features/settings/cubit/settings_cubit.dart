import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings State
class SettingsState {
  const SettingsState({
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.isLoading = false,
    this.error,
  });
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool isLoading;
  final String? error;

  SettingsState copyWith({
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Settings Cubit
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('sound_enabled') ?? true;
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      emit(state.copyWith(
        soundEnabled: soundEnabled,
        notificationsEnabled: notificationsEnabled,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      ));
    }
  }


  // Set music enabled (handled by MusicCubit globally)
  Future<void> setMusicEnabled(bool value) async {
    await _saveSettings();
  }


  // Set volume (handled by MusicCubit globally)
  Future<void> setVolume(double value) async {
    await _saveSettings();
  }

  // Reset all settings to default
  Future<void> resetSettings() async {
    emit(state.copyWith(isLoading: true));

    try {
      emit(state.copyWith(
        soundEnabled: true,
        notificationsEnabled: true,
        isLoading: false,
      ));

      await _saveSettings();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to reset settings: $e',
      ));
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', state.soundEnabled);
      await prefs.setBool('notifications_enabled', state.notificationsEnabled);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to save settings: $e'));
    }
  }
}
