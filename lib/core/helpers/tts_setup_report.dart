import 'tts_voice_selection.dart';

/// What one text-to-speech engine can offer for Arabic.
class TtsEngineReport {
  const TtsEngineReport({
    required this.engine,
    required this.arabicVoices,
    this.best,
    this.bestScore = 0,
  });

  /// Package name on Android, e.g. `com.google.android.tts`.
  final String engine;

  final List<TtsVoiceCandidate> arabicVoices;

  /// Best Arabic voice this engine offers, if any.
  final TtsVoiceCandidate? best;
  final int bestScore;

  bool get hasArabic => arabicVoices.isNotEmpty;

  bool get hasEgyptian => arabicVoices.any((v) => v.isEgyptian);

  bool get hasEgyptianFemale =>
      arabicVoices.any((v) => v.isEgyptian && v.isFemale);

  /// Friendly name for the settings screen.
  String get displayName => switch (engine) {
        'com.google.android.tts' => 'Google Speech Services',
        'com.samsung.SMT' => 'Samsung Text-to-Speech',
        'com.amazon.tts' => 'Amazon TTS',
        'espeak' || 'com.reecedunn.espeak' => 'eSpeak',
        _ => engine,
      };
}

/// The whole picture: which engines exist, which one we chose, and what it
/// gives us. Rendered by Settings and logged at startup.
class TtsSetupReport {
  const TtsSetupReport({
    required this.engines,
    required this.selectedEngine,
    required this.selectedVoice,
    this.defaultEngine,
    this.usingCloudVoice = false,
    this.cloudVoiceName,
  });

  const TtsSetupReport.unavailable()
      : engines = const [],
        selectedEngine = null,
        selectedVoice = null,
        defaultEngine = null,
        usingCloudVoice = false,
        cloudVoiceName = null;

  /// Every engine on the device, with what Arabic each can do.
  final List<TtsEngineReport> engines;

  /// The engine we settled on.
  final TtsEngineReport? selectedEngine;

  /// The voice we settled on.
  final TtsVoiceCandidate? selectedVoice;

  /// The engine the *system* defaults to, which is not necessarily ours.
  final String? defaultEngine;

  final bool usingCloudVoice;
  final String? cloudVoiceName;

  bool get hasAnyArabic => engines.any((e) => e.hasArabic);

  bool get hasEgyptian => engines.any((e) => e.hasEgyptian);

  bool get hasEgyptianFemale => engines.any((e) => e.hasEgyptianFemale);

  /// True when the selected voice is the one the app actually wants.
  bool get isIdeal =>
      usingCloudVoice ||
      (selectedVoice != null &&
          selectedVoice!.isEgyptian &&
          selectedVoice!.isFemale);

  /// True when Arabic will be spoken by something that is not an Arabic voice.
  ///
  /// This is the state that produced "a foreign speaker reading broken
  /// Arabic": a Samsung engine pinned to `en_US` reading Arabic script.
  bool get willSoundForeign =>
      !usingCloudVoice && (selectedVoice == null || !selectedVoice!.isArabic);

  /// Whether we should ask the user to install voice data.
  bool get needsVoiceDownload => !usingCloudVoice && !hasAnyArabic;

  /// Short status line for the settings screen.
  TtsSetupQuality get quality {
    if (usingCloudVoice) return TtsSetupQuality.cloud;
    if (willSoundForeign) return TtsSetupQuality.missing;
    if (selectedVoice == null) return TtsSetupQuality.missing;
    if (selectedVoice!.isEgyptian && selectedVoice!.isFemale) {
      return TtsSetupQuality.ideal;
    }
    if (selectedVoice!.isEgyptian) return TtsSetupQuality.egyptianWrongGender;
    return TtsSetupQuality.arabicNotEgyptian;
  }
}

enum TtsSetupQuality {
  /// A female Egyptian voice: what we want.
  ideal,

  /// Egyptian, but not female.
  egyptianWrongGender,

  /// Arabic, but from another country.
  arabicNotEgyptian,

  /// No Arabic voice at all - Arabic would be read by a foreign voice.
  missing,

  /// Speaking through the cloud neural voice.
  cloud,
}
