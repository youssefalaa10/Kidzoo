import '../../../core/localization/app_localizations.dart';
import 'sorter_models.dart';

class SorterGameData {
  static final List<FoodItem> allFruits = [
    FoodItem(
      id: 'apple',
      imageAsset: 'assets/gen/images/fruits/apple.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.apple,
    ),
    FoodItem(
      id: 'banana',
      imageAsset: 'assets/gen/images/fruits/banana.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.banana,
    ),
    FoodItem(
      id: 'cherries',
      imageAsset: 'assets/gen/images/fruits/cherries.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.cherries,
    ),
    FoodItem(
      id: 'grapes',
      imageAsset: 'assets/gen/images/fruits/grapes.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.grapes,
    ),
    FoodItem(
      id: 'mango',
      imageAsset: 'assets/gen/images/fruits/mango.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.mango,
    ),
    FoodItem(
      id: 'orange',
      imageAsset: 'assets/gen/images/fruits/orange.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.orangeFruit,
    ),
    FoodItem(
      id: 'pineapple',
      imageAsset: 'assets/gen/images/fruits/pineapple.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.pineapple,
    ),
    FoodItem(
      id: 'watermelon',
      imageAsset: 'assets/gen/images/fruits/watermelon.png',
      type: FoodType.fruit,
      getLocalizedName: (AppLocalizations l10n) => l10n.watermelon,
    ),
  ];

  static final List<FoodItem> allVegetables = [
    FoodItem(
      id: 'cabbage',
      imageAsset: 'assets/gen/images/vegetables/cabbage.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.cabbage,
    ),
    FoodItem(
      id: 'carrot',
      imageAsset: 'assets/gen/images/vegetables/carrot.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.carrot,
    ),
    FoodItem(
      id: 'cucumber',
      imageAsset: 'assets/gen/images/vegetables/cucumber.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.cucumber,
    ),
    FoodItem(
      id: 'eggplant',
      imageAsset: 'assets/gen/images/vegetables/eggplant.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.eggplant,
    ),
    FoodItem(
      id: 'onion',
      imageAsset: 'assets/gen/images/vegetables/onion.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.onion,
    ),
    FoodItem(
      id: 'potato',
      imageAsset: 'assets/gen/images/vegetables/potato.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.potato,
    ),
    FoodItem(
      id: 'redPepper',
      imageAsset: 'assets/gen/images/vegetables/red_pepper.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.redPepper,
    ),
    FoodItem(
      id: 'tomato',
      imageAsset: 'assets/gen/images/vegetables/tomato.png',
      type: FoodType.vegetable,
      getLocalizedName: (AppLocalizations l10n) => l10n.tomato,
    ),
  ];

  static List<FoodItem> get allFoods => [...allFruits, ...allVegetables];
}
