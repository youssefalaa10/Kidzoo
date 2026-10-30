import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart';
import 'tts_setup_report.dart';
import 'tts_voice_selection.dart';

/// How an utterance ended.
///
/// The difference between these is the whole point of [Speech.speakAndWait]:
/// a caller that gates a scene transition needs to know the audio has actually
/// stopped, and needs to know it from the engine rather than from a guess.
enum SpeechOutcome {
  /// The engine reported the utterance finished on its own.
  completed,

  /// Superseded, stopped, or the app went away. Audio is silent.
  cancelled,

  /// Nothing was spoken, and nothing was going to be. Returns at once.
  skipped,

  /// Dispatch failed, or no completion event ever arrived and the watchdog
  /// stepped in. Audio has been stopped either way.
  failed,
}

/// Where a given utterance is being spoken from.
enum SpeechRoute {
  /// The device's own text-to-speech engine.
  device,

  /// The device has no installed Arabic voice.
  ///
  /// Arabic is **not** spoken in this state. Handing Arabic script to an
  /// English engine is what produced "a foreign speaker reading broken
  /// Arabic", so staying quiet and prompting for a download is the honest
  /// behaviour.
  needsVoiceData,
}

/// Shared speech lifecycle using installed device voices only.
/// Bundled recordings remain handled by the individual activity audio services.
class Speech {
  const Speech._();

  static FlutterTts? _tts;

  /// The utterance [speakAndWait] is currently waiting on, if any.
  static Completer<SpeechOutcome>? _utterance;

  /// Liveness guard for the current utterance. Never the transition signal.
  static Timer? _watchdog;

  /// Bumped whenever an utterance is superseded or stopped, so a late platform
  /// callback belonging to an abandoned utterance cannot resolve a newer one.
  static int _utteranceGeneration = 0;

  static String _languageCode = 'en';
  static SpeechRoute _route = SpeechRoute.device;

  /// How the last language resolution turned out, for diagnostics.
  static TtsLanguageOutcome? deviceOutcome;

  static SpeechRoute get route => _route;

  /// True when Arabic cannot be spoken until voice data is installed.
  static bool get needsVoiceData => _route == SpeechRoute.needsVoiceData;

  /// Called when a prompt had to be skipped for want of a voice, so the UI can
  /// offer the installer instead of failing silently.
  static void Function()? onVoiceDataMissing;

  /// Wires the facade to the app's shared engine. Call once from `main`.
  static void attach({required FlutterTts tts}) {
    _tts = tts;
    _wireCompletion(tts);
  }

  /// Attaches the completion callbacks that make [speakAndWait] real.
  ///
  /// These go on **this** facade's engine. There is a second
  /// `FlutterTts` inside `TtsService`, and a handler registered through
  /// `TtsService.setCompletionHandler` fires for that other instance - so it
  /// would never see an utterance spoken through here, and the wait would hang
  /// until the watchdog rescued it every single time.
  ///
  /// Deliberately **not** `awaitSpeakCompletion(true)`. That would make
  /// `tts.speak` itself block until the utterance ends, and about twenty legacy
  /// call sites do `await Speech.speak(...)` and then apply their own timing on
  /// top. Turning those awaits from "dispatched" into "finished" would re-time
  /// every one of them. The handlers below give the real completion event
  /// without changing what `speak` means to anyone already calling it.
  static void _wireCompletion(FlutterTts tts) {
    tts.setCompletionHandler(() => _settle(SpeechOutcome.completed));
    tts.setCancelHandler(() => _settle(SpeechOutcome.cancelled));
    tts.setErrorHandler((dynamic message) {
      debugPrint('Speech: engine error: $message');
      _settle(SpeechOutcome.failed);
    });
  }

  @visibleForTesting
  static void reset() {
    _watchdog?.cancel();
    _watchdog = null;
    _utterance = null;
    _utteranceGeneration = 0;
    _tts = null;
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
  }) {
    if (!normalizeLocale(languageCode).startsWith('ar')) {
      return SpeechRoute.device;
    }
    return outcome?.isArabic == true
        ? SpeechRoute.device
        : SpeechRoute.needsVoiceData;
  }

  /// Speaks through the installed device voice without a cloud fallback.
  static Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;

    if (_route == SpeechRoute.needsVoiceData) {
      debugPrint('Speech: skipped - no Arabic voice installed');
      onVoiceDataMissing?.call();
      return false;
    }

    return _dispatch(text);
  }

  static Future<bool> _speakWithDevice(String text) async {
    final tts = _tts;
    if (tts == null || deviceOutcome?.voiceName == null) return false;
    try {
      await tts.speak(text);
      return true;
    } catch (e) {
      debugPrint('Speech: device speak failed: $e');
      return false;
    }
  }

  /// Speaks [text] and resolves only once the audio has actually stopped.
  ///
  /// This is the call anything sequencing a scene must use. [speak] returns on
  /// **dispatch**, which is why the story used to move while the narrator was
  /// still mid-sentence; this one resolves from the engine's own completion
  /// callback, and the character-count estimate survives only as the watchdog
  /// below.
  ///
  /// The guarantee callers rely on: **when this future resolves, nothing is
  /// playing.** Every path honours it, including the failure paths.
  static Future<SpeechOutcome> speakAndWait(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return SpeechOutcome.skipped;

    if (_route == SpeechRoute.needsVoiceData) {
      // Returns immediately rather than waiting out an utterance that was
      // never going to happen. This used to sit silent for the full estimate -
      // up to eight seconds of dead air on a device with no Arabic voice, with
      // the child looking at a button that would not light up.
      debugPrint('Speech: skipped - no Arabic voice installed');
      onVoiceDataMissing?.call();
      return SpeechOutcome.skipped;
    }

    // Anything still in flight is silenced and settled before a new utterance
    // starts, so two lines can never overlap and no stale waiter survives.
    await stop();

    final completer = Completer<SpeechOutcome>();
    _utterance = completer;
    final generation = _utteranceGeneration;

    final dispatched = await _dispatch(trimmed)
        .timeout(dispatchTimeout, onTimeout: () => false);

    if (generation != _utteranceGeneration) {
      // Superseded while dispatching. `stop()` already settled this completer.
      return completer.future;
    }
    if (!dispatched) {
      await _stopEngines();
      _settle(SpeechOutcome.failed);
      return completer.future;
    }
    if (!completer.isCompleted) {
      _watchdog =
          Timer(watchdogFor(trimmed), () => _onWatchdogFired(generation));
    }
    return completer.future;
  }

  /// Dispatches speech only through the selected installed voice.
  static Future<bool> _dispatch(String text) => _speakWithDevice(text);

  /// Longest a dispatch may take before it is treated as failed.
  ///
  /// Bounds platform dispatch so a stalled device engine cannot block play.
  static const Duration dispatchTimeout = Duration(seconds: 15);

  /// How long to wait for a completion event before assuming it is never
  /// coming. Twice the estimate plus a margin: comfortably longer than any
  /// real utterance, so a healthy engine never reaches it.
  static Duration watchdogFor(String text) =>
      estimateFor(text) * 2 + const Duration(seconds: 2);

  /// Roughly how long [text] takes to say. **Only** used to size the watchdog.
  ///
  /// It was previously the completion signal itself, which is what let the
  /// story run ahead of the voice: it is a guess, it is capped, and a capped
  /// guess on a long line expires while the engine is still talking.
  static Duration estimateFor(String text) {
    final estimated = text.length * millisecondsPerCharacter;
    if (estimated < minimumUtterance.inMilliseconds) return minimumUtterance;
    if (estimated > maximumUtterance.inMilliseconds) return maximumUtterance;
    return Duration(milliseconds: estimated);
  }

  static const Duration minimumUtterance = Duration(milliseconds: 700);
  static const Duration maximumUtterance = Duration(seconds: 8);
  static const int millisecondsPerCharacter = 55;

  /// No completion event arrived. Stop the audio, **then** resolve.
  ///
  /// The order is the whole point. Resolving first would release the caller to
  /// start the next scene while the engine may still be speaking - precisely
  /// the overlap this mechanism exists to prevent - so a lost callback would
  /// quietly reintroduce the original bug on exactly the lines most likely to
  /// trigger it.
  static Future<void> _onWatchdogFired(int generation) async {
    if (generation != _utteranceGeneration) return;
    final completer = _utterance;
    if (completer == null || completer.isCompleted) return;
    debugPrint('Speech: no completion event; stopping audio and giving up');
    await _stopEngines();
    _settle(SpeechOutcome.failed);
  }

  /// Resolves the pending utterance, if there is one. Idempotent, because the
  /// platform can deliver a completion and a cancel for the same utterance.
  static void _settle(SpeechOutcome outcome) {
    _watchdog?.cancel();
    _watchdog = null;
    final completer = _utterance;
    _utterance = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome);
    }
  }

  /// True while an utterance started by [speakAndWait] is still in flight.
  static bool get isSpeaking => _utterance != null;

  /// Stops whichever route is currently talking, and settles any waiter.
  ///
  /// Audio is stopped **before** the waiter is released, for the same reason
  /// the watchdog does it in that order.
  static Future<void> stop() async {
    _utteranceGeneration++;
    await _stopEngines();
    _settle(SpeechOutcome.cancelled);
  }

  static Future<void> _stopEngines() async {
    try {
      await _tts?.stop();
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

  /// The most recent device voice survey.
  static TtsSetupReport? get report {
    final base = TtsService.lastReport;
    if (base == null) return null;
    return TtsSetupReport(
      engines: base.engines,
      selectedEngine: base.selectedEngine,
      selectedVoice: base.selectedVoice,
      defaultEngine: base.defaultEngine,
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
