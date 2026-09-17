import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'azure_tts.dart';
import 'tts_service.dart';
import 'tts_setup_report.dart';
import 'tts_voice_selection.dart';

/// Where a given utterance is being spoken from.
enum SpeechRoute {
  /// The device's own text-to-speech engine.
  device,

  /// Azure's neural Egyptian voice.
  azure,

  /// The device has no Arabic voice and no cloud voice is configured.
  ///
  /// Arabic is **not** spoken in this state. Handing Arabic script to an
  /// English engine is what produced "a foreign speaker reading broken
  /// Arabic", so staying quiet and prompting for a download is the honest
  /// behaviour.
  needsVoiceData,
}

/// The single place the app speaks from.
///
/// Everything that used to call `flutterTts.speak(...)` goes through here, so
/// one decision - device voice or cloud voice - applies everywhere instead of
/// being re-made in every game.
///
/// The rule: use the device voice when it can offer a **female Egyptian**
/// voice, and otherwise, if Azure is configured, use `ar-EG-SalmaNeural`. A
/// male or non-Egyptian Arabic voice is exactly the case the device fails at,
/// so it does not count as good enough to keep.
class Speech {
  const Speech._();

  static FlutterTts? _tts;
  static AudioPlayer? _player;
  static AzureTtsClient? _azure;

  static String _languageCode = 'en';
  static SpeechRoute _route = SpeechRoute.device;

  /// How the last language resolution turned out, for diagnostics.
  static TtsLanguageOutcome? deviceOutcome;

  static SpeechRoute get route => _route;

  static bool get isUsingAzure => _route == SpeechRoute.azure;

  /// True when Arabic cannot be spoken until voice data is installed.
  static bool get needsVoiceData => _route == SpeechRoute.needsVoiceData;

  /// Called when a prompt had to be skipped for want of a voice, so the UI can
  /// offer the installer instead of failing silently.
  static void Function()? onVoiceDataMissing;

  /// Wires the facade to the app's shared engine. Call once from `main`.
  static void attach({required FlutterTts tts, required AudioPlayer player}) {
    _tts = tts;
    _player = player;
    if (AzureSpeechConfig.isConfigured) _azure ??= AzureTtsClient();
  }

  @visibleForTesting
  static void reset() {
    _tts = null;
    _player = null;
    _azure = null;
    _route = SpeechRoute.device;
    deviceOutcome = null;
    _languageCode = 'en';
  }

  /// Chooses the voice for [languageCode] and decides the route.
  static Future<SpeechRoute> configureLanguage(String languageCode) async {
    _languageCode = languageCode;
    final tts = _tts;

    if (tts != null) {
      deviceOutcome = await TtsService.applyLanguageTo(tts, languageCode);
    }

    _route = decideRoute(
      languageCode: languageCode,
      outcome: deviceOutcome,
      azureConfigured: AzureSpeechConfig.isConfigured,
      forceAzure: AzureSpeechConfig.force,
    );

    debugPrint('Speech: language=$languageCode route=${_route.name} '
        'device=${deviceOutcome?.describe() ?? "n/a"}');
    return _route;
  }

  /// The routing rule, isolated so it can be tested without a device.
  @visibleForTesting
  static SpeechRoute decideRoute({
    required String languageCode,
    required TtsLanguageOutcome? outcome,
    required bool azureConfigured,
    required bool forceAzure,
  }) {
    // English keeps using the device voice, which is good and free.
    final wantsArabic = normalizeLocale(languageCode).startsWith('ar');
    if (!wantsArabic) return SpeechRoute.device;

    if (azureConfigured && forceAzure) return SpeechRoute.azure;

    // The device voice is kept only when it is genuinely what we asked for.
    final ideal = outcome != null && outcome.isEgyptian && outcome.isFemale;
    if (ideal) return SpeechRoute.device;

    // Anything less than ideal goes to the cloud when we can.
    if (azureConfigured) return SpeechRoute.azure;

    // No cloud voice. A different *Arabic* voice is an acceptable stand-in -
    // it is still Arabic. A non-Arabic voice is not: it would read the script
    // phonetically in a foreign accent, which is the bug being fixed.
    if (outcome != null && outcome.isArabic) return SpeechRoute.device;

    return SpeechRoute.needsVoiceData;
  }

  /// Speaks [text], falling back to the device voice if the cloud call fails.
  ///
  /// Returns whether audio was actually dispatched, which callers use to
  /// decide whether to wait before moving on. The old code inspected
  /// flutter_tts's Android "1" return code for this, which says nothing once
  /// the cloud route may have answered instead.
  static Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;

    if (_route == SpeechRoute.needsVoiceData) {
      debugPrint('Speech: skipped - no Arabic voice installed');
      onVoiceDataMissing?.call();
      return false;
    }

    if (_route == SpeechRoute.azure) {
      if (await _speakWithAzure(text)) return true;
      // Network down, quota spent, or a bad key. Better a plainer voice than
      // silence in a child's game.
      debugPrint('Speech: Azure unavailable, using device voice');
    }

    return _speakWithDevice(text);
  }

  static Future<bool> _speakWithAzure(String text) async {
    final azure = _azure;
    final player = _player;
    if (azure == null || player == null) return false;

    try {
      final file = await azure.synthesizeToFile(text);
      if (file == null) return false;
      await player.stop();
      await player.play(DeviceFileSource(file.path));
      return true;
    } catch (e) {
      debugPrint('Speech: Azure playback failed: $e');
      return false;
    }
  }

  static Future<bool> _speakWithDevice(String text) async {
    final tts = _tts;
    if (tts == null) return false;
    try {
      await tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('Speech: device speak failed: $e');
      return false;
    }
  }

  /// Stops whichever route is currently talking.
  static Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    try {
      await _player?.stop();
    } catch (_) {}
  }

  /// Re-runs voice resolution, e.g. after the user installs voice data.
  static Future<SpeechRoute> refresh() async {
    TtsService.invalidateVoiceCache();
    return configureLanguage(_languageCode);
  }

  /// The current language, for callers that need to re-resolve.
  static String get languageCode => _languageCode;

  /// Speaks a short Arabic sample so the user can hear the selected voice.
  static Future<bool> speakSample() =>
      speak('أهلاً! أنا هنا عشان نلعب ونتعلم مع بعض.');

  /// Surveys what Arabic the device can do, whatever language is in use.
  ///
  /// Needed even in the English UI so the first-launch prompt can offer the
  /// installer before the child ever switches to Arabic. The result is cached,
  /// so this is cheap after the first call.
  static Future<TtsSetupReport?> surveyArabic() async {
    final tts = _tts;
    if (tts == null) return null;
    await TtsService.applyLanguageTo(tts, 'ar');
    final report = TtsService.lastReport;
    // Put the engine back on whatever the app is actually speaking.
    await configureLanguage(_languageCode);
    return report;
  }

  /// The most recent survey, including the cloud decision.
  static TtsSetupReport? get report {
    final base = TtsService.lastReport;
    if (base == null) return null;
    return TtsSetupReport(
      engines: base.engines,
      selectedEngine: base.selectedEngine,
      selectedVoice: base.selectedVoice,
      defaultEngine: base.defaultEngine,
      usingCloudVoice: _route == SpeechRoute.azure,
      cloudVoiceName:
          _route == SpeechRoute.azure ? AzureSpeechConfig.voice : null,
    );
  }

  /// Dumps everything discovered, for reading in `flutter run` output.
  static void logDiagnostics() {
    final r = report;
    debugPrint('===== TTS DIAGNOSTICS =====');
    debugPrint('language     : $_languageCode');
    debugPrint('route        : ${_route.name}');
    if (r == null) {
      debugPrint('report       : (not surveyed yet)');
      debugPrint('===========================');
      return;
    }
    debugPrint('system default engine: ${r.defaultEngine ?? "unknown"}');
    debugPrint('selected engine      : ${r.selectedEngine?.engine ?? "none"}');
    debugPrint('selected voice       : '
        '${r.selectedVoice?.name ?? "none"} (${r.selectedVoice?.locale ?? "-"})');
    debugPrint('egyptian installed   : ${r.hasEgyptian}');
    debugPrint('egyptian female      : ${r.hasEgyptianFemale}');
    debugPrint('quality              : ${r.quality.name}');
    for (final engine in r.engines) {
      debugPrint('  engine ${engine.engine} -> ${engine.arabicVoices.length} '
          'arabic voice(s)');
      for (final v in engine.arabicVoices) {
        debugPrint('    - ${v.name} | ${v.locale} | '
            '${v.inferredGender.name} | egyptian=${v.isEgyptian} | '
            'q=${v.quality} | net=${v.networkRequired}');
      }
    }
    debugPrint('===========================');
  }
}
