import 'package:flutter/material.dart';

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

  void initGame() {
    gameOver = false;
    score = 0;
    animals = [
      AnimalQuizModel(
        animalName: 'lion',
        animalImage: "assets/images/animal/lion.png",
        value: "lion",
      ),
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
        animalName: 'sheep',
        animalImage: "assets/images/animal/sheep.png",
        value: "sheep",
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
        animalName: 'horse',
        animalImage: "assets/images/animal/horse.png",
        value: "horse",
      ),
      AnimalQuizModel(
        animalName: 'bird',
        animalImage: "assets/images/animal/bird.png",
        value: "bird",
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
    ];
    chooseAnimals = List<AnimalQuizModel>.from(animals);
    animals.shuffle();
    chooseAnimals.shuffle();
  }

  @override
  void initState() {
    super.initState();
    initGame();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the game is over
    if (!gameOver && animals.isEmpty && chooseAnimals.isEmpty && score == 100) {
      setState(() {
        gameOver = true;
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/home/Page Border in Green Illustrative Nature Pastels Jungle Themed Style.png',
            height: MediaQuery.of(context).size.height,
            //width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text.rich(
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
                  ),
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
                                    score += 10;
                                  });
                                } else {
                                  setState(() {
                                    score -= 5;
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
                                      ? Colors.grey[400]
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
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              "Game Over",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              result(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (gameOver)
                    Container(
                      height: MediaQuery.of(context).size.width / 10,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            initGame();
                          });
                        },
                        child: Text(
                          'Play Again',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.white),
                        ),
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
    if (score == 100) {
      return "Excellent";
    } else {
      return "Try Again to get a better score";
    }
  }
}
