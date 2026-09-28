import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:kidzo/core/localization/app_localizations.dart';

/// An [AppLocalizations] delegate that resolves synchronously, from disk.
///
/// The production delegate reads `assets/lang/*.json` through `rootBundle`.
/// That works in the first widget test of a file and then stops: the test
/// binding resets the binary messenger between tests, so the asset future
/// never completes, `Localizations` keeps rendering its empty placeholder, and
/// every finder in every later test comes back with nothing. It fails silently,
/// which is the worst way for it to fail.
///
/// Reading the same files with `dart:io` and handing back a [SynchronousFuture]
/// sidesteps the channel entirely. It is the same trick
/// `test/catalog/grid_contents_regression_test.dart` uses to check the locale
/// files, so the strings under test are still the real shipped ones.
class TestAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const <String>['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final File file = File('assets/lang/${locale.languageCode}.json');
    final Map<String, dynamic> decoded =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    return SynchronousFuture<AppLocalizations>(AppLocalizations(
      locale,
      decoded.map((String key, dynamic value) =>
          MapEntry<String, String>(key, value.toString())),
    ));
  }

  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}
