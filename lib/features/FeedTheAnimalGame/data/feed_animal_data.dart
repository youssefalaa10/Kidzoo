import '../../../core/services/background_resolver.dart';
import 'feed_animal_models.dart';

class FeedAnimalData {
  static final List<FeedItem> allFoods = [
    FeedItem(
      id: 'banana',
      imageAsset: 'assets/gen/images/fruits/banana.png',
      getLocalizedName: (l10n) => l10n.banana,
    ),
    FeedItem(
      id: 'carrot',
      imageAsset: 'assets/gen/images/vegetables/carrot.png',
      getLocalizedName: (l10n) => l10n.carrot,
    ),
    FeedItem(
      id: 'watermelon',
      imageAsset: 'assets/gen/images/fruits/watermelon.png',
      getLocalizedName: (l10n) => l10n.watermelon,
    ),
    FeedItem(
      id: 'bamboo',
      imageAsset: 'assets/gen/images/feed/bamboo.png',
      getLocalizedName: (l10n) => l10n.bamboo,
    ),
    FeedItem(
      id: 'corn',
      imageAsset: 'assets/gen/images/vegetables/corn.png',
      getLocalizedName: (l10n) => l10n.corn,
    ),
    FeedItem(
      id: 'grass',
      imageAsset: 'assets/gen/images/feed/grees.png',
      getLocalizedName: (l10n) => l10n.grass,
    ),
    FeedItem(
      id: 'fish',
      imageAsset: 'assets/gen/images/animal/fish.png',
      getLocalizedName: (l10n) => l10n.fish,
    ),
    FeedItem(
      id: 'meat',
      imageAsset: 'assets/gen/images/feed/meat.png',
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
      getLocalizedName: (l10n) => l10n.monkey,
    ),
    AnimalItem(
      id: 'rabbit',
      imageAsset: 'assets/gen/images/animal/rabbit.png',
      audioAsset: 'assets/audio/animals-sounds/cute squeak.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'carrot',
      getLocalizedName: (l10n) => l10n.rabbit,
    ),
    AnimalItem(
      id: 'elephant',
      imageAsset: 'assets/gen/images/animal/elephant.png',
      audioAsset: 'assets/audio/animals-sounds/elephant.mp3',
      backgroundType: BackgroundType.jungle,
      targetFoodId: 'watermelon',
      getLocalizedName: (l10n) => l10n.elephant,
    ),
    AnimalItem(
      id: 'panda',
      imageAsset: 'assets/gen/images/animal/panda.png',
      audioAsset: 'assets/audio/animals-sounds/cute squeak.mp3',
      backgroundType: BackgroundType.education,
      targetFoodId: 'bamboo',
      getLocalizedName: (l10n) => l10n.panda,
    ),
    AnimalItem(
      id: 'horse',
      imageAsset: 'assets/gen/images/animal/horse.png',
      audioAsset: 'assets/audio/animals-sounds/horse_neigh.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'corn',
      getLocalizedName: (l10n) => l10n.horse,
    ),
    AnimalItem(
      id: 'cow',
      imageAsset: 'assets/gen/images/animal/cow.png',
      audioAsset: 'assets/audio/animals-sounds/cow_mooing.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'grass',
      getLocalizedName: (l10n) => l10n.cow,
    ),
    AnimalItem(
      id: 'sheep',
      imageAsset: 'assets/gen/images/animal/sheep.png',
      audioAsset: 'assets/audio/animals-sounds/sheep_baa.mp3',
      backgroundType: BackgroundType.game,
      targetFoodId: 'grass',
      getLocalizedName: (l10n) => l10n.sheep,
    ),
    AnimalItem(
      id: 'cat',
      imageAsset: 'assets/gen/images/animal/cat.png',
      audioAsset: 'assets/audio/animals-sounds/cat_meow.wav',
      backgroundType: BackgroundType.game,
      targetFoodId: 'fish',
      getLocalizedName: (l10n) => l10n.cat,
    ),
    AnimalItem(
      id: 'dog',
      imageAsset: 'assets/gen/images/animal/dog.png',
      audioAsset: 'assets/audio/animals-sounds/dog_barking.wav',
      backgroundType: BackgroundType.game,
      targetFoodId: 'meat',
      getLocalizedName: (l10n) => l10n.dog,
    ),
    AnimalItem(
      id: 'lion',
      imageAsset: 'assets/gen/images/animal/lion.png',
      audioAsset: 'assets/audio/animals-sounds/lion_roar.wav',
      backgroundType: BackgroundType.jungle,
      targetFoodId: 'meat',
      getLocalizedName: (l10n) => l10n.lion,
    ),
  ];
}
