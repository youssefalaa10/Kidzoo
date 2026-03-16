import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/localization/app_localizations.dart';

import '../../../core/base/protected_game_screen.dart';
import '../../../core/mixins/background_music_mixin.dart';
import '../data/model/animal_quiz_model.dart';
import 'package:kidzoo/core/utils/assets.dart';

class AnimalQuizScreen extends ProtectedGameScreen {
  const AnimalQuizScreen({required super.level, super.key});

  @override
  State<AnimalQuizScreen> createState() => _AnimalQuizScreenState();
}

class _AnimalQuizScreenState extends ProtectedGameScreenState<AnimalQuizScreen>
    with TTSMusicMixin {
  List<AnimalQuizModel> animals = [];
  List<AnimalQuizModel> chooseAnimals = [];
  int score = 0;
  bool gameOver = false;
  late int level;
  int maxLevel = 3;
  int pointsPerCorrectMatch = 10;
  int penaltyPerWrongMatch = 5;
  int targetScoreForLevel = 100;

  final FlutterTts flutterTts = FlutterTts();

  // All available animals across levels
  final List<AnimalQuizModel> allAnimals = [
    // Level 1 animals (easy)
    AnimalQuizModel(
      animalName: 'cat',
      animalImage: Assets.genImagesAnimalCat,
      value: 'cat',
    ),
    AnimalQuizModel(
      animalName: 'dog',
      animalImage: Assets.genImagesAnimalDog,
      value: 'dog',
    ),
    AnimalQuizModel(
      animalName: 'cow',
      animalImage: Assets.genImagesAnimalCow,
      value: 'cow',
    ),
    AnimalQuizModel(
      animalName: 'hen',
      animalImage: Assets.genImagesAnimalHen,
      value: 'hen',
    ),
    AnimalQuizModel(
      animalName: 'bird',
      animalImage: Assets.genImagesAnimalBird,
      value: 'bird',
    ),

    // Level 2 animals (medium)
    AnimalQuizModel(
      animalName: 'lion',
      animalImage: Assets.genImagesAnimalLion,
      value: 'lion',
    ),
    AnimalQuizModel(
      animalName: 'sheep',
      animalImage: Assets.genImagesAnimalSheep,
      value: 'sheep',
    ),
    AnimalQuizModel(
      animalName: 'horse',
      animalImage: Assets.genImagesAnimalHorse,
      value: 'horse',
    ),
    AnimalQuizModel(
      animalName: 'elephant',
      animalImage: Assets.genImagesAnimalElephant,
      value: 'elephant',
    ),
    AnimalQuizModel(
      animalName: 'giraffe',
      animalImage: Assets.genImagesAnimalGiraffe,
      value: 'giraffe',
    ),
    AnimalQuizModel(
      animalName: 'cow',
      animalImage: Assets.genImagesAnimalCow,
      value: 'cow',
    ),
    AnimalQuizModel(
      animalName: 'hen',
      animalImage: Assets.genImagesAnimalHen,
      value: 'hen',
    ),
    AnimalQuizModel(
      animalName: 'bird',
      animalImage: Assets.genImagesAnimalBird,
      value: 'bird',
    ),

    // Level 3 animals (hard)
    AnimalQuizModel(
      animalName: 'cat',
      animalImage: Assets.genImagesAnimalCat,
      value: 'cat',
    ),
    AnimalQuizModel(
      animalName: 'dog',
      animalImage: Assets.genImagesAnimalDog,
      value: 'dog',
    ),
    AnimalQuizModel(
      animalName: 'cow',
      animalImage: Assets.genImagesAnimalCow,
      value: 'cow',
    ),
    AnimalQuizModel(
      animalName: 'hen',
      animalImage: Assets.genImagesAnimalHen,
      value: 'hen',
    ),
    AnimalQuizModel(
      animalName: 'bird',
      animalImage: Assets.genImagesAnimalBird,
      value: 'bird',
    ),
    AnimalQuizModel(
      animalName: 'lion',
      animalImage: Assets.genImagesAnimalLion,
      value: 'lion',
    ),
    AnimalQuizModel(
      animalName: 'sheep',
      animalImage: Assets.genImagesAnimalSheep,
      value: 'sheep',
    ),
    AnimalQuizModel(
      animalName: 'horse',
      animalImage: Assets.genImagesAnimalHorse,
      value: 'horse',
    ),
    AnimalQuizModel(
      animalName: 'elephant',
      animalImage: Assets.genImagesAnimalElephant,
      value: 'elephant',
    ),
    AnimalQuizModel(
      animalName: 'giraffe',
      animalImage: Assets.genImagesAnimalGiraffe,
      value: 'giraffe',
    ),
    AnimalQuizModel(
      animalName: 'A',
      animalImage: Assets.genImagesAlphabetA,
      value: 'A',
    ),
    AnimalQuizModel(
      animalName: 'B',
      animalImage: Assets.genImagesAlphabetB,
      value: 'B',
    ),
  ];

  void initGame() {
    gameOver = false;
    score = 0;
    setupLevel(level);
  }

  void setupLevel(int newLevel) {
    level = newLevel;

    // Adjust difficulty based on level
    switch (level) {
      case 1:
        pointsPerCorrectMatch = 10;
        penaltyPerWrongMatch = 5;
        targetScoreForLevel = 50;
        // Get first 5 animals for level 1
        animals = List<AnimalQuizModel>.from(allAnimals.sublist(0, 5));
        break;
      case 2:
        pointsPerCorrectMatch = 15;
        penaltyPerWrongMatch = 8;
        targetScoreForLevel = 75;
        // Get next 8 animals for level 2
        animals = List<AnimalQuizModel>.from(allAnimals.sublist(5, 13));
        break;
      case 3:
        pointsPerCorrectMatch = 20;
        penaltyPerWrongMatch = 10;
        targetScoreForLevel = 100;
        // Get last 12 animals for level 3
        animals = List<AnimalQuizModel>.from(allAnimals.sublist(13, 25));
        break;
    }

    chooseAnimals = List<AnimalQuizModel>.from(animals);
    animals.shuffle();
    chooseAnimals.shuffle();
  }

  void checkLevelCompletion() {
    if (animals.isEmpty && chooseAnimals.isEmpty) {
      final l10n = AppLocalizations.of(context);
      // Show a brief congratulations message
      speak(l10n.levelComplete);

      // Add a small delay to allow the speech to be heard
      Future.delayed(const Duration(milliseconds: 1500), () {
        // Always return to map screen with completion status
        // This will signal the level map to automatically open the next stage
        if (mounted) {
          Navigator.of(context)
              .pop(true); // Return true to indicate level completion
        }
      });
    }
  }

  void speak(String text) async {
    // Stop background music completely for TTS to avoid تداخل
    stopForSpeech();

    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);

    // Resume background music after a delay
    Future.delayed(const Duration(seconds: 3), () {
      resumeAfterSpeech();
    });
  }

  @override
  void onGameInit() {
    final l10n = AppLocalizations.of(context);
    level = widget.level;
    initGame();
    speak(l10n.welcomeToAnimalQuiz(level));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            Assets
                .genImagesHomePageBorderInGreenIllustrativeNaturePastelsJungleThemedStyle,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${l10n.score}: ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: '$score',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: Colors.teal),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l10n.levelText(level),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!gameOver)
                    Row(
                      children: [
                        const Spacer(),
                        Column(
                          children: animals.map((animal) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 7),
                              child: Draggable<AnimalQuizModel>(
                                data: animal,
                                childWhenDragging: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      AssetImage(animal.animalImage),
                                  radius: 50,
                                ),
                                feedback: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      AssetImage(animal.animalImage),
                                  radius: 30,
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      AssetImage(animal.animalImage),
                                  radius: 30,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Spacer(
                          flex: 2,
                        ),
                        Column(
                          children: chooseAnimals.map((animalLetter) {
                            return DragTarget<AnimalQuizModel>(
                              onAcceptWithDetails: (receivedAnimal) {
                                if (receivedAnimal.data.value ==
                                    animalLetter.value) {
                                  setState(() {
                                    animals.remove(receivedAnimal.data);
                                    chooseAnimals.remove(animalLetter);
                                    score += pointsPerCorrectMatch;
                                    speak(' ${animalLetter.animalName}');

                                    // Check if level is complete
                                    checkLevelCompletion();
                                  });
                                } else {
                                  setState(() {
                                    score = score > penaltyPerWrongMatch
                                        ? score - penaltyPerWrongMatch
                                        : 0;
                                    speak(l10n.oopsTryAgain);
                                  });
                                }
                              },
                              onWillAcceptWithDetails: (receivedAnimal) {
                                setState(() {
                                  animalLetter.accepting = true;
                                });
                                return true;
                              },
                              onLeave: (_) {
                                setState(() {
                                  animalLetter.accepting = false;
                                });
                              },
                              builder:
                                  (context, acceptedItems, rejectedItems) =>
                                      Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: animalLetter.accepting
                                      ? Colors.teal.withOpacity(0.3)
                                      : Colors.grey[200],
                                ),
                                alignment: Alignment.center,
                                height: MediaQuery.of(context).size.width / 6.5,
                                width: MediaQuery.of(context).size.width / 3,
                                margin: const EdgeInsets.all(8),
                                child: Text(
                                  animalLetter.animalName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                      ],
                    ),
                  if (gameOver)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  l10n.gameComplete,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.yourFinalScore(score),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  result(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: getResultColor(),
                                      ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            width: MediaQuery.of(context).size.width / 2,
                            height: MediaQuery.of(context).size.width / 10,
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  level = 1;
                                  initGame();
                                });
                              },
                              child: Text(
                                l10n.playAgain,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String result() {
    final l10n = AppLocalizations.of(context);
    if (score >= targetScoreForLevel * maxLevel) {
      return l10n.excellent;
    } else if (score >= (targetScoreForLevel * maxLevel * 0.7)) {
      return l10n.greatJob;
    } else {
      return l10n.tryAgainToGetBetterScore;
    }
  }

  Color getResultColor() {
    if (score >= targetScoreForLevel * maxLevel) {
      return Colors.green;
    } else if (score >= (targetScoreForLevel * maxLevel * 0.7)) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
