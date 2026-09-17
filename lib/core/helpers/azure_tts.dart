import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Azure Speech configuration, supplied at build time.
///
/// Nothing here is ever committed. Pass the key in when you build:
///
/// ```
/// flutter run \
///   --dart-define=AZURE_SPEECH_KEY=xxxxxxxx \
///   --dart-define=AZURE_SPEECH_REGION=westeurope
/// ```
///
/// With no key the app simply never takes the cloud path and keeps using the
/// device voice, so a plain `flutter run` still works.
class AzureSpeechConfig {
  const AzureSpeechConfig._();

  static const String key = String.fromEnvironment('AZURE_SPEECH_KEY');

  static const String region =
      String.fromEnvironment('AZURE_SPEECH_REGION', defaultValue: 'westeurope');

  /// Salma is Azure's female Egyptian (Cairene) neural voice.
  static const String voice = String.fromEnvironment(
    'AZURE_SPEECH_VOICE',
    defaultValue: 'ar-EG-SalmaNeural',
  );

  static const String locale =
      String.fromEnvironment('AZURE_SPEECH_LOCALE', defaultValue: 'ar-EG');

  /// Forces the cloud voice even when the device has a usable Egyptian female
  /// voice. Off by default: the local voice is free, instant and works offline.
  static const bool force =
      bool.fromEnvironment('AZURE_SPEECH_FORCE');

  static bool get isConfigured => key.isNotEmpty;

  static Uri get endpoint =>
      Uri.https('$region.tts.speech.microsoft.com', '/cognitiveservices/v1');
}

/// Minimal client for Azure's text-to-speech REST endpoint.
///
/// Uses `dart:io` rather than pulling in an HTTP package - the whole surface is
/// one POST.
class AzureTtsClient {
  AzureTtsClient({
    this.subscriptionKey = AzureSpeechConfig.key,
    this.endpoint,
    this.voice = AzureSpeechConfig.voice,
    this.locale = AzureSpeechConfig.locale,
  });

  final String subscriptionKey;
  final Uri? endpoint;
  final String voice;
  final String locale;

  /// mp3 at 24kHz/48kbps: small enough for short prompts on a phone plan,
  /// and audioplayers plays it on both platforms without extra codecs.
  static const String _outputFormat = 'audio-24khz-48kbitrate-mono-mp3';

  /// Slightly slower than default, matching the device-TTS rate used for kids.
  static const String _prosodyRate = '-8%';

  Directory? _cacheDir;

  /// Requests are cached on disk by voice + text, so a prompt a child hears
  /// twenty times costs one call and then works offline.
  Future<File?> synthesizeToFile(String text) async {
    if (subscriptionKey.isEmpty || text.trim().isEmpty) return null;

    final file = await _cacheFileFor(text);
    if (file == null) return null;
    if (file.existsSync() && await file.length() > 0) return file;

    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request =
          await client.postUrl(endpoint ?? AzureSpeechConfig.endpoint);
      request.headers
        ..set('Ocp-Apim-Subscription-Key', subscriptionKey)
        ..set(HttpHeaders.contentTypeHeader, 'application/ssml+xml')
        ..set('X-Microsoft-OutputFormat', _outputFormat)
        // Azure rejects the request without a User-Agent.
        ..set(HttpHeaders.userAgentHeader, 'kidzo');
      request.add(utf8.encode(buildSsml(text)));

      final response = await request.close().timeout(
            const Duration(seconds: 12),
          );

      if (response.statusCode != HttpStatus.ok) {
        // 401 wrong key/region, 429 over quota, 502/503 upstream. Any of them
        // means "fall back to the device voice", never "fail the prompt".
        debugPrint('Azure TTS: HTTP ${response.statusCode}');
        await response.drain<void>();
        return null;
      }

      final bytes = await _collect(response);
      if (bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Azure TTS: request failed: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  Future<List<int>> _collect(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  }

  Future<File?> _cacheFileFor(String text) async {
    try {
      _cacheDir ??= Directory(
        '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}tts_cache',
      );
      final dir = _cacheDir!;
      if (!dir.existsSync()) await dir.create(recursive: true);
      return File('${dir.path}${Platform.pathSeparator}${_cacheKey(text)}.mp3');
    } catch (e) {
      debugPrint('Azure TTS: cache directory unavailable: $e');
      return null;
    }
  }

  String _cacheKey(String text) => '${voice}_${stableHash("$voice|$text")}';

  /// Builds the SSML body.
  ///
  /// Visible for testing: the escaping matters, because an unescaped `&` in a
  /// prompt would make Azure reject the whole request with a 400.
  @visibleForTesting
  String buildSsml(String text) {
    final safe = escapeXml(text);
    return '<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" '
        'xml:lang="$locale">'
        '<voice name="$voice">'
        '<prosody rate="$_prosodyRate">$safe</prosody>'
        '</voice>'
        '</speak>';
  }
}

/// XML-escapes text destined for an SSML body.
String escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// FNV-1a, so cache filenames are stable across runs.
///
/// `String.hashCode` is deliberately not stable between Dart VM launches, which
/// would silently defeat the on-disk cache.
String stableHash(String input) {
  var hash = 0xcbf29ce484222325;
  for (final unit in utf8.encode(input)) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  // Dart ints are signed 64-bit, so the accumulator can come out negative and
  // toRadixString would prefix a '-' - not something to put in a filename.
  // Emitting two unsigned 32-bit halves keeps it 16 hex characters, always.
  final high = (hash >> 32) & 0xFFFFFFFF;
  final low = hash & 0xFFFFFFFF;
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}
