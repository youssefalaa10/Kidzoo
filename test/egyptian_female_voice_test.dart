import 'package:flutter_test/flutter_test.dart';
import 'package:kidzo/core/helpers/azure_tts.dart';
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
      // cloud voice necessary on that platform.
      final voices = parseVoices([ios('Maged', 'ar-SA', 'male')]);
      final best = selectBestArabicVoice(voices);
      expect(best?.name, 'Maged');
      expect(isGoodEgyptianFemaleVoice(best), isFalse);
    });
  });

  group('Choosing between the device and the cloud', () {
    SpeechRoute route({
      required TtsLanguageOutcome? deviceOutcome,
      bool azure = true,
      bool force = false,
      String language = 'ar',
    }) =>
        Speech.decideRoute(
          languageCode: language,
          outcome: deviceOutcome,
          azureConfigured: azure,
          forceAzure: force,
        );

    test('keeps the device voice when it is female and Egyptian', () {
      expect(
        route(
          deviceOutcome:
              outcome(isEgyptian: true, gender: TtsVoiceGender.female),
        ),
        SpeechRoute.device,
      );
    });

    test('goes to Azure for an Egyptian male voice', () {
      expect(
        route(
          deviceOutcome: outcome(isEgyptian: true, gender: TtsVoiceGender.male),
        ),
        SpeechRoute.azure,
      );
    });

    test('goes to Azure for a female voice that is not Egyptian', () {
      expect(
        route(
          deviceOutcome:
              outcome(isEgyptian: false, gender: TtsVoiceGender.female),
        ),
        SpeechRoute.azure,
      );
    });

    test('goes to Azure when the device has no Arabic voice at all', () {
      expect(route(deviceOutcome: null), SpeechRoute.azure);
    });

    test('never uses Azure when no key is configured', () {
      // A non-ideal but genuinely Arabic voice is an acceptable stand-in.
      expect(
        route(
          deviceOutcome: outcome(isEgyptian: true, gender: TtsVoiceGender.male),
          azure: false,
        ),
        SpeechRoute.device,
      );
      expect(
        route(
          deviceOutcome:
              outcome(isEgyptian: false, gender: TtsVoiceGender.unknown),
          azure: false,
        ),
        SpeechRoute.device,
      );
    });

    test('stays silent rather than reading Arabic in a foreign voice', () {
      // No Arabic voice and no cloud voice. Handing Arabic script to an
      // English engine is the bug being fixed, so nothing is spoken and the
      // UI prompts for a download instead.
      expect(
        route(deviceOutcome: null, azure: false),
        SpeechRoute.needsVoiceData,
      );
      expect(
        route(
          deviceOutcome: const TtsLanguageOutcome(
            locale: 'en-US',
            isArabic: false,
            isEgyptian: false,
            gender: TtsVoiceGender.female,
          ),
          azure: false,
        ),
        SpeechRoute.needsVoiceData,
      );
    });

    test('leaves English on the device voice even with Azure available', () {
      expect(
        route(deviceOutcome: null, language: 'en'),
        SpeechRoute.device,
      );
    });

    test('the force flag overrides a perfectly good device voice', () {
      expect(
        route(
          deviceOutcome:
              outcome(isEgyptian: true, gender: TtsVoiceGender.female),
          force: true,
        ),
        SpeechRoute.azure,
      );
    });
  });

  group('Azure request building', () {
    // The default voice is already asserted below, so this just needs a key.
    final client = AzureTtsClient(subscriptionKey: 'test-key');

    test('names the Egyptian female voice and locale', () {
      final ssml = client.buildSsml('مرحبا');
      expect(ssml, contains('name="ar-EG-SalmaNeural"'));
      expect(ssml, contains('xml:lang="ar-EG"'));
      expect(ssml, contains('مرحبا'));
    });

    test('escapes characters that would break the request', () {
      // An unescaped & makes Azure reject the whole body with a 400.
      final ssml = client.buildSsml('Tom & Jerry <5> "x"');
      expect(ssml, contains('Tom &amp; Jerry &lt;5&gt;'));
      expect(ssml, isNot(contains('& J')));
    });

    test('escapes every XML metacharacter', () {
      expect(escapeXml('''&<>"' '''), '&amp;&lt;&gt;&quot;&apos; ');
    });

    test('cache keys are stable across runs and differ per text', () {
      // String.hashCode is not stable between VM launches, which would quietly
      // defeat the on-disk cache.
      expect(stableHash('يلا نأكّل الأسد'), stableHash('يلا نأكّل الأسد'));
      expect(stableHash('a'), isNot(stableHash('b')));
      expect(stableHash('a'), hasLength(16));
    });

    test('does nothing without a key', () async {
      // Explicit even though it matches the (unconfigured) default: the
      // point of the test is the empty key, and the default stops being
      // empty as soon as anyone builds with --dart-define.
      // ignore: avoid_redundant_argument_values
      final unconfigured = AzureTtsClient(subscriptionKey: '');
      expect(await unconfigured.synthesizeToFile('hello'), isNull);
    });

    test('the default voice is Azure\'s female Egyptian one', () {
      expect(AzureSpeechConfig.voice, 'ar-EG-SalmaNeural');
      expect(AzureSpeechConfig.locale, 'ar-EG');
    });

    test('is inert until a key is supplied at build time', () {
      // No --dart-define in a test run, so nothing can call out.
      expect(AzureSpeechConfig.isConfigured, isFalse);
    });

    test('endpoint follows the documented regional pattern', () {
      final uri = AzureSpeechConfig.endpoint;
      expect(uri.scheme, 'https');
      expect(uri.host, endsWith('.tts.speech.microsoft.com'));
      expect(uri.path, '/cognitiveservices/v1');
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
