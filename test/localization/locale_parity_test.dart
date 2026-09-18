import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the localization files against the failure that shipped twice:
/// `AppLocalizations` exposes ~700 getters of the form `_localizedValues['k']!`,
/// so a key present in one locale file and absent from the other is a crash in
/// that locale, not a missing translation.
///
/// Two real bugs this suite would have caught:
///   * `straightLineModeEnabled` / `freehandModeEnabled` existed only in
///     `ar.json`, so toggling DrawLab's line mode in English threw.
///   * `medium` existed only in `en.json`, leaving `l10n.medium` latent-fatal
///     in Arabic.
void main() {
  late final Map<String, String> englishValues;
  late final Map<String, String> arabicValues;
  late final String localizationsSource;

  Map<String, String> loadLanguageFile(String languageCode) {
    final File file = File('assets/lang/$languageCode.json');
    expect(file.existsSync(), isTrue,
        reason: 'missing language file: ${file.path}');
    final Map<String, dynamic> decoded =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  setUpAll(() {
    englishValues = loadLanguageFile('en');
    arabicValues = loadLanguageFile('ar');
    localizationsSource =
        File('lib/core/localization/app_localizations.dart').readAsStringSync();
  });

  group('Locale file parity', () {
    test('every English key has an Arabic counterpart', () {
      final Set<String> missingFromArabic =
          englishValues.keys.toSet().difference(arabicValues.keys.toSet());
      expect(missingFromArabic, isEmpty,
          reason: 'keys in en.json with no ar.json entry: $missingFromArabic');
    });

    test('every Arabic key has an English counterpart', () {
      final Set<String> missingFromEnglish =
          arabicValues.keys.toSet().difference(englishValues.keys.toSet());
      expect(missingFromEnglish, isEmpty,
          reason: 'keys in ar.json with no en.json entry: $missingFromEnglish');
    });

    test('no value is blank in either locale', () {
      final List<String> blankEnglish = englishValues.entries
          .where((entry) => entry.value.trim().isEmpty)
          .map((entry) => entry.key)
          .toList();
      final List<String> blankArabic = arabicValues.entries
          .where((entry) => entry.value.trim().isEmpty)
          .map((entry) => entry.key)
          .toList();
      expect(blankEnglish, isEmpty, reason: 'blank en.json values');
      expect(blankArabic, isEmpty, reason: 'blank ar.json values');
    });
  });

  group('Getter backing keys', () {
    /// Every map lookup by string literal in the source. These are
    /// non-null-asserted, so an absent key throws at call time.
    ///
    /// Comments are stripped first: the class documents its own lookup shape
    /// in prose, and matching that would report a phantom key.
    Set<String> readKeysUsedByGetters() {
      final String codeOnly = localizationsSource
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
      final RegExp lookupPattern = RegExp(r"_localizedValues\['([^']+)'\]");
      return lookupPattern
          .allMatches(codeOnly)
          .map((match) => match.group(1)!)
          .toSet();
    }

    test('finds the getter lookups it is meant to check', () {
      // A sanity check on the regex itself: if AppLocalizations is ever
      // restructured, this test fails loudly rather than passing vacuously.
      expect(readKeysUsedByGetters().length, greaterThan(500));
    });

    test('every key a getter reads exists in English', () {
      final Set<String> missing =
          readKeysUsedByGetters().difference(englishValues.keys.toSet());
      expect(missing, isEmpty,
          reason: 'getters read these keys, absent from en.json: $missing');
    });

    test('every key a getter reads exists in Arabic', () {
      final Set<String> missing =
          readKeysUsedByGetters().difference(arabicValues.keys.toSet());
      expect(missing, isEmpty,
          reason: 'getters read these keys, absent from ar.json: $missing');
    });
  });
}
