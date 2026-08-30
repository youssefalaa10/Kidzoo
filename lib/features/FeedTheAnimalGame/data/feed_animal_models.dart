import 'package:equatable/equatable.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';

enum PromptType {
  feedAnimal,
  whatDoesAnimalEat,
}

/// Broad food family, used to pick distractors that are obviously wrong in the
/// easy rounds and less obviously wrong later on.
enum FoodKind { plant, meat }

class FeedItem extends Equatable {
  const FeedItem({
    required this.id,
    required this.imageAsset,
    required this.kind,
    required this.getLocalizedName,
  });

  final String id;
  final String imageAsset;
  final FoodKind kind;
  final String Function(AppLocalizations) getLocalizedName;

  @override
  List<Object?> get props => [id];
}

class AnimalItem extends Equatable {
  const AnimalItem({
    required this.id,
    required this.imageAsset,
    required this.audioAsset,
    required this.backgroundType,
    required this.targetFoodId,
    required this.getLocalizedName,
    this.alsoEats = const <String>{},
  });

  final String id;
  final String imageAsset;
  final String audioAsset;
  final BackgroundType backgroundType;

  /// The one food the round asks for.
  final String targetFoodId;

  /// Other foods this animal would plausibly eat.
  ///
  /// These are excluded from the distractor pool: offering a cow both grass and
  /// corn and then calling corn "wrong" teaches the child nothing.
  final Set<String> alsoEats;

  final String Function(AppLocalizations) getLocalizedName;

  bool wouldEat(String foodId) =>
      foodId == targetFoodId || alsoEats.contains(foodId);

  @override
  List<Object?> get props => [id];
}

class GameRoundData extends Equatable {
  const GameRoundData({
    required this.animal,
    required this.targetFood,
    required this.choices,
    this.promptType = PromptType.feedAnimal,
  });

  final AnimalItem animal;
  final FeedItem targetFood;
  final List<FeedItem> choices;
  final PromptType promptType;

  String getPromptText(AppLocalizations l10n) {
    final animalName = animal.getLocalizedName(l10n);
    switch (promptType) {
      case PromptType.feedAnimal:
        return l10n.promptFeedAnimal(animalName);
      case PromptType.whatDoesAnimalEat:
        return l10n.promptWhatDoesAnimalEat(animalName);
    }
  }

  @override
  List<Object?> get props => [animal, targetFood, choices, promptType];
}
