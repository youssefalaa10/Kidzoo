import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Sound settings
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }

  // Music settings
  bool _musicEnabled = true;
  bool get musicEnabled => _musicEnabled;

  void setMusicEnabled(bool value) {
    _musicEnabled = value;
    notifyListeners();
  }

  // Notifications settings
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  // Theme settings
  String _selectedTheme = 'light';
  String get selectedTheme => _selectedTheme;

  void setSelectedTheme(String theme) {
    _selectedTheme = theme;
    notifyListeners();
  }

  // Brightness settings
  String _selectedBrightness = 'auto';
  String get selectedBrightness => _selectedBrightness;

  void setSelectedBrightness(String brightness) {
    _selectedBrightness = brightness;
    notifyListeners();
  }

  // Volume settings
  double _volume = 0.7;
  double get volume => _volume;

  void setVolume(double value) {
    _volume = value;
    notifyListeners();
  }

  // Reset all settings to default
  void resetSettings() {
    _soundEnabled = true;
    _musicEnabled = true;
    _notificationsEnabled = true;
    _selectedTheme = 'light';
    _selectedBrightness = 'auto';
    _volume = 0.7;
    notifyListeners();
  }

  // Save settings (in a real app, this would save to SharedPreferences)
  Future<void> saveSettings() async {
    // TODO: Implement actual saving to SharedPreferences
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  // Load settings (in a real app, this would load from SharedPreferences)
  Future<void> loadSettings() async {
    // TODO: Implement actual loading from SharedPreferences
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
