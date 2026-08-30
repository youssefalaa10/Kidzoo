import 'package:equatable/equatable.dart';

import '../../../core/localization/app_localizations.dart';

enum FoodType {
  fruit,
  vegetable,
}

class FoodItem extends Equatable {
  const FoodItem({
    required this.id,
    required this.imageAsset,
    required this.type,
    required this.getLocalizedName,
  });

  final String id;
  final String imageAsset;
  final FoodType type;
  final String Function(AppLocalizations) getLocalizedName;

  @override
  List<Object?> get props => [id];
}

class SorterGameRoundData extends Equatable {
  const SorterGameRoundData({
    required this.choices,
    required this.targetFood,
  });

  final List<FoodItem> choices;
  final FoodItem targetFood;

  /// The basket the target belongs in. Derived rather than stored so the two
  /// can never disagree.
  FoodType get targetBasket => targetFood.type;

  String getPromptText(AppLocalizations l10n) {
    final foodName = targetFood.getLocalizedName(l10n);
    final basketName = targetFood.type == FoodType.fruit
        ? l10n.fruitsBasket
        : l10n.vegetablesBasket;
    return l10n.putItemInBasket(foodName, basketName);
  }

  @override
  List<Object?> get props => [choices, targetFood];
}
