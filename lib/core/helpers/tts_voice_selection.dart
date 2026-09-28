/// Picking an Arabic text-to-speech voice, kept free of plugin and platform
/// calls so the rules can be exercised in tests.
///
/// The app speaks to Egyptian children, so `ar-EG` is what we want and
/// everything else is a fallback. What is actually installed varies a lot:
///
///  * Android exposes whatever the selected engine ships. Google's engine
///    names its Arabic voices in the `ar-xa-x-arz-local` style, where `arz` is
///    the ISO 639-3 code for **Egyptian** Arabic - so a voice can be Egyptian
///    while its locale still reads `ar-XA`. That is why the name is scored as
///    well as the locale.
///  * iOS ships one Arabic voice, `ar-SA` (Maged). There is no `ar-EG` voice
///    on iOS, so on that platform the fallback path is the normal path.
library;

/// Arabic locales in the order we want them, best first.
///
/// `ar-XA` is Google's pan-Arabic locale and is usually the best-sounding
/// generic voice, so it outranks the country-specific ones below it.
const List<String> kArabicLocalePreference = <String>[
  'ar-eg',
  'ar-xa',
  'ar-sa',
  'ar-ae',
  'ar-jo',
  'ar-kw',
  'ar-qa',
  'ar-bh',
  'ar-om',
  'ar-lb',
  'ar-ps',
  'ar-iq',
  'ar-sy',
  'ar-ye',
  'ar-ly',
  'ar-tn',
  'ar-dz',
  'ar-ma',
  'ar',
];

/// The locale we ask for before anything else.
const String kPreferredArabicLocale = 'ar-EG';

/// What we know about a voice's gender.
enum TtsVoiceGender { female, male, unknown }

/// Gender of Google's on-device Arabic voice variants.
///
/// Android's `TextToSpeech.Voice` API exposes no gender field at all, so the
/// only signal available is the variant subtag in the voice name
/// (`ar-xa-x-**arz**-local`). This mapping is the community-documented one for
/// Google's engine; where a device *does* report a gender (iOS does) that
/// reported value always wins over this table.
///
/// `arz` is the happy case for this app: it is both the Egyptian variant and a
/// female voice.
const Map<String, TtsVoiceGender> kGoogleArabicVariantGender = {
  'arz': TtsVoiceGender.female,
  'arc': TtsVoiceGender.female,
  'ard': TtsVoiceGender.male,
  'are': TtsVoiceGender.male,
};

/// Normalises the many shapes a locale arrives in (`ar_EG`, `ar-EG`, `ARA-EGY`)
/// to a lowercase, dash-separated form.
String normalizeLocale(String raw) =>
    raw.trim().replaceAll('_', '-').toLowerCase();

/// One voice as reported by `FlutterTts.getVoices`.
class TtsVoiceCandidate {
  const TtsVoiceCandidate({
    required this.name,
    required this.locale,
    this.quality,
    this.networkRequired = false,
    this.gender,
  });

  /// Builds a candidate from a raw `getVoices` entry.
  ///
  /// Keys differ per platform (Android adds `quality`, `latency`,
  /// `network_required`, `features`; iOS adds `quality`, `gender`,
  /// `identifier`) and values arrive as `String`, `bool` or `int` depending on
  /// the platform channel, so everything is read defensively.
  factory TtsVoiceCandidate.fromMap(Map<Object?, Object?> map) {
    String read(String key) => map[key]?.toString() ?? '';

    final rawNetwork = map['network_required'] ?? map['networkRequired'];
    final network = rawNetwork is bool
        ? rawNetwork
        : rawNetwork?.toString().toLowerCase() == 'true' ||
            rawNetwork?.toString() == '1';

    final rawQuality = map['quality'];
    final quality = rawQuality is int
        ? rawQuality
        : int.tryParse(rawQuality?.toString() ?? '');

    return TtsVoiceCandidate(
      name: read('name'),
      locale: read('locale'),
      quality: quality,
      networkRequired: network,
      gender: map['gender']?.toString(),
    );
  }

  final String name;
  final String locale;

  /// Android reports 100..500 (very low..very high); iOS reports 0..2
  /// (default, enhanced, premium). Both scales are handled.
  final int? quality;

  /// A voice that needs the network is unusable offline and adds latency, so
  /// it loses to an equivalent local voice.
  final bool networkRequired;
  final String? gender;

  String get normalizedLocale => normalizeLocale(locale);

  String get languageCode => normalizedLocale.split('-').first;

  String get regionCode {
    final parts = normalizedLocale.split('-');
    return parts.length > 1 ? parts[1] : '';
  }

  List<String> get _nameTokens =>
      normalizeLocale(name).split(RegExp(r'[-_. ]'));

  /// Best guess at the speaker's gender.
  ///
  /// A platform-reported value is trusted first (iOS supplies one); otherwise
  /// the voice name is read, either for an explicit word or for Google's
  /// variant subtag.
  TtsVoiceGender get inferredGender {
    final reported = gender?.toLowerCase().trim();
    if (reported != null) {
      // Order matters: "female" contains "male".
      if (reported.contains('female') || reported == 'f') {
        return TtsVoiceGender.female;
      }
      if (reported.contains('male') || reported == 'm') {
        return TtsVoiceGender.male;
      }
    }

    final tokens = _nameTokens;
    if (tokens.any((t) => t.contains('female') || t == 'woman' || t == 'f')) {
      return TtsVoiceGender.female;
    }
    for (final token in tokens) {
      final variant = kGoogleArabicVariantGender[token];
      if (variant != null) return variant;
    }
    if (tokens.any((t) => t.contains('male') || t == 'man' || t == 'm')) {
      return TtsVoiceGender.male;
    }
    return TtsVoiceGender.unknown;
  }

  bool get isFemale => inferredGender == TtsVoiceGender.female;
  bool get isMale => inferredGender == TtsVoiceGender.male;

  /// `ar` and the ISO 639-3 codes for the Arabic macrolanguage varieties we
  /// might see (`ara`, and `arz` for Egyptian).
  bool get isArabic =>
      languageCode == 'ar' ||
      languageCode == 'ara' ||
      languageCode == 'arz' ||
      normalizedLocale.startsWith('ar-');

  /// True when either the locale says Egypt or the voice name carries the
  /// Egyptian Arabic subtag.
  bool get isEgyptian {
    if (regionCode == 'eg' || regionCode == 'egy') return true;
    if (languageCode == 'arz') return true;
    return _nameHasEgyptianTag;
  }

  bool get _nameHasEgyptianTag {
    final tokens = _nameTokens;
    return tokens.contains('arz') ||
        tokens.contains('eg') ||
        tokens.contains('egy');
  }

  @override
  String toString() => 'TtsVoiceCandidate($name, $locale, quality: $quality, '
      'network: $networkRequired)';
}

/// How good a match this voice is. Higher wins; a negative score means the
/// voice is not Arabic at all and must not be used.
///
/// With [preferFemale] on (the default) the app asks for a female narrator,
/// which is the convention for young children's audio and what this app wants.
int scoreArabicVoice(
  TtsVoiceCandidate voice, {
  List<String> preference = kArabicLocalePreference,
  bool preferFemale = true,
}) {
  if (!voice.isArabic) return -1;

  var score = 0;

  // Region beats everything else: an Egyptian voice at mediocre quality is
  // still the right voice for this app.
  if (voice.isEgyptian) score += 10000;

  if (preferFemale) {
    // Gender ranks just under region, so an Egyptian male still beats a
    // non-Egyptian female - the accent is the thing a child actually learns
    // from. A known male voice is demoted below an unknown one rather than
    // excluded, so a device with only male Arabic voices still speaks.
    switch (voice.inferredGender) {
      case TtsVoiceGender.female:
        score += 4000;
        break;
      case TtsVoiceGender.unknown:
        score += 1000;
        break;
      case TtsVoiceGender.male:
        break;
    }
  }

  // Then how close the locale is to our preference order.
  final rank = preference.indexOf(voice.normalizedLocale);
  if (rank >= 0) {
    score += (preference.length - rank) * 100;
  } else if (voice.languageCode.startsWith('ar')) {
    // An Arabic locale we have not listed still beats nothing.
    score += 50;
  }

  // Offline voices are worth real money in a children's app: no latency, and
  // they keep working on a tablet with no connection.
  if (!voice.networkRequired) score += 400;

  score += _qualityBonus(voice.quality);

  return score;
}

int _qualityBonus(int? quality) {
  if (quality == null) return 0;
  if (quality >= 100) {
    // Android's 100..500 scale.
    return ((quality - 100) / 100 * 20).round();
  }
  // iOS's 0..2 scale (default, enhanced, premium).
  return quality * 40;
}

/// The best Arabic voice in [voices], or null when there is no Arabic voice.
TtsVoiceCandidate? selectBestArabicVoice(
  List<TtsVoiceCandidate> voices, {
  List<String> preference = kArabicLocalePreference,
  bool preferFemale = true,
}) {
  TtsVoiceCandidate? best;
  var bestScore = 0;

  for (final voice in voices) {
    final score = scoreArabicVoice(
      voice,
      preference: preference,
      preferFemale: preferFemale,
    );
    if (score <= 0) continue;
    if (best == null || score > bestScore) {
      best = voice;
      bestScore = score;
    }
  }
  return best;
}

/// Whether [voice] is good enough that we should not reach for a cloud voice.
///
/// The bar is deliberately specific: a **female Egyptian** voice. Anything
/// less - a male Egyptian, a female Saudi, a generic `ar` - is the situation
/// the user described as sounding wrong, so it is treated as a fallback rather
/// than a result.
bool isGoodEgyptianFemaleVoice(TtsVoiceCandidate? voice) {
  if (voice == null) return false;
  return voice.isArabic && voice.isEgyptian && voice.isFemale;
}

/// Parses a raw `getVoices` result into candidates, skipping malformed rows.
List<TtsVoiceCandidate> parseVoices(Object? raw) {
  if (raw is! List) return const [];
  final result = <TtsVoiceCandidate>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final candidate = TtsVoiceCandidate.fromMap(entry.cast<Object?, Object?>());
    if (candidate.name.isEmpty && candidate.locale.isEmpty) continue;
    result.add(candidate);
  }
  return result;
}

/// The Arabic locales to try with `setLanguage`, best first, given what the
/// engine says it supports.
///
/// Used when voice enumeration comes back empty, which happens on some Android
/// engines and on the web.
List<String> arabicLocaleAttempts(Iterable<String> availableLocales) {
  final available = availableLocales.map(normalizeLocale).toSet();
  final ordered = <String>[];

  for (final locale in kArabicLocalePreference) {
    if (available.contains(locale)) ordered.add(locale);
  }
  // Anything Arabic the device offers that we did not think to list.
  for (final locale in available) {
    if (locale.startsWith('ar') && !ordered.contains(locale)) {
      ordered.add(locale);
    }
  }
  // If the engine told us nothing, still try our preferred order blind.
  if (ordered.isEmpty) return List<String>.from(kArabicLocalePreference);
  return ordered;
}
