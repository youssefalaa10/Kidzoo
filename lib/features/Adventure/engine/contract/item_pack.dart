import 'package:flutter/foundation.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

/// One thing a child can count, sort, match or find.
@immutable
class PackItem {
  const PackItem({
    required this.id,
    required this.imageAsset,
    required this.label,
    this.attributes = const <String, String>{},
  });

  factory PackItem.fromJson(Map<String, dynamic> json, String packId) {
    final JsonReader reader = JsonReader(json, 'packs/$packId.items');
    final Map<String, dynamic>? rawAttributes =
        reader.optionalMap('attributes');
    return PackItem(
      id: reader.requireString('id'),
      imageAsset: reader.requireString('image'),
      label: LocalizedText.fromJson(json['label'],
          debugPath: 'packs/$packId.items.label'),
      attributes: rawAttributes == null
          ? const <String, String>{}
          : rawAttributes.map(
              (String key, Object? value) =>
                  MapEntry<String, String>(key, '$value'),
            ),
    );
  }

  final String id;
  final String imageAsset;
  final LocalizedText label;

  /// Free-form tags such as `category: fruit`, `color: red`, `size: big`.
  ///
  /// Sorting reads these. They are strings rather than an enum so a new
  /// Adventure can sort by something nobody thought of, without a code change.
  final Map<String, String> attributes;

  String? attribute(String name) => attributes[name];
}

/// A reusable set of items, referenced by activities as `packs/animals`.
///
/// This is what lets one `counting` engine count animals in the Jungle, fruit
/// in the Market and stars in Space: the engine never names a domain, it just
/// resolves an `itemsRef`.
@immutable
class ItemPack {
  const ItemPack({required this.packId, required this.items});

  factory ItemPack.fromJson(Map<String, dynamic> json) {
    final JsonReader reader = JsonReader(json, 'pack');
    final String packId = reader.requireString('packId');
    final List<PackItem> items = reader
        .optionalMapList('items')
        .map((Map<String, dynamic> item) => PackItem.fromJson(item, packId))
        .toList(growable: false);
    if (items.isEmpty) {
      throw ActivityContentException(
          'packs/$packId.items', 'pack has no items');
    }
    return ItemPack(packId: packId, items: items);
  }

  final String packId;
  final List<PackItem> items;

  PackItem? findById(String id) {
    for (final PackItem item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  /// The items named by [ids], or every item when [ids] is empty.
  List<PackItem> select(List<String> ids, {required String debugPath}) {
    if (ids.isEmpty) {
      return items;
    }
    return ids.map((String id) {
      final PackItem? item = findById(id);
      if (item == null) {
        throw ActivityContentException(
          debugPath,
          'pack "$packId" has no item "$id"; it has '
          '${items.map((PackItem i) => i.id).toList()}',
        );
      }
      return item;
    }).toList(growable: false);
  }

  /// Items carrying [value] for [attribute].
  List<PackItem> whereAttribute(String attribute, String value) => items
      .where((PackItem item) => item.attribute(attribute) == value)
      .toList(growable: false);

  Set<String> valuesFor(String attribute) => items
      .map((PackItem item) => item.attribute(attribute))
      .whereType<String>()
      .toSet();
}

/// Everything an engine needs to turn `itemsRef` into real items.
abstract class ItemPackResolver {
  ItemPack require(String packRef, {required String debugPath});
}

/// Resolves from an in-memory map. The loader builds one of these once.
class MapItemPackResolver implements ItemPackResolver {
  const MapItemPackResolver(this._packs);

  final Map<String, ItemPack> _packs;

  @override
  ItemPack require(String packRef, {required String debugPath}) {
    // Content writes `packs/animals`; the map is keyed by `animals`.
    final String packId =
        packRef.startsWith('packs/') ? packRef.substring(6) : packRef;
    final ItemPack? pack = _packs[packId];
    if (pack == null) {
      throw ActivityContentException(
        debugPath,
        'no pack "$packId"; known packs: ${(_packs.keys.toList()..sort())}',
      );
    }
    return pack;
  }
}
