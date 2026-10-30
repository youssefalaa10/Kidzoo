import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kidzo/core/helpers/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final selected = <String>[];
  var networkOnly = false;
  var failSelection = false;

  setUp(() {
    networkOnly = false;
    failSelection = false;
    selected.clear();
    TtsService.invalidateVoiceCache();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getVoices') {
        return [
          for (final locale in ['en-US', 'ar-SA']) ...[
            {
              'name': '$locale-network',
              'locale': locale,
              'network_required': true
            },
            if (!networkOnly)
              {
                'name': '$locale-local',
                'locale': locale,
                'network_required': false
              },
          ],
        ];
      }
      if (call.method == 'setVoice') {
        if (failSelection) throw PlatformException(code: 'unavailable');
        selected.add((call.arguments as Map)['name'] as String);
      }
      return 1;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  for (final language in ['en', 'ar']) {
    test('$language pins a local voice instead of a network voice', () async {
      final outcome = await TtsService.applyLanguageTo(FlutterTts(), language);
      expect(outcome.voiceName, endsWith('-local'));
      expect(selected, isNotEmpty);
      expect(selected.every((name) => name.endsWith('-local')), isTrue);
    });
    test('$language stays without narration when only network voices exist',
        () async {
      networkOnly = true;
      final outcome = await TtsService.applyLanguageTo(FlutterTts(), language);
      expect(outcome.voiceName, isNull);
      expect(selected, isEmpty);
    });
    test('$language does not use an unpinned default after selection fails',
        () async {
      failSelection = true;
      final outcome = await TtsService.applyLanguageTo(FlutterTts(), language);
      expect(outcome.voiceName, isNull);
    });
  }
}
