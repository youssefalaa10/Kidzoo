import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A robust TTS service that handles Arabic voice data installation.
/// It is a singleton so it can be shared across the app.
class TtsService {
  factory TtsService() => _instance;
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  String _currentLanguage = 'en';
  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;

  Future<void> init({String languageCode = 'en'}) async {
    if (_isInitialized && _currentLanguage == languageCode) return;
    if (_isInitializing) return;

    _isInitializing = true;
    _currentLanguage = languageCode;
    await _setupEngine();
    _isInitialized = true;
    _isInitializing = false;
  }

  Future<void> _setupEngine() async {
    try {
      if (Platform.isAndroid) {
        await _tts.setEngine('com.google.android.tts'); // Force Google TTS
      }
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.38); // Slightly slower for kids
      await _tts.setVolume(1.0);

      // Set language based on code
      await _applyLanguage(_currentLanguage);
    } catch (e) {
      debugPrint('TTS Setup Error: $e');
    }
  }

  Future<bool> _applyLanguage(String languageCode) async {
    if (languageCode.toLowerCase() == 'ar') {
      // Try different Arabic locales in order of preference
      final arabicLocales = ['ar-SA', 'ar-EG', 'ar-AE', 'ar'];
      for (final locale in arabicLocales) {
        try {
          final result = await _tts.setLanguage(locale);
          // On Android, setLanguage returns 1 on success
          if (result == 1 || result == null) {
            debugPrint('TTS: Arabic language set to $locale successfully');
            return true;
          }
        } catch (e) {
          debugPrint('TTS: Failed to set language $locale: $e');
        }
      }
      debugPrint('TTS: Could not set any Arabic locale, falling back to en-US');
      await _tts.setLanguage('en-US');
      return false;
    } else {
      await _tts.setLanguage('en-US');
      return true;
    }
  }

  /// Speak the given text in the current language.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Set the language code and re-initialize the engine.
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _applyLanguage(languageCode);
  }

  void setCompletionHandler(VoidCallback handler) {
    _tts.setCompletionHandler(handler);
  }

  void setErrorHandler(void Function(dynamic) handler) {
    _tts.setErrorHandler(handler);
  }

  static Future<bool> checkAndRequestArabicVoice(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('hasRequestedArabicVoice') == true) return true;

    final tts = _instance._tts;
    // Don't call setEngine here if we are already initializing or initialized
    if (!_instance._isInitialized && !_instance._isInitializing) {
      await tts.setEngine('com.google.android.tts');
    }

    try {
      final languages = await tts.getLanguages as List?;
      if (languages != null) {
        final hasArabic = languages.any((lang) {
          final l = lang.toString().toLowerCase();
          return l.startsWith('ar');
        });

        if (hasArabic) {
          debugPrint('TTS: Arabic language data is available on device');
          return true;
        }
      }
    } catch (e) {
      debugPrint('TTS: Error checking languages: $e');
    }

    // Arabic is NOT installed — show a dialog asking the user to install it
    if (context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.record_voice_over, color: Color(0xFF6C63FF), size: 28),
              SizedBox(width: 10),
              Text(
                'تثبيت الصوت العربي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'لتشغيل النطق العربي بشكل صحيح، سيتم تحويلك الآن إلى شاشة تنزيل حزم الصوت.\n\n'
            'يُرجى اختيار اللغة العربية والضغط على تثبيت.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              height: 1.6,
            ),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasRequestedArabicVoice', true);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'لاحقاً',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasRequestedArabicVoice', true);
                if (ctx.mounted) Navigator.pop(ctx);
                // Open TTS settings on Android
                _openTtsSettings(_instance._tts);
              },
              child: const Text(
                'موافقة وتنزيل',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return false;
  }

  static const MethodChannel _channel =
      MethodChannel('dev.annotex.kidzo/tts_settings');

  static Future<void> _openTtsSettings(FlutterTts tts) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openTtsSettings');
      } else {
        await tts.setLanguage('ar-SA');
      }
    } catch (e) {
      debugPrint('TTS install request error: $e');
    }
  }
}
