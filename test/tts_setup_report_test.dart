import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/helpers/tts_setup_report.dart';
import 'package:kidzo/core/helpers/tts_voice_selection.dart';

TtsVoiceCandidate voice(String name, {String locale = 'ar'}) =>
    TtsVoiceCandidate(name: name, locale: locale);

TtsEngineReport engine(String name, List<TtsVoiceCandidate> voices) {
  final best = selectBestArabicVoice(voices);
  return TtsEngineReport(
    engine: name,
    arabicVoices: voices,
    best: best,
    bestScore: best == null ? 0 : scoreArabicVoice(best),
  );
}

void main() {
  // These mirror what the Samsung A52s (Android 14) actually reported:
  // com.samsung.SMT exposed no Arabic voices at all, while Google's engine
  // exposed nine, including the Egyptian female ar-xa-x-arz-local.
  final samsung = engine('com.samsung.SMT', const []);
  final google = engine('com.google.android.tts', [
    voice('ar-xa-x-arz-local'),
    voice('ar-xa-x-ard-local'),
    voice('ar-xa-x-arc-local'),
    voice('ar-xa-x-are-local'),
    voice('ar-language'),
  ]);

  group('Engine reports', () {
    test('an engine with no Arabic voices is recognised as such', () {
      expect(samsung.hasArabic, isFalse);
      expect(samsung.hasEgyptian, isFalse);
      expect(samsung.best, isNull);
      expect(samsung.bestScore, 0);
    });

    test('Google engine offers an Egyptian female voice', () {
      expect(google.hasArabic, isTrue);
      expect(google.hasEgyptian, isTrue);
      expect(google.hasEgyptianFemale, isTrue);
      expect(google.best?.name, 'ar-xa-x-arz-local');
    });

    test('engines get readable names for the settings screen', () {
      expect(samsung.displayName, 'Samsung Text-to-Speech');
      expect(google.displayName, 'Google Speech Services');
      expect(engine('com.acme.tts', const []).displayName, 'com.acme.tts');
    });
  });

  group('The device that reported the bug', () {
    final report = TtsSetupReport(
      engines: [samsung, google],
      selectedEngine: google,
      selectedVoice: google.best,
      defaultEngine: 'com.samsung.SMT',
    );

    test('picks Google even though the system default is Samsung', () {
      expect(report.defaultEngine, 'com.samsung.SMT');
      expect(report.selectedEngine?.engine, 'com.google.android.tts');
    });

    test('reports the ideal state once the right voice is selected', () {
      expect(report.hasEgyptianFemale, isTrue);
      expect(report.isIdeal, isTrue);
      expect(report.quality, TtsSetupQuality.ideal);
      expect(report.willSoundForeign, isFalse);
      expect(report.needsVoiceDownload, isFalse);
    });
  });

  group('Degraded states are named honestly', () {
    test('no Arabic anywhere means it would sound foreign', () {
      const report = TtsSetupReport(
        engines: [],
        selectedEngine: null,
        selectedVoice: null,
      );
      expect(report.hasAnyArabic, isFalse);
      expect(report.willSoundForeign, isTrue);
      expect(report.needsVoiceDownload, isTrue);
      expect(report.quality, TtsSetupQuality.missing);
      expect(report.isIdeal, isFalse);
    });

    test('a selected English voice counts as sounding foreign', () {
      // The original bug: Samsung on en_US reading Arabic script.
      final report = TtsSetupReport(
        engines: [samsung],
        selectedEngine: samsung,
        selectedVoice: voice('en-us-x-sfg-local', locale: 'en-US'),
      );
      expect(report.willSoundForeign, isTrue);
      expect(report.quality, TtsSetupQuality.missing);
    });

    test('an Egyptian male voice is flagged, not passed off as ideal', () {
      final onlyMale = engine('com.google.android.tts', [
        voice('ar-eg-x-ard-local', locale: 'ar-EG'),
      ]);
      final report = TtsSetupReport(
        engines: [onlyMale],
        selectedEngine: onlyMale,
        selectedVoice: onlyMale.best,
      );
      expect(report.quality, TtsSetupQuality.egyptianWrongGender);
      expect(report.isIdeal, isFalse);
      expect(report.willSoundForeign, isFalse);
      // Arabic exists, so there is nothing to download.
      expect(report.needsVoiceDownload, isFalse);
    });

    test('a non-Egyptian Arabic voice is flagged as such', () {
      final saudi = engine('com.google.android.tts', [
        voice('ar-xa-x-arc-local', locale: 'ar-SA'),
      ]);
      final report = TtsSetupReport(
        engines: [saudi],
        selectedEngine: saudi,
        selectedVoice: saudi.best,
      );
      expect(report.quality, TtsSetupQuality.arabicNotEgyptian);
      expect(report.isIdeal, isFalse);
    });

    test('the cloud voice counts as ideal whatever the device has', () {
      final report = TtsSetupReport(
        engines: [samsung],
        selectedEngine: samsung,
        selectedVoice: null,
        usingCloudVoice: true,
        cloudVoiceName: 'ar-EG-SalmaNeural',
      );
      expect(report.quality, TtsSetupQuality.cloud);
      expect(report.isIdeal, isTrue);
      expect(report.willSoundForeign, isFalse);
      // Nothing to install when the cloud is answering.
      expect(report.needsVoiceDownload, isFalse);
    });

    test('an unavailable report degrades safely', () {
      const report = TtsSetupReport.unavailable();
      expect(report.engines, isEmpty);
      expect(report.quality, TtsSetupQuality.missing);
      expect(report.needsVoiceDownload, isTrue);
    });
  });
}
