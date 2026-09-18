import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// Thrown when a content file is malformed, always naming the JSON path so the
/// author is told *where*, not just *that*, something is wrong.
class ActivityContentException implements Exception {
  ActivityContentException(this.jsonPath, this.message);
  final String jsonPath;
  final String message;

  @override
  String toString() => 'ActivityContentException at $jsonPath: $message';
}

/// The shared envelope every activity file carries, before the engine has
/// looked at its own payload.
@immutable
class ActivitySpec {
  const ActivitySpec({
    required this.instanceId,
    required this.engineId,
    required this.schemaVersion,
    required this.locales,
    required this.presentation,
    required this.narration,
    required this.support,
    required this.payload,
    required this.adaptation,
    this.sourcePath = '<memory>',
  });

  factory ActivitySpec.fromJson(
    Map<String, dynamic> json, {
    String sourcePath = '<memory>',
  }) {
    final JsonReader reader = JsonReader(json, sourcePath);
    return ActivitySpec(
      instanceId: reader.requireString('instanceId'),
      engineId: reader.requireString('engineId'),
      schemaVersion: reader.optionalInt('schemaVersion') ?? 1,
      locales: reader.requireStringList('locales'),
      presentation:
          ActivityPresentation.fromJson(reader.optionalMap('presentation')),
      narration: ActivityNarration.fromJson(reader.optionalMap('narration')),
      support: ActivitySupport.fromJson(reader.optionalMap('support')),
      payload: reader.optionalMap('payload') ?? const <String, dynamic>{},
      adaptation: ActivityAdaptation.fromJson(reader.optionalMap('adaptation')),
      sourcePath: sourcePath,
    );
  }

  final String instanceId;
  final String engineId;
  final int schemaVersion;
  final List<String> locales;
  final ActivityPresentation presentation;
  final ActivityNarration narration;
  final ActivitySupport support;
  final Map<String, dynamic> payload;
  final ActivityAdaptation adaptation;
  final String sourcePath;

  JsonReader get payloadReader =>
      JsonReader(payload, '$sourcePath > payload');
}

/// Backdrop and accent. Deliberately tiny: anything richer is art, not config.
@immutable
class ActivityPresentation {
  const ActivityPresentation({
    this.backgroundType,
    this.backgroundAsset,
    this.sceneImage,
    this.accent,
    this.celebration,
  });

  factory ActivityPresentation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityPresentation();
    }
    final JsonReader reader = JsonReader(json, 'presentation');
    return ActivityPresentation(
      backgroundType: reader.optionalString('backgroundType'),
      backgroundAsset: reader.optionalString('backgroundAsset'),
      sceneImage: reader.optionalString('sceneImage'),
      accent: reader.optionalString('accent'),
      celebration: reader.optionalString('celebration'),
    );
  }

  final String? backgroundType;
  final String? backgroundAsset;
  final String? sceneImage;
  final String? accent;
  final String? celebration;
}

/// The four spoken lines every activity provides.
///
/// `hint1`, `hint2` and `model` map one-to-one onto the no-fail ladder, so an
/// engine can never invent its own escalation copy.
@immutable
class ActivityNarration {
  const ActivityNarration({
    required this.prompt,
    required this.hint1,
    required this.hint2,
    required this.model,
    required this.success,
  });

  factory ActivityNarration.fromJson(Map<String, dynamic>? json) {
    final Map<String, dynamic> map = json ?? const <String, dynamic>{};
    return ActivityNarration(
      prompt: LocalizedText.fromJson(map['prompt'], debugPath: 'narration.prompt'),
      hint1: LocalizedText.fromJson(map['hint1'], debugPath: 'narration.hint1'),
      hint2: LocalizedText.fromJson(map['hint2'], debugPath: 'narration.hint2'),
      model: LocalizedText.fromJson(map['model'], debugPath: 'narration.model'),
      success:
          LocalizedText.fromJson(map['success'], debugPath: 'narration.success'),
    );
  }

  final LocalizedText prompt;
  final LocalizedText hint1;
  final LocalizedText hint2;
  final LocalizedText model;
  final LocalizedText success;

  /// All non-empty lines, for the content test's per-locale coverage check.
  Map<String, LocalizedText> get all => <String, LocalizedText>{
        'prompt': prompt,
        'hint1': hint1,
        'hint2': hint2,
        'model': model,
        'success': success,
      }..removeWhere((_, LocalizedText text) => text.isEmpty);
}

/// The cross-cutting settings the **base** cubit and the no-fail coach consume.
///
/// Deliberately not "difficulty". `distractorCount` is Terrace's errorless
/// fading procedure expressed as data, and `scaffolding` selects the feedback
/// regime — both belong to the shared lifecycle, not to any one engine. Real
/// gameplay parameters live in the engine's own `payload` under their real
/// names (`targetCount`, `pairCount`, `gridSize`), never behind a 1-5 tier.
@immutable
class ActivitySupport {
  const ActivitySupport({
    this.distractorCount = 2,
    this.scaffolding = ScaffoldingMode.errorless,
    this.tolerance,
    this.timeLimitSeconds,
    this.allowTapToSelect = true,
  });

  factory ActivitySupport.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivitySupport();
    }
    final JsonReader reader = JsonReader(json, 'support');
    return ActivitySupport(
      distractorCount: reader.optionalInt('distractorCount') ?? 2,
      scaffolding: ScaffoldingMode.values.firstWhere(
        (ScaffoldingMode mode) =>
            mode.name == (reader.optionalString('scaffolding') ?? 'errorless'),
        orElse: () => ScaffoldingMode.errorless,
      ),
      tolerance: reader.optionalDouble('tolerance'),
      timeLimitSeconds: reader.optionalInt('timeLimitSeconds'),
      allowTapToSelect: reader.optionalBool('allowTapToSelect') ?? true,
    );
  }

  final int distractorCount;
  final ScaffoldingMode scaffolding;
  final double? tolerance;
  final int? timeLimitSeconds;

  /// Always true in practice. Drag succeeds as little as 30% of the time for
  /// some school-age children, and WCAG 2.2 SC 2.5.7 requires a single-pointer
  /// alternative to every drag, so an engine cannot opt out of tap-to-select.
  final bool allowTapToSelect;
}

enum ScaffoldingMode {
  /// Wrong answers quietly return. No buzzer, no red X, no score loss.
  errorless,

  /// Explicit right/wrong. Reserved for mastery content, not first exposure.
  mastery,
}

/// Bounds for the between-node adaptive nudge.
@immutable
class ActivityAdaptation {
  const ActivityAdaptation({this.min, this.max, this.enabled = true});

  factory ActivityAdaptation.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ActivityAdaptation(enabled: false);
    }
    final JsonReader reader = JsonReader(json, 'adaptation');
    return ActivityAdaptation(
      min: reader.optionalInt('min'),
      max: reader.optionalInt('max'),
      enabled: reader.optionalBool('enabled') ?? true,
    );
  }

  final int? min;
  final int? max;
  final bool enabled;

  int clamp(int value) {
    int result = value;
    if (min != null && result < min!) {
      result = min!;
    }
    if (max != null && result > max!) {
      result = max!;
    }
    return result;
  }
}

/// Base class for whatever an engine parses its payload into.
@immutable
abstract class ActivityContent {
  const ActivityContent();
}

/// Typed reads over a decoded JSON map that fail with the path, not a
/// `_TypeError` fifty frames away from the file that caused it.
class JsonReader {
  const JsonReader(this._map, this._path);

  final Map<String, dynamic> _map;
  final String _path;

  Never _fail(String key, String message) =>
      throw ActivityContentException('$_path.$key', message);

  bool has(String key) => _map.containsKey(key);

  String requireString(String key) {
    final Object? value = _map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    _fail(key, 'expected a non-empty string, got ${value.runtimeType}');
  }

  String? optionalString(String key) {
    final Object? value = _map[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int requireInt(String key) {
    final Object? value = _map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    _fail(key, 'expected an integer, got ${value.runtimeType}');
  }

  int? optionalInt(String key) {
    final Object? value = _map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  double? optionalDouble(String key) {
    final Object? value = _map[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  bool? optionalBool(String key) {
    final Object? value = _map[key];
    return value is bool ? value : null;
  }

  List<String> requireStringList(String key) {
    final Object? value = _map[key];
    if (value is List) {
      return value.map((Object? item) => '$item').toList(growable: false);
    }
    _fail(key, 'expected a list of strings, got ${value.runtimeType}');
  }

  List<String> optionalStringList(String key) {
    final Object? value = _map[key];
    if (value is List) {
      return value.map((Object? item) => '$item').toList(growable: false);
    }
    return const <String>[];
  }

  List<int> optionalIntList(String key) {
    final Object? value = _map[key];
    if (value is List) {
      return value
          .whereType<num>()
          .map((num item) => item.toInt())
          .toList(growable: false);
    }
    return const <int>[];
  }

  Map<String, dynamic>? optionalMap(String key) {
    final Object? value = _map[key];
    if (value is Map) {
      return value.map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v));
    }
    return null;
  }

  List<Map<String, dynamic>> optionalMapList(String key) {
    final Object? value = _map[key];
    if (value is List) {
      return value
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> item) =>
              item.map((Object? k, Object? v) => MapEntry<String, dynamic>('$k', v)))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  JsonReader child(String key, Map<String, dynamic> map) =>
      JsonReader(map, '$_path.$key');
}
