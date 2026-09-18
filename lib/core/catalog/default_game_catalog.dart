import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/catalog/game_catalog.dart';
import 'package:kidzo/core/catalog/game_descriptor.dart';
import 'package:kidzo/core/catalog/game_surface.dart';
import 'package:kidzo/core/shared/style/image_manager.dart';
import 'package:kidzo/features/Alphabets/alphabet_screen.dart';
import 'package:kidzo/features/Alphabets/bloc/alphabet_bloc.dart';
import 'package:kidzo/features/AnimalNameGame/UI/animal_name_game_screen.dart';
import 'package:kidzo/features/AnimalQuiz/UI/animal_quiz_screen.dart';
import 'package:kidzo/features/ColorMemoryGame/UI/color_memory_screen.dart';
import 'package:kidzo/features/ColorSwitchGame/color_switch_screen.dart';
import 'package:kidzo/features/DotsAndBoxes/UI/dots_and_boxes_screen.dart';
import 'package:kidzo/features/DrawLab/UI/screens/drawlab_screen.dart';
import 'package:kidzo/features/FeedTheAnimalGame/ui/feed_animal_screen.dart';
import 'package:kidzo/features/FlagGame/pages/flag_game_menu_screen.dart';
import 'package:kidzo/features/FlappyBird/flappy_bird_screen.dart';
import 'package:kidzo/features/FruitVegSorterGame/ui/sorter_game_screen.dart';
import 'package:kidzo/features/FruitsGame/UI/fruits_game_screen.dart';
import 'package:kidzo/features/Game2048/UI/game_2048_home.dart';
import 'package:kidzo/features/Game2048/data/logic/game_cubit.dart';
import 'package:kidzo/features/MathGame/Ui/math_game.dart';
import 'package:kidzo/features/MazeGame/UI/maze_game_screen.dart';
import 'package:kidzo/features/MemoryGame/UI/memory_game.dart';
import 'package:kidzo/features/MissingLetterGame/Ui/missing_letter_home.dart';
import 'package:kidzo/features/Numbers/bloc/number_bloc.dart';
import 'package:kidzo/features/Numbers/number_screen.dart';
import 'package:kidzo/features/PaddleBounce/UI/paddle_bounce_menu_screen.dart';
import 'package:kidzo/features/Puzzle/puzzle_screen.dart';
import 'package:kidzo/features/Shapes/bloc/shape_cubit.dart';
import 'package:kidzo/features/Shapes/shape_screen.dart';
import 'package:kidzo/features/Tic-Tac-Toe/UI/tic_tac_toe_game.dart';
import 'package:kidzo/features/VegetablesGame/UI/vegetables_game_screen.dart';
import 'package:kidzo/features/VehiclesGame/UI/vehicles_game_screen.dart';

/// Builds the catalog the app ships with.
///
/// Order within each surface is the order the grid displays, and it reproduces
/// the previous hand-written lists exactly — a regression test asserts this.
///
/// The five activities that already record scores keep their historical
/// `gameKey` as their [GameDescriptor.activityId], so existing `GameScores`
/// rows stay joinable: `feed_animal_game`, `fruit_veg_sorter`, `vehicles_game`,
/// `fruits`, `vegetables`.
GameCatalog buildDefaultGameCatalog() {
  return GameCatalog(<GameDescriptor>[
    // ---- Games ----
    GameDescriptor(
      activityId: 'tic_tac_toe',
      titleLocalizationKey: 'ticTacToe',
      iconAsset: ImageManager.xo,
      flipImageAsset: ImageManager.brain,
      surface: GameSurface.games,
      backIcon: Icons.grid_3x3_rounded,
      screenBuilder: () => const TicTacToeGame(),
    ),
    GameDescriptor(
      activityId: 'flappy_bird',
      titleLocalizationKey: 'flappyBird',
      iconAsset: ImageManager.flappyBird,
      flipImageAsset: ImageManager.birdAnimal,
      surface: GameSurface.games,
      screenBuilder: () => const FlappyBirdScreen(),
    ),
    GameDescriptor(
      activityId: 'missing_letter',
      titleLocalizationKey: 'missingLetter',
      iconAsset: ImageManager.letterL,
      flipImageAsset: ImageManager.brain,
      surface: GameSurface.games,
      backIcon: Icons.spellcheck_rounded,
      screenBuilder: () => const MissingLetterHome(),
    ),
    GameDescriptor(
      activityId: 'game_2048',
      titleLocalizationKey: 'game2048',
      iconAsset: ImageManager.i2048,
      flipImageAsset: ImageManager.numbers,
      surface: GameSurface.games,
      screenBuilder: () => BlocProvider<GameCubit>(
        create: (_) => GameCubit(),
        child: const Game2048Home(),
      ),
    ),
    GameDescriptor(
      activityId: 'dots_and_boxes',
      titleLocalizationKey: 'dotsAndBoxes',
      iconAsset: ImageManager.pen,
      flipImageAsset: ImageManager.flipShapes,
      surface: GameSurface.games,
      screenBuilder: () => const DotsAndBoxesScreen(),
    ),
    GameDescriptor(
      activityId: 'paddle_bounce',
      titleLocalizationKey: 'paddleBounce',
      iconAsset: ImageManager.gamepad,
      flipImageAsset: ImageManager.brain,
      surface: GameSurface.games,
      backIcon: Icons.sports_esports_rounded,
      screenBuilder: () => const PaddleBounceMenuScreen(),
    ),
    GameDescriptor(
      activityId: 'draw_lab',
      titleLocalizationKey: 'drawLab',
      iconAsset: ImageManager.simle,
      flipImageAsset: ImageManager.pen,
      surface: GameSurface.games,
      screenBuilder: () => const DrawLabScreen(),
    ),

    // ---- Previously locked behind the Challenge level map ----
    //
    // These six were reachable *only* through the old level map, which is gone
    // now that Challenge opens Adventures. Leaving them there would have made
    // six working games unreachable.
    //
    // Putting them in the grids is also what the design actually calls for:
    // free play is never gated by story progress, and gating a memory game
    // behind a campaign was the mistake the level map embodied. They default to
    // level 1, which is the gentlest configuration each one offers.
    GameDescriptor(
      activityId: 'memory_game',
      titleLocalizationKey: 'memoryGame',
      iconAsset: ImageManager.brain,
      flipImageAsset: ImageManager.brainstorming,
      surface: GameSurface.games,
      backIcon: Icons.grid_view_rounded,
      screenBuilder: () => const MemoryGameScreen(level: 1),
    ),
    GameDescriptor(
      activityId: 'color_memory_game',
      titleLocalizationKey: 'colorMemory',
      iconAsset: 'assets/gen/images/shapes/circle.png',
      flipImageAsset: ImageManager.colorLearn,
      surface: GameSurface.games,
      backIcon: Icons.palette_rounded,
      screenBuilder: () => const ColorMemoryScreen(level: 1),
    ),
    GameDescriptor(
      activityId: 'puzzle',
      titleLocalizationKey: 'puzzleGame',
      iconAsset: ImageManager.puzzle,
      flipImageAsset: ImageManager.brain,
      surface: GameSurface.games,
      backIcon: Icons.extension_rounded,
      screenBuilder: () => const PuzzleScreen(level: 1),
    ),
    GameDescriptor(
      activityId: 'maze_game',
      titleLocalizationKey: 'mazeGame',
      iconAsset: ImageManager.brainstorming,
      flipImageAsset: ImageManager.brain,
      surface: GameSurface.games,
      backIcon: Icons.route_rounded,
      screenBuilder: () => const MazeGameScreen(),
    ),

    // ---- Education ----
    GameDescriptor(
      activityId: 'numbers',
      titleLocalizationKey: 'numbers',
      iconAsset: ImageManager.numbers,
      flipImageAsset: ImageManager.flipNumbers,
      surface: GameSurface.education,
      screenBuilder: () => BlocProvider<NumberBloc>(
        create: (_) => NumberBloc(),
        child: const NumberScreen(),
      ),
    ),
    GameDescriptor(
      activityId: 'animal_names',
      titleLocalizationKey: 'animalNames',
      iconAsset: 'assets/gen/images/animal/cat.png',
      flipImageAsset: 'assets/gen/images/animal/dog.png',
      surface: GameSurface.education,
      screenBuilder: () => const AnimalNameGameScreen(),
    ),
    GameDescriptor(
      activityId: 'alphabet',
      titleLocalizationKey: 'alphabet',
      iconAsset: ImageManager.letters,
      flipImageAsset: ImageManager.flipLetters,
      surface: GameSurface.education,
      screenBuilder: () => BlocProvider<AlphabetBloc>(
        create: (_) => AlphabetBloc(),
        child: const AlphabetScreen(),
      ),
    ),
    GameDescriptor(
      activityId: 'shapes',
      titleLocalizationKey: 'shapes',
      iconAsset: ImageManager.shapes,
      flipImageAsset: ImageManager.flipShapes,
      surface: GameSurface.education,
      screenBuilder: () => BlocProvider<ShapeCubit>(
        create: (_) => ShapeCubit(),
        child: const ShapeScreen(),
      ),
    ),
    GameDescriptor(
      activityId: 'flag_game',
      titleLocalizationKey: 'learnCountryFlags',
      iconAsset: ImageManager.worldMap,
      flipImageAsset: ImageManager.worldMap,
      surface: GameSurface.education,
      backIcon: Icons.outlined_flag_rounded,
      frontIcon: Icons.flag_rounded,
      screenBuilder: () => const FlagGameMenuScreen(),
    ),
    GameDescriptor(
      activityId: 'color_switch',
      titleLocalizationKey: 'colorSwitch',
      iconAsset: 'assets/gen/images/shapes/circle.png',
      flipImageAsset: ImageManager.colorLearn,
      surface: GameSurface.education,
      backIcon: Icons.palette_rounded,
      frontIcon: Icons.color_lens_rounded,
      screenBuilder: () => const ColorSwitchScreen(),
    ),
    GameDescriptor(
      activityId: 'feed_animal_game',
      titleLocalizationKey: 'feed_animal_title',
      iconAsset: 'assets/gen/images/animal/cow.png',
      flipImageAsset: 'assets/gen/images/animal/sheep.png',
      surface: GameSurface.education,
      screenBuilder: () => const FeedAnimalScreen(),
    ),
    GameDescriptor(
      activityId: 'fruit_veg_sorter',
      titleLocalizationKey: 'fruitVegSorterTitle',
      iconAsset: 'assets/gen/images/fruits/watermelon.png',
      flipImageAsset: 'assets/gen/images/vegetables/carrot.png',
      surface: GameSurface.education,
      screenBuilder: () => const SorterGameScreen(),
    ),
    GameDescriptor(
      activityId: 'vehicles_game',
      titleLocalizationKey: 'vehicles',
      iconAsset: 'assets/gen/images/vehicles/car.png',
      flipImageAsset: 'assets/gen/images/vehicles/train.png',
      surface: GameSurface.education,
      screenBuilder: () => const VehiclesGameScreen(),
    ),
    GameDescriptor(
      activityId: 'fruits',
      titleLocalizationKey: 'fruits',
      iconAsset: 'assets/gen/images/fruits/mango.png',
      flipImageAsset: 'assets/gen/images/fruits/orange.png',
      surface: GameSurface.education,
      screenBuilder: () => const FruitsGameScreen(),
    ),
    GameDescriptor(
      activityId: 'vegetables',
      titleLocalizationKey: 'vegetables',
      iconAsset: 'assets/gen/images/vegetables/corn.png',
      flipImageAsset: 'assets/gen/images/vegetables/potato.png',
      surface: GameSurface.education,
      screenBuilder: () => const VegetablesGameScreen(),
    ),

    // Also previously locked behind the level map; appended so the eleven
    // entries above keep the exact order they have always had.
    GameDescriptor(
      activityId: 'animal_quiz',
      titleLocalizationKey: 'animalQuiz',
      iconAsset: 'assets/gen/images/animal/lion.png',
      flipImageAsset: 'assets/gen/images/animal/giraffe.png',
      surface: GameSurface.education,
      screenBuilder: () => const AnimalQuizScreen(level: 1),
    ),
    GameDescriptor(
      activityId: 'math_game',
      titleLocalizationKey: 'mathGameTitle',
      iconAsset: ImageManager.numbers,
      flipImageAsset: ImageManager.flipNumbers,
      surface: GameSurface.education,
      backIcon: Icons.calculate_rounded,
      screenBuilder: () => const MathGame(level: 1),
    ),
  ]);
}
