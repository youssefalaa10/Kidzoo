import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/helpers/tts_voice_selection.dart';

/// Shapes taken from real `getVoices` output.
Map<Object?, Object?> androidVoice(
  String name,
  String locale, {
  int quality = 300,
  bool network = false,
}) =>
    {
      'name': name,
      'locale': locale,
      'quality': quality,
      'latency': 300,
      'network_required': network,
      'features': const <String>[],
    };

Map<Object?, Object?> iosVoice(
  String name,
  String locale, {
  int quality = 0,
  String gender = 'male',
}) =>
    {
      'name': name,
      'locale': locale,
      'quality': quality,
      'gender': gender,
      'identifier': 'com.apple.voice.compact.$locale.$name',
    };

void main() {
  group('Locale normalisation', () {
    test('accepts the underscore and mixed-case forms Android emits', () {
      expect(normalizeLocale('ar_EG'), 'ar-eg');
      expect(normalizeLocale('AR-eg'), 'ar-eg');
      expect(normalizeLocale('  ar-EG '), 'ar-eg');
    });
  });

  group('Egyptian detection', () {
    test('recognises the ar-EG locale', () {
      const voice = TtsVoiceCandidate(name: 'any', locale: 'ar-EG');
      expect(voice.isArabic, isTrue);
      expect(voice.isEgyptian, isTrue);
    });

    test('recognises the arz subtag inside a Google voice name', () {
      // Google names its Egyptian Arabic voice this way while still reporting
      // the pan-Arabic ar-XA locale, so the locale alone would miss it.
      const voice =
          TtsVoiceCandidate(name: 'ar-xa-x-arz-local', locale: 'ar-XA');
      expect(voice.isEgyptian, isTrue);
    });

    test('does not mistake other Arabic voices for Egyptian', () {
      const saudi =
          TtsVoiceCandidate(name: 'ar-xa-x-ard-local', locale: 'ar-SA');
      expect(saudi.isArabic, isTrue);
      expect(saudi.isEgyptian, isFalse);
    });

    test('does not treat a non-Arabic voice as Arabic', () {
      const english = TtsVoiceCandidate(name: 'Karen', locale: 'en-AU');
      expect(english.isArabic, isFalse);
      expect(scoreArabicVoice(english), lessThan(0));
    });

    test('is not fooled by an unrelated name containing "eg"', () {
      // "Regina" contains "eg" but only as letters inside a word; the check
      // looks at subtags, not substrings.
      const voice = TtsVoiceCandidate(name: 'Regina', locale: 'de-DE');
      expect(voice.isEgyptian, isFalse);
    });
  });

  group('Choosing the best Arabic voice', () {
    test('ar-EG wins over every other Arabic locale', () {
      final voices = parseVoices([
        androidVoice('ar-xa-x-ard-local', 'ar-SA'),
        androidVoice('ar-eg-x-arz-local', 'ar-EG'),
        androidVoice('ar-xa-x-arb-local', 'ar-AE'),
      ]);
      expect(selectBestArabicVoice(voices)?.locale, 'ar-EG');
    });

    test('an Egyptian-named voice beats a non-Egyptian locale match', () {
      final voices = parseVoices([
        androidVoice('ar-xa-x-ard-local', 'ar-SA', quality: 500),
        androidVoice('ar-xa-x-arz-local', 'ar-XA', quality: 100),
      ]);
      // Region matters more than quality: the Egyptian voice wins even though
      // the Saudi one reports the best quality on the device.
      expect(selectBestArabicVoice(voices)?.name, 'ar-xa-x-arz-local');
    });

    test('prefers an offline voice over an equivalent network one', () {
      final voices = parseVoices([
        androidVoice('ar-eg-network', 'ar-EG', quality: 500, network: true),
        androidVoice('ar-eg-local', 'ar-EG', quality: 400),
      ]);
      expect(selectBestArabicVoice(voices)?.name, 'ar-eg-local');
    });

    test('prefers higher quality when region and network match', () {
      final voices = parseVoices([
        androidVoice('ar-eg-low', 'ar-EG', quality: 100),
        androidVoice('ar-eg-high', 'ar-EG', quality: 500),
      ]);
      expect(selectBestArabicVoice(voices)?.name, 'ar-eg-high');
    });

    test('falls back through the preference order when Egypt is absent', () {
      final voices = parseVoices([
        androidVoice('ma', 'ar-MA'),
        androidVoice('sa', 'ar-SA'),
        androidVoice('xa', 'ar-XA'),
      ]);
      // ar-XA is Google's pan-Arabic voice and outranks the country ones.
      expect(selectBestArabicVoice(voices)?.locale, 'ar-XA');
    });

    test('handles the underscore locales Android sometimes reports', () {
      final voices = parseVoices([
        androidVoice('sa', 'ar_SA'),
        androidVoice('eg', 'ar_EG'),
      ]);
      expect(selectBestArabicVoice(voices)?.name, 'eg');
    });

    test('returns null when the device has no Arabic voice at all', () {
      final voices = parseVoices([
        androidVoice('en-us-x-sfg-local', 'en-US'),
        androidVoice('fr-fr-x-frc-local', 'fr-FR'),
      ]);
      expect(selectBestArabicVoice(voices), isNull);
    });

    test('on iOS, where only ar-SA exists, it picks ar-SA and flags it', () {
      // iOS ships a single Arabic voice (Maged, ar-SA). There is no ar-EG
      // voice on the platform, so the fallback path is the normal path there.
      final voices = parseVoices([
        iosVoice('Maged', 'ar-SA'),
        iosVoice('Samantha', 'en-US'),
      ]);
      final best = selectBestArabicVoice(voices);
      expect(best?.name, 'Maged');
      expect(best?.isEgyptian, isFalse);
    });

    test('iOS enhanced quality beats compact for the same locale', () {
      final voices = parseVoices([
        iosVoice('Maged', 'ar-SA'),
        iosVoice('MagedEnhanced', 'ar-SA', quality: 1),
      ]);
      expect(selectBestArabicVoice(voices)?.name, 'MagedEnhanced');
    });
  });

  group('Parsing raw platform output', () {
    test('skips malformed rows instead of throwing', () {
      final voices = parseVoices([
        androidVoice('ar-eg', 'ar-EG'),
        'not a map',
        <Object?, Object?>{},
        null,
      ]);
      expect(voices, hasLength(1));
      expect(voices.single.locale, 'ar-EG');
    });

    test('reads network_required whether it is a bool or a string', () {
      expect(
        TtsVoiceCandidate.fromMap(
                {'name': 'a', 'locale': 'ar-EG', 'network_required': true})
            .networkRequired,
        isTrue,
      );
      expect(
        TtsVoiceCandidate.fromMap(
                {'name': 'a', 'locale': 'ar-EG', 'network_required': 'true'})
            .networkRequired,
        isTrue,
      );
      expect(
        TtsVoiceCandidate.fromMap(
                {'name': 'a', 'locale': 'ar-EG', 'network_required': 'false'})
            .networkRequired,
        isFalse,
      );
    });

    test('reads quality whether it is an int or a string', () {
      expect(
        TtsVoiceCandidate.fromMap(
            {'name': 'a', 'locale': 'ar-EG', 'quality': '400'}).quality,
        400,
      );
      expect(
        TtsVoiceCandidate.fromMap(
            {'name': 'a', 'locale': 'ar-EG', 'quality': 400}).quality,
        400,
      );
    });

    test('returns nothing for a non-list payload', () {
      expect(parseVoices(null), isEmpty);
      expect(parseVoices('oops'), isEmpty);
    });
  });

  group('Locale-only fallback ordering', () {
    test('puts ar-EG first when the device reports it', () {
      final attempts =
          arabicLocaleAttempts(['en-US', 'ar-SA', 'ar-EG', 'fr-FR']);
      expect(attempts.first, 'ar-eg');
      expect(attempts, contains('ar-sa'));
      expect(attempts, isNot(contains('en-us')));
    });

    test('keeps an Arabic locale we never thought to list', () {
      final attempts = arabicLocaleAttempts(['ar-XY']);
      expect(attempts, contains('ar-xy'));
    });

    test('falls back to the full preference list when the engine says nothing',
        () {
      final attempts = arabicLocaleAttempts(const []);
      expect(attempts.first, 'ar-eg');
      expect(attempts, equals(kArabicLocalePreference));
    });

    test('the preferred locale constant and the ranking agree', () {
      expect(normalizeLocale(kPreferredArabicLocale),
          kArabicLocalePreference.first);
    });
  });
}
