import 'dart:math';

import '../../../core/services/background_resolver.dart';
import 'feed_animal_models.dart';

class FeedAnimalData {
  static final List<FeedItem> allFoods = [
    FeedItem(
      id: 'banana',
      imageAsset: 'assets/gen/images/fruits/banana.png',
      kind: FoodKind.plant,
      getLocalizedName: (l10n) => l10n.banana,
    ),
    FeedItem(
      id: 'carrot',
      imageAsset: 'assets/gen/images/vegetables/carrot.png',
      kind: FoodKind.plant,
      getLocalizedName: (l10n) => l10n.carrot,
    ),
    FeedItem(
      id: 'watermelon',
      imageAsset: 'assets/gen/images/fruits/watermelon.png',
      kind: FoodKind.plant,
      getLocalizedName: (l10n) => l10n.watermelon,
    ),
    FeedItem(
      id: 'bamboo',
      imageAsset: 'assets/gen/images/feed/bamboo.png',
      kind: FoodKind.plant,
      getLocalizedName: (l10n) => l10n.bamboo,
    ),
    FeedItem(
      id: 'corn',
      imageAsset: 'assets/gen/images/vegetables/corn.png',
      kind: FoodKind.plant,
      getLocalizedName: (l10n) => l10n.corn,
    ),
    FeedItem(
      id: 'grass',
      imageAsset: 'assets/gen/images/feed/grees.png',
      kind: FoodKind.plant,
      getLocalizedName: (l10n) => l10n.grass,
    ),
    FeedItem(
      id: 'fish',
      imageAsset: 'assets/gen/images/animal/fish.png',
      kind: FoodKind.meat,
      getLocalizedName: (l10n) => l10n.fish,
    ),
    FeedItem(
      id: 'meat',
      imageAsset: 'assets/gen/images/feed/meat.png',
      kind: FoodKind.meat,
      getLocalizedName: (l10n) => l10n.meat,
    ),
  ];

  static final List<AnimalItem> allAnimals = [
    AnimalItem(
      id: 'monkey',
      imageAsset: 'assets/gen/images/animal/monkey.png',
      audioAsset: 'assets/audio/animals-sounds/monkey-sound.mp3',
      backgroundType: BackgroundType.jungle,
      targetFoodId: 'banana',
      alsoEats: const {'watermelon'},
      getLocalizedName: (l10n) => l10n.monkey,
    ),
    AnimalItem(
      id: 'rabbit',
      imageAsset: 'assets/gen/images/animal/rabbit.png',
      audioAsset: 'assets/audio/animals-sounds/cute squeak.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'carrot',
      alsoEats: const {'grass'},
      getLocalizedName: (l10n) => l10n.rabbit,
    ),
    AnimalItem(
      id: 'elephant',
      imageAsset: 'assets/gen/images/animal/elephant.png',
      audioAsset: 'assets/audio/animals-sounds/elephant.mp3',
      backgroundType: BackgroundType.jungle,
      targetFoodId: 'watermelon',
      alsoEats: const {'grass', 'bamboo', 'banana'},
      getLocalizedName: (l10n) => l10n.elephant,
    ),
    AnimalItem(
      id: 'panda',
      imageAsset: 'assets/gen/images/animal/panda.png',
      audioAsset: 'assets/audio/animals-sounds/cute squeak.mp3',
      backgroundType: BackgroundType.jungle,
      targetFoodId: 'bamboo',
      alsoEats: const {'grass'},
      getLocalizedName: (l10n) => l10n.panda,
    ),
    AnimalItem(
      id: 'horse',
      imageAsset: 'assets/gen/images/animal/horse.png',
      audioAsset: 'assets/audio/animals-sounds/horse_neigh.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'corn',
      alsoEats: const {'grass', 'carrot'},
      getLocalizedName: (l10n) => l10n.horse,
    ),
    AnimalItem(
      id: 'cow',
      imageAsset: 'assets/gen/images/animal/cow.png',
      audioAsset: 'assets/audio/animals-sounds/cow_mooing.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'grass',
      alsoEats: const {'corn'},
      getLocalizedName: (l10n) => l10n.cow,
    ),
    AnimalItem(
      id: 'sheep',
      imageAsset: 'assets/gen/images/animal/sheep.png',
      audioAsset: 'assets/audio/animals-sounds/sheep_baa.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'grass',
      alsoEats: const {'corn'},
      getLocalizedName: (l10n) => l10n.sheep,
    ),
    AnimalItem(
      id: 'cat',
      imageAsset: 'assets/gen/images/animal/cat.png',
      audioAsset: 'assets/audio/animals-sounds/cat_meow.wav',
      backgroundType: BackgroundType.game,
      targetFoodId: 'fish',
      alsoEats: const {'meat'},
      getLocalizedName: (l10n) => l10n.cat,
    ),
    AnimalItem(
      id: 'dog',
      imageAsset: 'assets/gen/images/animal/dog.png',
      audioAsset: 'assets/audio/animals-sounds/dog_barking.wav',
      backgroundType: BackgroundType.game,
      targetFoodId: 'meat',
      alsoEats: const {'fish'},
      getLocalizedName: (l10n) => l10n.dog,
    ),
    AnimalItem(
      id: 'lion',
      imageAsset: 'assets/gen/images/animal/lion.png',
      audioAsset: 'assets/audio/animals-sounds/lion_roar.wav',
      backgroundType: BackgroundType.jungle,
      targetFoodId: 'meat',
      alsoEats: const {'fish'},
      getLocalizedName: (l10n) => l10n.lion,
    ),
  ];

  /// Foods offered alongside the answer.
  ///
  /// Two rules the previous random pick did not honour:
  ///  * a food the animal would plausibly eat is never a "wrong" answer -
  ///    showing a cow grass and corn and calling corn incorrect teaches nothing;
  ///  * early rounds contrast the food families (a lion offered bamboo) and
  ///    later rounds narrow the gap, so difficulty ramps with something more
  ///    meaningful than the number of cards.
  static List<FeedItem> buildDistractors({
    required AnimalItem animal,
    required FeedItem targetFood,
    required int count,
    required double progress,
    required Random random,
  }) {
    final pool = allFoods.where((f) => !animal.wouldEat(f.id)).toList()
      ..shuffle(random);

    final contrasting = pool.where((f) => f.kind != targetFood.kind).toList();
    final similar = pool.where((f) => f.kind == targetFood.kind).toList();
    final ordered = progress <= 0.4
        ? [...contrasting, ...similar]
        : [...similar, ...contrasting];

    return ordered.take(count).toList();
  }

  /// Number of cards on the tray for a given round.
  static int choiceCountFor(double progress) {
    if (progress <= 0.3) return 3;
    if (progress <= 0.7) return 4;
    return 5;
  }
}
