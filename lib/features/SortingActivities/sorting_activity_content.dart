import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kidzo/features/Adventure/engine/contract/activity_spec.dart';
import 'package:kidzo/features/Adventure/engine/contract/item_pack.dart';
import 'package:kidzo/features/Adventure/engine/support/localized_text.dart';

enum SortingActivityKind {
  teeth('tooth_food_sorting', 'toothFoodSorting'),
  weather('weather_sorting', 'weatherSorting'),
  laundry('laundry_sorting', 'laundrySorting');

  const SortingActivityKind(this.activityId, this.titleKey);
  final String activityId;
  final String titleKey;
}

class SortingDestination {
  const SortingDestination(
      {required this.id,
      required this.image,
      required this.label,
      required this.feedback});
  final String id;
  final String image;
  final LocalizedText label;
  final LocalizedText feedback;
}

/// Shared data, independently loaded and owned by each game's route.
class SortingActivityContent {
  SortingActivityContent(
      {required this.kind,
      required this.items,
      required this.destinations,
      required this.intro,
      required this.prompt,
      required this.retry,
      required this.complete}) {
    if (items.length != 10 ||
        items.map((i) => i.id).toSet().length != 10 ||
        destinations.length != 2 ||
        destinations[0].id == destinations[1].id ||
        items.any((i) =>
            !destinations.any((b) => b.id == i.attribute('destination')))) {
      throw const FormatException(
          'A worksheet needs ten unique items and two valid destinations.');
    }
  }

  factory SortingActivityContent.fromJson(SortingActivityKind kind,
      Map<String, dynamic> json, Map<String, dynamic> packJson) {
    final spec = ActivitySpec.fromJson(json);
    final pack = ItemPack.fromJson(packJson);
    final worksheet = json['worksheet'] as Map<String, dynamic>;
    final correct = worksheet['correct'] as Map<String, dynamic>;
    final bins =
        (spec.payload['bins'] as List<dynamic>).cast<Map<String, dynamic>>();
    return SortingActivityContent(
        kind: kind,
        items: List.unmodifiable(pack.items),
        destinations: List.unmodifiable(bins.map((bin) => SortingDestination(
            id: bin['id'] as String,
            image: bin['image'] as String,
            label: LocalizedText.fromJson(bin['label']),
            feedback: LocalizedText.fromJson(correct[bin['id']])))),
        intro: spec.narration.prompt,
        prompt: LocalizedText.fromJson(worksheet['prompt']),
        retry: LocalizedText.fromJson(worksheet['retry']),
        complete: spec.narration.success);
  }

  static Future<SortingActivityContent> load(SortingActivityKind kind) async {
    final files = await Future.wait([
      rootBundle
          .loadString('assets/adventures/activities/helpers_${kind.name}.json'),
      rootBundle
          .loadString('assets/adventures/packs/helpers_${kind.name}.json'),
    ]);
    return SortingActivityContent.fromJson(
        kind,
        jsonDecode(files[0]) as Map<String, dynamic>,
        jsonDecode(files[1]) as Map<String, dynamic>);
  }

  final SortingActivityKind kind;
  final List<PackItem> items;
  final List<SortingDestination> destinations;
  final LocalizedText intro;
  final LocalizedText prompt;
  final LocalizedText retry;
  final LocalizedText complete;

  String effect(String cue) => cue == 'retry'
      ? 'audio/sorting_return.wav'
      : 'audio/sorting_${kind.name}_$cue.wav';
  Iterable<String> get images => [
        ...items.map((i) => i.imageAsset),
        ...destinations.map((b) => b.image),
      ];
}
