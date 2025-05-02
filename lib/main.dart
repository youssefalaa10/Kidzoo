import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/FlappyBird/flappy_bird_game.dart';

import 'modules/Alphabets/bloc/alphabet_bloc.dart';
import 'modules/home/UI/character.dart';
import 'modules/home/UI/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kidzoo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
         home: BlocProvider(
        create: (context) => AlphabetBloc(),
        child: const CharacterSelectionScreen(),
      ),
          // CharacterSelectionScreen(),
      // GameWidget(game: FlappyBirdGame()),
      // BlocProvider(
      //   create: (context) => AlphabetBloc(),
      //   child: const HomeScreen(),
      // ),
    );
  }
}
