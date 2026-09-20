import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'azure_tts.dart';
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

  /// The utterance [speakAndWait] is currently waiting on, if any.
  static Completer<SpeechOutcome>? _utterance;

  /// Liveness guard for the current utterance. Never the transition signal.
  static Timer? _watchdog;

  /// Bumped whenever an utterance is superseded or stopped, so a late platform
  /// callback belonging to an abandoned utterance cannot resolve a newer one.
  static int _utteranceGeneration = 0;

  static StreamSubscription<void>? _playerCompletion;

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
    _wireCompletion(tts, player);
  }

  /// Attaches the completion callbacks that make [speakAndWait] real.
  ///
  /// These go on **this** facade's engine and player. There is a second
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
  static void _wireCompletion(FlutterTts tts, AudioPlayer player) {
    tts.setCompletionHandler(() => _settle(SpeechOutcome.completed));
    tts.setCancelHandler(() => _settle(SpeechOutcome.cancelled));
    tts.setErrorHandler((dynamic message) {
      debugPrint('Speech: engine error: $message');
      _settle(SpeechOutcome.failed);
    });
    _playerCompletion?.cancel();
    // The cloud route plays a file, so its completion comes from the player.
    _playerCompletion =
        player.onPlayerComplete.listen((_) => _settle(SpeechOutcome.completed));
  }

  @visibleForTesting
  static void reset() {
    _watchdog?.cancel();
    _watchdog = null;
    _playerCompletion?.cancel();
    _playerCompletion = null;
    _utterance = null;
    _utteranceGeneration = 0;
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

    // Network down, quota spent, or a bad key falls through to the device
    // voice inside `_dispatch`. Better a plainer voice than silence in a
    // child's game.
    return _dispatch(text);
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
      _watchdog = Timer(watchdogFor(trimmed), () => _onWatchdogFired(generation));
    }
    return completer.future;
  }

  /// Sends [text] to whichever route is active, cloud first with a device
  /// fallback. Returns whether audio was actually started.
  static Future<bool> _dispatch(String text) async {
    if (_route == SpeechRoute.azure) {
      if (await _speakWithAzure(text)) return true;
      debugPrint('Speech: Azure unavailable, using device voice');
    }
    return _speakWithDevice(text);
  }

  /// Longest a dispatch may take before it is treated as failed.
  ///
  /// Generous because the cloud route synthesises to a file first, and that is
  /// a network round trip before a single sound is made.
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
