import 'package:flutter/foundation.dart';

/// How an engine came to exist, which decides how much scrutiny it gets.
enum EngineKind {
  /// Content-driven and domain-agnostic. The default and the goal.
  reusable,

  /// Wraps a pre-existing game screen so a story node can use it.
  adaptedLegacy,

  /// One-off. Lives in `engine/bespoke/` and needs an allowlist entry.
  bespoke,
}

/// What an engine teaches. Used with [InteractionMode] to detect two engines
/// crowding the same space, which is the first symptom of over-generalising.
enum LearningDomain {
  counting,
  classification,
  matching,
  patterning,
  vocabulary,
  visualSearch,
  memory,
  spatialReasoning,
  arithmetic,
  literacy,
}

/// How the child acts. The other half of the uniqueness key.
enum InteractionMode {
  chooseOne,
  dragToTarget,
  orderSequence,
  stateQuantity,
  tapInScene,
  traceStroke,
  buildText,
}

/// One gameplay parameter an engine accepts from content.
///
/// These carry the engine's **own** names — `targetCount`, `pairCount`,
/// `gridSize`, `maxNumber`, `clueCount` — because the story author configures
/// the experience, not an abstract Easy/Medium/Hard tier. A tier is a lossy
/// encoding of the thing the author actually means, and it cannot express
/// orderings that matter (for counting, the *arrangement* ladder from dice to
/// random is as important as the count).
@immutable
class ContentParameter {
  const ContentParameter({
    required this.name,
    required this.type,
    this.minValue,
    this.maxValue,
    this.allowedValues,
    this.isRequired = false,
    this.description = '',
  });

  const ContentParameter.integer(
    this.name, {
    this.minValue,
    this.maxValue,
    this.isRequired = false,
    this.description = '',
  })  : type = ContentParameterType.integer,
        allowedValues = null;

  const ContentParameter.enumeration(
    this.name,
    this.allowedValues, {
    this.isRequired = false,
    this.description = '',
  })  : type = ContentParameterType.enumeration,
        minValue = null,
        maxValue = null;

  const ContentParameter.text(
    this.name, {
    this.isRequired = false,
    this.description = '',
  })  : type = ContentParameterType.text,
        minValue = null,
        maxValue = null,
        allowedValues = null;

  const ContentParameter.list(
    this.name, {
    this.isRequired = false,
    this.description = '',
  })  : type = ContentParameterType.list,
        minValue = null,
        maxValue = null,
        allowedValues = null;

  const ContentParameter.flag(
    this.name, {
    this.description = '',
  })  : type = ContentParameterType.flag,
        minValue = null,
        maxValue = null,
        allowedValues = null,
        isRequired = false;

  final String name;
  final ContentParameterType type;
  final int? minValue;
  final int? maxValue;
  final List<String>? allowedValues;
  final bool isRequired;
  final String description;
}

enum ContentParameterType { integer, enumeration, text, list, flag }

/// The engine's self-description: what it teaches, what it accepts, and which
/// locales it can honestly be authored in.
@immutable
class ActivityEngineDescriptor {
  const ActivityEngineDescriptor({
    required this.engineId,
    required this.kind,
    required this.learningDomains,
    required this.interactionModes,
    required this.contentParameters,
    required this.adaptationAxis,
    required this.supportedLocales,
    this.schemaVersion = 1,
    this.justification = '',
  });

  final String engineId;
  final EngineKind kind;
  final Set<LearningDomain> learningDomains;
  final Set<InteractionMode> interactionModes;
  final List<ContentParameter> contentParameters;

  /// The single parameter the between-node adaptive nudge steps along.
  /// Null means this engine does not adapt.
  final String? adaptationAxis;

  /// Locales this engine can be **authored** in, not locales the UI supports.
  ///
  /// The distinction is the whole point. Kidzo's UI is bilingual, which says
  /// nothing about whether an activity can be written in Arabic. A literacy
  /// engine needs ~110 pre-shaped glyphs, connected contextual forms (كتب is
  /// not ك + ت + ب), i'jam dots validated as taps rather than traces, a Naskh
  /// face and full harakat — none of which exist yet. Such engines declare
  /// `{'en'}`, and the content test refuses any Arabic node authored against
  /// them, so a child never meets English content inside an Arabic chapter.
  final Set<String> supportedLocales;

  final int schemaVersion;

  /// Required non-empty when [kind] is [EngineKind.bespoke].
  final String justification;

  /// The key the registry uses to detect two engines crowding one space.
  String get capabilityKey {
    final List<String> domains =
        learningDomains.map((LearningDomain d) => d.name).toList()..sort();
    final List<String> modes =
        interactionModes.map((InteractionMode m) => m.name).toList()..sort();
    return '${domains.join(',')}|${modes.join(',')}';
  }

  ContentParameter? parameterNamed(String name) {
    for (final ContentParameter parameter in contentParameters) {
      if (parameter.name == name) {
        return parameter;
      }
    }
    return null;
  }
}
