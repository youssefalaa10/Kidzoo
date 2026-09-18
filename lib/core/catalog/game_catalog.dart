import 'package:kidzo/core/catalog/game_descriptor.dart';
import 'package:kidzo/core/catalog/game_surface.dart';

/// The single registry of playable activities.
///
/// Replaces three disconnected registries: the two hand-written option lists in
/// `app_category_options.dart` and the `GameType` switch in
/// `GameSequenceItem.create`. It is an ordinary value, constructed and passed
/// in — deliberately not a singleton, so tests and Adventure Mode can supply
/// their own without mutating global state.
class GameCatalog {
  GameCatalog(List<GameDescriptor> descriptors)
      : _descriptors = List<GameDescriptor>.unmodifiable(descriptors) {
    assert(
      _descriptors.map((descriptor) => descriptor.activityId).toSet().length ==
          _descriptors.length,
      'duplicate activityId in the catalog: activityId doubles as '
      'GameScores.gameKey, so a duplicate would merge two games score history',
    );
  }

  final List<GameDescriptor> _descriptors;

  List<GameDescriptor> get all => _descriptors;

  /// The entries belonging to one grid, in catalog order.
  List<GameDescriptor> forSurface(GameSurface surface) => _descriptors
      .where((descriptor) => descriptor.surface == surface)
      .toList(growable: false);

  GameDescriptor? findByActivityId(String activityId) {
    for (final GameDescriptor descriptor in _descriptors) {
      if (descriptor.activityId == activityId) {
        return descriptor;
      }
    }
    return null;
  }
}
