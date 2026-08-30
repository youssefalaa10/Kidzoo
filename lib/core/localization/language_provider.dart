import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en', '')) {
    _loadLanguage();
  }

  static const String _languageKey = 'selected_language';

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      emit(Locale(languageCode, ''));
    } catch (e) {
      emit(const Locale('en', ''));
    }
  }

  Future<void> setLanguage(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      emit(locale);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> toggleLanguage() async {
    final newLanguage = state.languageCode == 'en' ? 'ar' : 'en';
    await setLanguage(Locale(newLanguage, ''));
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}
