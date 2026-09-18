/// Numbers, in the two forms a counting activity needs them.
///
/// A child counting out loud hears *words* and reads *digits*, and the two are
/// not the same string in either locale. Arabic needs both a different glyph set
/// (Eastern Arabic-Indic) and a different spoken form, and the spoken form is
/// vowelised for the same reason every other Arabic string here is.
///
/// This lives in `support/` rather than in the counting engine because the
/// spoken form is requested by the **base cubit** (which owns the narrator) and
/// the written form by the **host** (which owns presentation). Neither belongs
/// to one engine.
class NumberWords {
  const NumberWords._();

  static const List<String> _easternDigits = <String>[
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
  ];

  /// Spoken cardinal numbers, 1..10, authored whole.
  ///
  /// Not assembled from digits: a TTS engine handed "٣" may read it as the
  /// wrong dialect's word, or spell it out, and the counting activity's whole
  /// job is that the child hears the number named correctly.
  static const Map<String, List<String>> _spoken = <String, List<String>>{
    'en': <String>[
      'one', 'two', 'three', 'four', 'five',
      'six', 'seven', 'eight', 'nine', 'ten',
    ],
    'ar': <String>[
      'وَاحِد', 'اِثْنَان', 'ثَلَاثَة', 'أَرْبَعَة', 'خَمْسَة',
      'سِتَّة', 'سَبْعَة', 'ثَمَانِيَة', 'تِسْعَة', 'عَشَرَة',
    ],
  };

  /// The digits to **show**, in the script the child is reading.
  static String digits(int value, String languageCode) {
    if (languageCode != 'ar') {
      return '$value';
    }
    return value
        .toString()
        .split('')
        .map((String digit) => _easternDigits[int.parse(digit)])
        .join();
  }

  /// The word to **say** for [value], or its digits when it is off the end of
  /// the authored list. Counting content stays inside 1..10, so the fallback is
  /// a safety net rather than a path anything takes.
  static String spoken(int value, String languageCode) {
    final List<String> words = _spoken[languageCode] ?? _spoken['en']!;
    if (value < 1 || value > words.length) {
      return digits(value, languageCode);
    }
    return words[value - 1];
  }
}
