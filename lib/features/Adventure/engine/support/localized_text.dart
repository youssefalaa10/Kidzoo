import 'package:flutter/foundation.dart';

/// A string authored once per locale, inline in content.
///
/// Story content does **not** go through `AppLocalizations`. That class is ~700
/// hand-written getters over two JSON files, and adding a string costs three
/// edits with no tooling to catch drift. Adventure 1 alone carries dozens of
/// narration lines, and every future Adventure adds more: routing them through
/// the getter file would make authoring a code change, which is exactly what
/// made the old `QuizEngine` unusable.
///
/// Accepts either a bare string (same text in every locale — fine for a proper
/// noun) or a `{locale: text}` map.
@immutable
class LocalizedText {
  const LocalizedText(this._byLanguageCode);

  const LocalizedText.empty() : _byLanguageCode = const <String, String>{};

  factory LocalizedText.fromJson(Object? json, {String? debugPath}) {
    if (json == null) {
      return const LocalizedText.empty();
    }
    if (json is String) {
      return LocalizedText(<String, String>{_fallbackLanguageCode: json});
    }
    if (json is Map) {
      final Map<String, String> byLanguage = <String, String>{};
      json.forEach((key, value) {
        if (value != null) {
          byLanguage['$key'] = '$value';
        }
      });
      return LocalizedText(byLanguage);
    }
    throw FormatException(
      'expected a string or a {locale: text} map${debugPath == null ? '' : ' at $debugPath'}, '
      'got ${json.runtimeType}',
    );
  }

  static const String _fallbackLanguageCode = 'en';

  final Map<String, String> _byLanguageCode;

  Iterable<String> get languageCodes => _byLanguageCode.keys;

  bool get isEmpty => _byLanguageCode.isEmpty;

  bool hasLanguage(String languageCode) =>
      _byLanguageCode[languageCode]?.trim().isNotEmpty ?? false;

  /// The text for [languageCode], falling back to English and then to an empty
  /// string. Never throws: a missing translation degrades, it does not crash a
  /// child's story mid-sentence.
  String resolve(String languageCode) {
    final String? exact = _byLanguageCode[languageCode];
    if (exact != null && exact.isNotEmpty) {
      return exact;
    }
    final String? fallback = _byLanguageCode[_fallbackLanguageCode];
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return '';
  }

  @override
  String toString() => 'LocalizedText($_byLanguageCode)';
}
