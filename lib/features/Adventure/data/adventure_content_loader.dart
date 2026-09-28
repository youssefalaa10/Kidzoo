import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/story/models/story_models.dart';

/// Where content bytes come from.
///
/// An interface so the same loader serves the running app (asset bundle) and
/// the content test (disk). The content test is the highest-value test in this
/// feature and it must not need a widget binding to run.
abstract class AdventureContentSource {
  Future<String> readString(String relativePath);
}

class AssetAdventureContentSource implements AdventureContentSource {
  const AssetAdventureContentSource({this.rootPath = 'assets/adventures'});
  final String rootPath;

  @override
  Future<String> readString(String relativePath) =>
      rootBundle.loadString('$rootPath/$relativePath');
}

/// Everything under `assets/adventures/`, parsed and cross-checked.
@immutable
class AdventureContentBundle {
  const AdventureContentBundle({
    required this.arcs,
    required this.adventures,
    required this.activities,
    required this.packs,
  });

  final Map<String, StoryArc> arcs;
  final Map<String, Adventure> adventures;
  final Map<String, ActivitySpec> activities;
  final Map<String, ItemPack> packs;

  ItemPackResolver get packResolver => MapItemPackResolver(packs);

  StoryArc get primaryArc => arcs.values.first;

  Adventure requireAdventure(String adventureId) {
    final Adventure? adventure = adventures[adventureId];
    if (adventure == null) {
      throw ActivityContentException(
        'adventures/$adventureId',
        'no such adventure; known: ${(adventures.keys.toList()..sort())}',
      );
    }
    return adventure;
  }

  ActivitySpec requireActivity(String activityRef) {
    final String id = activityRef.startsWith('activities/')
        ? activityRef.substring('activities/'.length)
        : activityRef;
    final ActivitySpec? spec = activities[id];
    if (spec == null) {
      throw ActivityContentException(
        'activities/$id',
        'no such activity; known: ${(activities.keys.toList()..sort())}',
      );
    }
    return spec;
  }
}

/// Reads the five fixed content directories.
///
/// The manifest is the index rather than a directory listing, because asset
/// bundles cannot be enumerated at runtime. A test asserts the manifest and the
/// disk agree in **both** directions, which is what stops a file being added and
/// silently never shipping.
class AdventureContentLoader {
  const AdventureContentLoader(this.source);

  final AdventureContentSource source;

  Future<AdventureContentBundle> load() async {
    final Map<String, dynamic> manifest = await _readJson('manifest.json');
    final JsonReader reader = JsonReader(manifest, 'manifest.json');

    final Map<String, ItemPack> packs = <String, ItemPack>{};
    for (final String name in reader.optionalStringList('packs')) {
      final Map<String, dynamic> json = await _readJson('packs/$name.json');
      final ItemPack pack = ItemPack.fromJson(json);
      packs[pack.packId] = pack;
    }

    final Map<String, ActivitySpec> activities = <String, ActivitySpec>{};
    for (final String name in reader.optionalStringList('activities')) {
      final Map<String, dynamic> json =
          await _readJson('activities/$name.json');
      activities[name] =
          ActivitySpec.fromJson(json, sourcePath: 'activities/$name.json');
    }

    final Map<String, Adventure> adventures = <String, Adventure>{};
    for (final String name in reader.optionalStringList('adventures')) {
      final Map<String, dynamic> json =
          await _readJson('adventures/$name.json');
      final Adventure adventure =
          Adventure.fromJson(json, 'adventures/$name.json');
      adventures[adventure.adventureId] = adventure;
    }

    final Map<String, StoryArc> arcs = <String, StoryArc>{};
    for (final String name in reader.optionalStringList('arcs')) {
      final Map<String, dynamic> json = await _readJson('arcs/$name.json');
      final StoryArc arc = StoryArc.fromJson(json, 'arcs/$name.json');
      arcs[arc.arcId] = arc;
    }

    if (arcs.isEmpty) {
      throw ActivityContentException('manifest.json.arcs', 'no arcs declared');
    }

    return AdventureContentBundle(
      arcs: arcs,
      adventures: adventures,
      activities: activities,
      packs: packs,
    );
  }

  Future<Map<String, dynamic>> _readJson(String relativePath) async {
    final String raw = await source.readString(relativePath);
    final Object? decoded = json.decode(raw);
    if (decoded is! Map) {
      throw ActivityContentException(
          relativePath, 'expected a JSON object at the top level');
    }
    return decoded.map((Object? key, Object? value) =>
        MapEntry<String, dynamic>('$key', value));
  }
}
