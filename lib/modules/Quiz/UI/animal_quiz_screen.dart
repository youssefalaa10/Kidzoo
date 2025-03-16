import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../models/quiz_model.dart';

class AnimalQuizScreen extends StatefulWidget {
  const AnimalQuizScreen({super.key});

  @override
  State<AnimalQuizScreen> createState() => _AnimalQuizScreenState();
}

class _AnimalQuizScreenState extends State<AnimalQuizScreen> {
  List<AnimalQuizModel> animals = [];
  List<AnimalQuizModel> chooseAnimals = [];
  int score = 0;
  bool gameOver = false;
  int level = 1;
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
      animalImage: "assets/images/animal/cat.png",
      value: "cat",
    ),
    AnimalQuizModel(
      animalName: 'dog',
      animalImage: "assets/images/animal/dog.png",
      value: "dog",
    ),
    AnimalQuizModel(
      animalName: 'cow',
      animalImage: "assets/images/animal/cow.png",
      value: "cow",
    ),
    AnimalQuizModel(
      animalName: 'hen',
      animalImage: "assets/images/animal/hen.png",
      value: "hen",
    ),
    AnimalQuizModel(
      animalName: 'bird',
      animalImage: "assets/images/animal/bird.png",
      value: "bird",
    ),
    
    // Level 2 animals (medium)
    AnimalQuizModel(
      animalName: 'lion',
      animalImage: "assets/images/animal/lion.png",
      value: "lion",
    ),
    AnimalQuizModel(
      animalName: 'sheep',
      animalImage: "assets/images/animal/sheep.png",
      value: "sheep",
    ),
    AnimalQuizModel(
      animalName: 'horse',
      animalImage: "assets/images/animal/horse.png",
      value: "horse",
    ),
    AnimalQuizModel(
      animalName: 'elephant',
      animalImage: "assets/images/animal/elephant.png",
      value: "elephant",
    ),
    AnimalQuizModel(
      animalName: 'giraffe',
      animalImage: "assets/images/animal/giraffe.png",
      value: "giraffe",
    ),
    AnimalQuizModel(
      animalName: 'cow',
      animalImage: "assets/images/animal/cow.png",
      value: "cow",
    ),
    AnimalQuizModel(
      animalName: 'hen',
      animalImage: "assets/images/animal/hen.png",
      value: "hen",
    ),
    AnimalQuizModel(
      animalName: 'bird',
      animalImage: "assets/images/animal/bird.png",
      value: "bird",
    ),
    
    // Level 3 animals (hard)
     AnimalQuizModel(
      animalName: 'cat',
      animalImage: "assets/images/animal/cat.png",
      value: "cat",
    ),
    AnimalQuizModel(
      animalName: 'dog',
      animalImage: "assets/images/animal/dog.png",
      value: "dog",
    ),
    AnimalQuizModel(
      animalName: 'cow',
      animalImage: "assets/images/animal/cow.png",
      value: "cow",
    ),
    AnimalQuizModel(
      animalName: 'hen',
      animalImage: "assets/images/animal/hen.png",
      value: "hen",
    ),
    AnimalQuizModel(
      animalName: 'bird',
      animalImage: "assets/images/animal/bird.png",
      value: "bird",
    ),
    AnimalQuizModel(
      animalName: 'lion',
      animalImage: "assets/images/animal/lion.png",
      value: "lion",
    ),
    AnimalQuizModel(
      animalName: 'sheep',
      animalImage: "assets/images/animal/sheep.png",
      value: "sheep",
    ),
    AnimalQuizModel(
      animalName: 'horse',
      animalImage: "assets/images/animal/horse.png",
      value: "horse",
    ),
    AnimalQuizModel(
      animalName: 'elephant',
      animalImage: "assets/images/animal/elephant.png",
      value: "elephant",
    ),
    AnimalQuizModel(
      animalName: 'giraffe',
      animalImage: "assets/images/animal/giraffe.png",
      value: "giraffe",
    ),
    AnimalQuizModel(
      animalName: 'A',
      animalImage: "assets/images/alphabet/a.png",
      value: "A",
    ),
    AnimalQuizModel(
      animalName: 'B',
      animalImage: "assets/images/alphabet/b.png",
      value: "B",
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
      if (level < maxLevel) {
        // Move to next level
        showLevelCompleteDialog();
      } else {
        // Game completed
        setState(() {
          gameOver = true;
        });
      }
    }
  }

  void showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Level $level Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You scored $score points'),
              const SizedBox(height: 20),
              Text('Ready for Level ${level + 1}?'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  setupLevel(level + 1);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    initGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/home/Page Border in Green Illustrative Nature Pastels Jungle Themed Style.png',
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
                                text: 'Score: ',
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
                            color: Colors.teal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Level $level',
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
                                    speak("Correct! Excellent");

                                    // Check if level is complete
                                    checkLevelCompletion();
                                  });
                                } else {
                                  setState(() {
                                    score = score > penaltyPerWrongMatch
                                        ? score - penaltyPerWrongMatch
                                        : 0;
                                    speak("Oops! Try again.");
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
                                      ? Colors.teal.withValues(alpha: 0.3)
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
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Game Complete!",
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
                                  "Your final score: $score",
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
                                  color: Colors.teal.withValues(alpha: 0.4),
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
                                'Play Again',
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
    if (score >= targetScoreForLevel * maxLevel) {
      return "Excellent!";
    } else if (score >= (targetScoreForLevel * maxLevel * 0.7)) {
      return "Great Job!";
    } else {
      return "Try Again to get a better score!";
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