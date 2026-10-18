import 'dart:math';

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

  /// Builds a round that actually tests the fruit/vegetable distinction.
  ///
  /// The previous logic took N random foods from the combined list, so a round
  /// could contain only fruits - the vegetable basket was then obviously wrong
  /// and the child could succeed without looking at the picture. Every round
  /// now contains at least one of each category.
  ///
  /// [avoidTargets] holds recently requested foods so the same item is not
  /// asked for twice in a row.
  static SorterGameRoundData buildRound({
    required int round,
    required int totalRounds,
    required Random random,
    Set<String> avoidTargets = const {},
  }) {
    final progress = totalRounds <= 0 ? 1.0 : round / totalRounds;
    final numChoices = progress <= 0.3
        ? 2
        : progress <= 0.6
            ? 3
            : progress <= 0.8
                ? 4
                : 5;

    final fruits = List<FoodItem>.from(allFruits)..shuffle(random);
    final vegetables = List<FoodItem>.from(allVegetables)..shuffle(random);

    final choices = <FoodItem>[fruits.removeAt(0), vegetables.removeAt(0)];
    final filler = [...fruits, ...vegetables]..shuffle(random);
    while (choices.length < numChoices && filler.isNotEmpty) {
      choices.add(filler.removeAt(0));
    }
    choices.shuffle(random);

    final fresh = choices.where((f) => !avoidTargets.contains(f.id)).toList();
    final pool = fresh.isNotEmpty ? fresh : choices;
    final targetFood = pool[random.nextInt(pool.length)];

    return SorterGameRoundData(choices: choices, targetFood: targetFood);
  }
}
