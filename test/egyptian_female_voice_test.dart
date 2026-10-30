import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/helpers/speech.dart';
import 'package:kidzo/core/helpers/tts_service.dart';
import 'package:kidzo/core/helpers/tts_voice_selection.dart';

Map<Object?, Object?> android(String name, String locale,
        {int quality = 300, bool network = false}) =>
    {
      'name': name,
      'locale': locale,
      'quality': quality,
      'network_required': network,
    };

Map<Object?, Object?> ios(String name, String locale, String gender,
        {int quality = 0}) =>
    {'name': name, 'locale': locale, 'gender': gender, 'quality': quality};

TtsLanguageOutcome outcome({
  required bool isEgyptian,
  required TtsVoiceGender gender,
  bool isArabic = true,
}) =>
    TtsLanguageOutcome(
      locale: isEgyptian ? 'ar-EG' : 'ar-SA',
      voiceName: 'test',
      isArabic: isArabic,
      isEgyptian: isEgyptian,
      gender: gender,
    );

void main() {
  group('Gender detection', () {
    test('trusts the gender the platform reports', () {
      expect(
        TtsVoiceCandidate.fromMap(ios('Salma', 'ar-EG', 'female')).isFemale,
        isTrue,
      );
      expect(
        TtsVoiceCandidate.fromMap(ios('Maged', 'ar-SA', 'male')).isMale,
        isTrue,
      );
    });

    test('does not read "female" as "male"', () {
      // "female" contains "male", so a naive substring check gets this wrong.
      final voice = TtsVoiceCandidate.fromMap(ios('X', 'ar-EG', 'Female'));
      expect(voice.inferredGender, TtsVoiceGender.female);
    });

    test('reads Google variant subtags when Android reports no gender', () {
      // Android's Voice API exposes no gender at all; the variant subtag is
      // the only signal available.
      expect(
        TtsVoiceCandidate.fromMap(android('ar-xa-x-arz-local', 'ar-XA'))
            .isFemale,
        isTrue,
      );
      expect(
        TtsVoiceCandidate.fromMap(android('ar-xa-x-arc-local', 'ar-XA'))
            .isFemale,
        isTrue,
      );
      expect(
        TtsVoiceCandidate.fromMap(android('ar-xa-x-ard-local', 'ar-XA')).isMale,
        isTrue,
      );
      expect(
        TtsVoiceCandidate.fromMap(android('ar-xa-x-are-local', 'ar-XA')).isMale,
        isTrue,
      );
    });

    test('says unknown rather than guessing', () {
      final voice = TtsVoiceCandidate.fromMap(android('ar-sa-local', 'ar-SA'));
      expect(voice.inferredGender, TtsVoiceGender.unknown);
    });

    test('arz is both Egyptian and female, which is the voice we want', () {
      final voice =
          TtsVoiceCandidate.fromMap(android('ar-xa-x-arz-local', 'ar-XA'));
      expect(voice.isEgyptian, isTrue);
      expect(voice.isFemale, isTrue);
      expect(isGoodEgyptianFemaleVoice(voice), isTrue);
    });
  });

  group('Preferring a female Egyptian voice', () {
    test('picks the Egyptian female over an Egyptian male', () {
      final voices = parseVoices([
        android('ar-eg-x-ard-local', 'ar-EG'),
        android('ar-eg-x-arz-local', 'ar-EG'),
      ]);
      expect(selectBestArabicVoice(voices)?.name, 'ar-eg-x-arz-local');
    });

    test('still prefers an Egyptian male over a non-Egyptian female', () {
      // Accent is what a child actually learns from, so region outranks gender.
      final voices = parseVoices([
        android('ar-eg-x-ard-local', 'ar-EG'),
        android('ar-sa-x-arc-local', 'ar-SA'),
      ]);
      final best = selectBestArabicVoice(voices);
      expect(best?.isEgyptian, isTrue);
      expect(best?.isMale, isTrue);
    });

    test('prefers a female voice among equally non-Egyptian ones', () {
      final voices = parseVoices([
        android('ar-xa-x-ard-local', 'ar-SA'),
        android('ar-xa-x-arc-local', 'ar-SA'),
      ]);
      expect(selectBestArabicVoice(voices)?.isFemale, isTrue);
    });

    test('still speaks when every Arabic voice is male', () {
      final voices = parseVoices([android('ar-xa-x-ard-local', 'ar-SA')]);
      final best = selectBestArabicVoice(voices);
      expect(best, isNotNull);
      expect(isGoodEgyptianFemaleVoice(best), isFalse);
    });

    test('preferFemale can be turned off', () {
      final voices = parseVoices([
        android('ar-eg-x-ard-local', 'ar-EG', quality: 500),
        android('ar-eg-x-arz-local', 'ar-EG', quality: 100),
      ]);
      // With gender out of the picture, quality decides.
      expect(
        selectBestArabicVoice(voices, preferFemale: false)?.name,
        'ar-eg-x-ard-local',
      );
    });

    test('iOS has no female Egyptian voice, so the bar is not met there', () {
      // iOS ships only Maged (ar-SA, male). This is the case that makes the
      // a different installed Arabic accent may be needed on that platform.
      final voices = parseVoices([ios('Maged', 'ar-SA', 'male')]);
      final best = selectBestArabicVoice(voices);
      expect(best?.name, 'Maged');
      expect(isGoodEgyptianFemaleVoice(best), isFalse);
    });
  });

  group('Offline speech routing', () {
    test('uses an installed Arabic voice regardless of accent or gender', () {
      for (final gender in TtsVoiceGender.values) {
        expect(
            Speech.decideRoute(
                languageCode: 'ar',
                outcome: outcome(isEgyptian: false, gender: gender)),
            SpeechRoute.device);
      }
    });
    test('missing Arabic never falls back to cloud or a foreign voice', () {
      expect(Speech.decideRoute(languageCode: 'ar', outcome: null),
          SpeechRoute.needsVoiceData);
      expect(
          Speech.decideRoute(
              languageCode: 'ar',
              outcome: const TtsLanguageOutcome(
                  locale: 'en-US', isArabic: false, isEgyptian: false)),
          SpeechRoute.needsVoiceData);
    });
    test('English uses the device route', () {
      expect(Speech.decideRoute(languageCode: 'en', outcome: null),
          SpeechRoute.device);
    });
    test('network-only Arabic voice is never selected', () {
      expect(
          selectBestArabicVoice(parseVoices([
            android('network', 'ar-EG', network: true),
          ])),
          isNull);
      expect(
          selectBestArabicVoice(parseVoices([
            android('network', 'ar-EG', network: true),
            android('local', 'ar-SA'),
          ]))?.name,
          'local');
    });
  });

  group('Outcome reporting', () {
    test('describes what was actually selected', () {
      final good = outcome(isEgyptian: true, gender: TtsVoiceGender.female);
      expect(good.isEgyptianFemale, isTrue);
      expect(good.describe(), contains('[ar-EG female]'));

      final male = outcome(isEgyptian: true, gender: TtsVoiceGender.male);
      expect(male.isEgyptianFemale, isFalse);
      expect(male.describe(), contains('ar-EG male'));
    });
  });
}
