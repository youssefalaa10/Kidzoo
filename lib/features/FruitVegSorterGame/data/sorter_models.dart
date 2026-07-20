
import '../../../core/localization/app_localizations.dart';

enum FoodType {
  fruit,
  vegetable,
}

class FoodItem {

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
}

class SorterGameRoundData {

  const SorterGameRoundData({
    required this.choices,
    required this.targetFood,
  });
  final List<FoodItem> choices;
  final FoodItem targetFood;

  String getPromptText(AppLocalizations l10n) {
    final foodName = targetFood.getLocalizedName(l10n);
    final basketName = targetFood.type == FoodType.fruit ? l10n.fruitsBasket : l10n.vegetablesBasket;
    return l10n.putItemInBasket(foodName, basketName);
  }
}
