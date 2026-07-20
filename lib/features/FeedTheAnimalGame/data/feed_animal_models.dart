import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/background_resolver.dart';

enum PromptType {
  feedAnimal,
  whatDoesAnimalEat,
}

class FeedItem {

  const FeedItem({
    required this.id,
    required this.imageAsset,
    required this.getLocalizedName,
  });
  final String id;
  final String imageAsset;
  final String Function(AppLocalizations) getLocalizedName;
}

class AnimalItem {

  const AnimalItem({
    required this.id,
    required this.imageAsset,
    required this.audioAsset,
    required this.backgroundType,
    required this.targetFoodId,
    required this.getLocalizedName,
  });
  final String id;
  final String imageAsset;
  final String audioAsset;
  final BackgroundType backgroundType;
  final String targetFoodId;
  final String Function(AppLocalizations) getLocalizedName;
}

class GameRoundData {

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
}
