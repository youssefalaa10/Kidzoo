import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every formerly downloaded font is available in the app bundle',
      () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    for (final family in ['Poppins', 'Nunito', 'ComicNeue', 'DaiBannaSIL']) {
      final entry = manifest.cast<Map<String, dynamic>>().singleWhere(
            (entry) => entry['family'] == family,
          );
      for (final font in entry['fonts'] as List<dynamic>) {
        final asset = (font as Map<String, dynamic>)['asset'] as String;
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(1000), reason: asset);
        final signature = data.getUint32(0);
        expect(signature == 0x00010000 || signature == 0x4f54544f, isTrue,
            reason: '$asset must be an actual OpenType or TrueType font');
      }
    }
  });
}
