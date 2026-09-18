import 'package:kidzo/features/Adventure/engine/contract/activity_engine.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_engine_descriptor.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';

/// Thrown when the set of registered engines is itself wrong — a duplicate id,
/// or two reusable engines claiming the same capability.
class EngineRegistryException implements Exception {
  EngineRegistryException(this.message);
  final String message;

  @override
  String toString() => 'EngineRegistryException: $message';
}

/// The engines available to content.
///
/// Injected, not static. The old `GameSequence.createGameForLevel` was a closed
/// `switch` that had to be edited to add anything; this is a list that a host,
/// a test, or a future Adventure can construct differently without touching
/// global state.
class ActivityEngineRegistry {
  ActivityEngineRegistry(List<ActivityEngine<ActivityContent>> engines)
      : _byId = <String, ActivityEngine<ActivityContent>>{} {
    for (final ActivityEngine<ActivityContent> engine in engines) {
      final String id = engine.descriptor.engineId;
      if (_byId.containsKey(id)) {
        throw EngineRegistryException('duplicate engineId "$id"');
      }
      _byId[id] = engine;
    }
    _assertCapabilitiesAreDistinct(engines);
  }

  final Map<String, ActivityEngine<ActivityContent>> _byId;

  Iterable<ActivityEngine<ActivityContent>> get engines => _byId.values;

  Iterable<String> get engineIds => _byId.keys;

  bool contains(String engineId) => _byId.containsKey(engineId);

  ActivityEngine<ActivityContent> require(String engineId) {
    final ActivityEngine<ActivityContent>? engine = _byId[engineId];
    if (engine == null) {
      throw EngineRegistryException(
        'no engine registered for "$engineId"; known engines: '
        '${_byId.keys.toList()..sort()}',
      );
    }
    return engine;
  }

  ActivityEngine<ActivityContent>? find(String engineId) => _byId[engineId];

  /// The teeth of the reuse ladder.
  ///
  /// Two *reusable* engines sharing a (learningDomains, interactionModes) pair
  /// means one of them should have been content on the other. Catching that
  /// mechanically matters more than usual here, because the likeliest way this
  /// architecture fails is a solo developer cheerfully building ten engines
  /// that are four engines wearing different names.
  ///
  /// Legacy adapters and bespoke engines are exempt: an adapter's capability is
  /// dictated by the game it wraps, not chosen.
  static void _assertCapabilitiesAreDistinct(
    List<ActivityEngine<ActivityContent>> engines,
  ) {
    final Map<String, String> ownerOfCapability = <String, String>{};
    for (final ActivityEngine<ActivityContent> engine in engines) {
      final ActivityEngineDescriptor descriptor = engine.descriptor;
      if (descriptor.kind != EngineKind.reusable) {
        continue;
      }
      final String key = descriptor.capabilityKey;
      final String? existing = ownerOfCapability[key];
      if (existing != null) {
        throw EngineRegistryException(
          'duplicate capability "$key" claimed by "$existing" and '
          '"${descriptor.engineId}" — extend "$existing" with content instead '
          'of adding a second engine for the same job',
        );
      }
      ownerOfCapability[key] = descriptor.engineId;
    }
  }
}
