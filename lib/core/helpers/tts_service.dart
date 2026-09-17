import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localizations.dart';

import 'speech.dart';
import 'tts_setup_report.dart';
import 'tts_voice_selection.dart';

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
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.38); // Slightly slower for kids
      await _tts.setVolume(1.0);

      await _applyLanguage(_currentLanguage);
    } catch (e) {
      debugPrint('TTS Setup Error: $e');
    }
  }

  Future<bool> _applyLanguage(String languageCode) async {
    final outcome = await applyLanguageTo(_tts, languageCode);
    return outcome.isArabic || !_isArabicCode(languageCode);
  }

  static bool _isArabicCode(String code) =>
      normalizeLocale(code).startsWith('ar');

  /// What actually happened when we asked for a language.
  ///
  /// Callers may ignore it; it exists so the install prompt can tell the
  /// difference between "no Egyptian voice, using another Arabic one" and
  /// "no Arabic voice at all".
  static TtsLanguageOutcome? lastArabicOutcome;

  /// Cached per process: the voice list does not change while the app runs,
  /// and `getVoices` is a real platform round trip we do not want on the path
  /// of every prompt.
  static TtsLanguageOutcome? _cachedArabicOutcome;

  /// Drops the cached Arabic result, so the next request re-checks the device.
  /// Call after the user has been sent to install voice data.
  static void invalidateVoiceCache() {
    _cachedArabicOutcome = null;
  }

  /// Points [tts] at the best available voice for [languageCode].
  ///
  /// For Arabic this now targets **Egyptian Arabic first**. The previous
  /// version walked a hard-coded list starting at `ar-SA` and called
  /// `setLanguage` only, which meant that even on a device with an Egyptian
  /// voice installed the app spoke with a Saudi one. It now enumerates the
  /// installed voices, scores them (see `tts_voice_selection.dart`) and pins
  /// the winner with `setVoice`, falling back to `setLanguage` when the engine
  /// reports no voices.
  ///
  /// Fallback order: `ar-EG` voice -> any Egyptian-tagged voice -> best other
  /// Arabic voice -> `ar-EG`/Arabic via `setLanguage` -> English.
  static Future<TtsLanguageOutcome> applyLanguageTo(
      FlutterTts tts, String languageCode) async {
    if (!_isArabicCode(languageCode)) {
      await _trySetLanguage(tts, 'en-US');
      return const TtsLanguageOutcome(
        locale: 'en-US',
        isArabic: false,
        isEgyptian: false,
      );
    }

    final cached = _cachedArabicOutcome;
    if (cached != null) {
      await _applyOutcome(tts, cached);
      lastArabicOutcome = cached;
      return cached;
    }

    final outcome = await _resolveArabic(tts);
    _cachedArabicOutcome = outcome;
    lastArabicOutcome = outcome;
    return outcome;
  }

  /// The last full survey of the device, for Settings and for logging.
  static TtsSetupReport? lastReport;

  /// Serialises Arabic resolution.
  ///
  /// flutter_tts crashes the app with `IllegalStateException: Reply already
  /// submitted` if two engine/init calls overlap, and at startup the language
  /// listener, the initial configure and the Settings screen can all ask at
  /// once. Everyone waits on the same future instead.
  static Future<TtsLanguageOutcome>? _inFlight;

  /// Engine currently loaded, tracked so we never call `setEngine` needlessly.
  static String? _activeEngine;

  static Future<TtsLanguageOutcome> _resolveArabic(FlutterTts tts) {
    return _inFlight ??= _resolveArabicOnce(tts).whenComplete(() {
      _inFlight = null;
    });
  }

  /// Chooses the engine and voice for Arabic.
  ///
  /// The device this was debugged on defaulted to `com.samsung.SMT` pinned to
  /// `en_US`, so Arabic script was being sounded out by an English voice -
  /// the "foreign speaker reading broken Arabic" report. Google's engine was
  /// installed all along, with its Arabic data present, and was never picked.
  ///
  /// The engine is switched **at most once**: an earlier version surveyed every
  /// engine in turn and the repeated `setEngine` calls crashed the app, because
  /// flutter_tts replies to its init callback twice.
  static Future<TtsLanguageOutcome> _resolveArabicOnce(FlutterTts tts) async {
    // Let the plugin finish its own initialisation first; calling in too early
    // produces "not bound to TTS engine" and a null default voice.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    String? defaultEngine;
    var engines = const <String>[];
    if (Platform.isAndroid) {
      try {
        defaultEngine = (await tts.getDefaultEngine)?.toString();
        _activeEngine ??= defaultEngine;
      } catch (_) {}
      engines = await _listEngines(tts);
    }

    final reports = <TtsEngineReport>[];

    // 1. What can the engine we are already on do?
    final current = await _surveyCurrentEngine(tts, _activeEngine ?? '');
    if (current != null) reports.add(current);

    // 2. If that is not a female Egyptian voice, try Google's engine - once.
    const google = 'com.google.android.tts';
    if (Platform.isAndroid &&
        !(current?.hasEgyptianFemale ?? false) &&
        engines.contains(google) &&
        _activeEngine != google) {
      if (await _trySetEngine(tts, google)) {
        final googleReport = await _surveyCurrentEngine(tts, google);
        if (googleReport != null) reports.add(googleReport);
      }
    }

    TtsEngineReport? winner;
    for (final report in reports) {
      if (report.best == null) continue;
      if (winner == null || report.bestScore > winner.bestScore) {
        winner = report;
      }
    }

    lastReport = TtsSetupReport(
      engines: reports,
      selectedEngine: winner,
      selectedVoice: winner?.best,
      defaultEngine: defaultEngine,
    );

    final best = winner?.best;
    if (winner != null && best != null) {
      // Switch back only if the winner is not what is loaded right now.
      if (Platform.isAndroid &&
          winner.engine.isNotEmpty &&
          _activeEngine != winner.engine) {
        await _trySetEngine(tts, winner.engine);
      }
      final outcome = TtsLanguageOutcome(
        locale: best.locale,
        voiceName: best.name,
        isArabic: true,
        isEgyptian: best.isEgyptian,
        gender: best.inferredGender,
        engine: winner.engine,
      );
      if (await _applyOutcome(tts, outcome)) {
        debugPrint('TTS: engine=${winner.engine} voice=${outcome.describe()}');
        return outcome;
      }
    }

    // 3. No voice list at all: fall back to locale-only selection.
    List<String> attempts;
    try {
      final languages = await tts.getLanguages;
      attempts = arabicLocaleAttempts(
        languages is List
            ? languages.map((l) => l.toString())
            : const <String>[],
      );
    } catch (_) {
      attempts = arabicLocaleAttempts(const <String>[]);
    }

    for (final locale in attempts) {
      if (await _trySetLanguage(tts, locale)) {
        debugPrint('TTS: Arabic set by locale $locale (no voice list)');
        return TtsLanguageOutcome(
          locale: locale,
          isArabic: true,
          isEgyptian: normalizeLocale(locale).contains('-eg'),
          engine: _activeEngine,
        );
      }
    }

    // 4. Nothing Arabic here. Deliberately NOT falling back to an English
    // voice: making an English engine sound out Arabic script is the exact
    // failure being fixed. The caller prompts for a download, and Speech
    // routes to the cloud voice when one is configured.
    debugPrint('TTS: no Arabic voice on this device');
    return const TtsLanguageOutcome(
      locale: 'ar-EG',
      isArabic: false,
      isEgyptian: false,
    );
  }

  static Future<List<String>> _listEngines(FlutterTts tts) async {
    try {
      final engines = await tts.getEngines;
      if (engines is List) {
        return engines
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('TTS: getEngines failed: $e');
    }
    return const [];
  }

  /// Reports the Arabic voices the currently loaded engine exposes.
  static Future<TtsEngineReport?> _surveyCurrentEngine(
      FlutterTts tts, String engine) async {
    try {
      final voices =
          parseVoices(await tts.getVoices).where((v) => v.isArabic).toList();
      final best = selectBestArabicVoice(voices);
      return TtsEngineReport(
        engine: engine,
        arabicVoices: voices,
        best: best,
        bestScore: best == null ? 0 : scoreArabicVoice(best),
      );
    } catch (e) {
      debugPrint('TTS: survey of $engine failed: $e');
      return null;
    }
  }

  static Future<bool> _trySetEngine(FlutterTts tts, String engine) async {
    try {
      await tts.setEngine(engine);
      _activeEngine = engine;
      // Switching engines is asynchronous on the platform side; without a
      // breath here the next getVoices can still answer for the old engine.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return true;
    } catch (e) {
      debugPrint('TTS: setEngine($engine) failed: $e');
      return false;
    }
  }

  /// Applies an outcome to an engine, pinning the voice when we have one.
  static Future<bool> _applyOutcome(
      FlutterTts tts, TtsLanguageOutcome outcome) async {
    final localeOk = await _trySetLanguage(tts, outcome.locale);
    final name = outcome.voiceName;
    if (name == null || name.isEmpty) return localeOk;

    try {
      // setVoice wants both keys; the locale must be the voice's own.
      await tts.setVoice({'name': name, 'locale': outcome.locale});
      return true;
    } catch (e) {
      debugPrint('TTS: setVoice failed for $name: $e');
      return localeOk;
    }
  }

  static Future<bool> _trySetLanguage(FlutterTts tts, String locale) async {
    try {
      final result = await tts.setLanguage(locale);
      // Android returns 1 for success and a negative code for
      // LANG_MISSING_DATA / LANG_NOT_SUPPORTED; iOS returns null.
      if (result == null) return true;
      if (result is num) return result >= 0;
      return true;
    } catch (e) {
      debugPrint('TTS: setLanguage($locale) failed: $e');
      return false;
    }
  }

  /// Speak the given text in the current language.
  ///
  /// Delegates to [Speech] so this older entry point takes the same
  /// device-or-cloud route as everything else in the app.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await Speech.speak(text);
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

  /// Offers the system voice installer when the device has no Arabic voice.
  ///
  /// Shown once, on first launch. It only appears when the survey found no
  /// Arabic voice on any engine - the case where Arabic would otherwise be
  /// read aloud by a foreign voice.
  ///
  /// Returns true when Arabic can already be spoken.
  static Future<bool> checkAndRequestArabicVoice(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('hasRequestedArabicVoice') == true) return true;

    final report = await Speech.surveyArabic();
    if (report == null || report.hasAnyArabic) return true;
    if (Speech.isUsingAzure) return true;

    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context);

    final go = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.record_voice_over_rounded,
                color: Color(0xFF6C63FF), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.ttsFirstRunTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(l10n.ttsFirstRunBody, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.ttsNotNow,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ttsOpenSettings),
          ),
        ],
      ),
    );

    // Only remember the "asked" flag once they have actually answered, so a
    // dismissed-by-accident dialog is not lost forever.
    await prefs.setBool('hasRequestedArabicVoice', true);

    if (go == true) {
      await openVoiceDataSettings();
      // They may have installed something while away.
      invalidateVoiceCache();
      await Speech.refresh();
    }
    return false;
  }

  static const MethodChannel _channel =
      MethodChannel('dev.annotex.kidzo/tts_settings');

  /// Opens Android's text-to-speech voice-data installer.
  ///
  /// Backed by a small MethodChannel because there is no plugin API for it.
  static Future<void> openVoiceDataSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openTtsSettings');
    } catch (e) {
      debugPrint('TTS: could not open voice settings: $e');
    }
  }
}

/// The result of pointing an engine at a language.
class TtsLanguageOutcome {
  const TtsLanguageOutcome({
    required this.locale,
    required this.isArabic,
    required this.isEgyptian,
    this.voiceName,
    this.gender = TtsVoiceGender.unknown,
    this.engine,
  });

  final String locale;
  final String? voiceName;
  final bool isArabic;

  /// True only when the chosen voice is genuinely Egyptian, not merely Arabic.
  final bool isEgyptian;

  /// Gender of the chosen voice, where it could be determined.
  final TtsVoiceGender gender;

  /// The engine that owns the chosen voice (Android package name).
  final String? engine;

  bool get isFemale => gender == TtsVoiceGender.female;

  /// The bar the app actually wants: a female Egyptian narrator.
  bool get isEgyptianFemale => isEgyptian && isFemale;

  String describe() {
    final tag = isEgyptianFemale
        ? '[ar-EG female]'
        : isEgyptian
            ? '[ar-EG ${gender.name}]'
            : isArabic
                ? '[ar fallback ${gender.name}]'
                : '[non-Arabic]';
    return '${voiceName ?? "(locale only)"} @ $locale $tag';
  }
}
