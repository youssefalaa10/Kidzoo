import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/Alphabets/alphabet_screen.dart';
import 'package:kidzoo/modules/Alphabets/bloc/alphabet_bloc.dart';
import 'package:kidzoo/modules/FlappyBird/flappy_bird_game.dart';
import 'package:kidzoo/modules/MemoryGame/UI/memory_game.dart';
import 'package:kidzoo/modules/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/modules/Numbers/number_screen.dart';
import 'package:kidzoo/modules/Puzzle/bloc/cubit.dart';
import 'package:kidzoo/modules/Puzzle/puzzle_screen.dart';
import 'package:kidzoo/modules/Quiz/UI/animal_quiz_screen.dart';
import 'package:kidzoo/modules/Shapes/shape_screen.dart';
import 'package:kidzoo/modules/Tic-Tac-Toe/UI/tic_tac_toe_game.dart';
import 'package:kidzoo/shared/style/image_manager.dart';
import 'package:kidzoo/shared/media_query.dart';
import 'package:kidzoo/modules/LevelsMap/Data/Logic/cubit/levelmap_cubit.dart';
import 'package:kidzoo/modules/LevelsMap/levelmap_screen.dart';
import 'package:kidzoo/modules/MathGame/Data/Logic/cubit/math_game_cubit.dart';
import 'package:kidzoo/modules/MathGame/Ui/math_game.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_cubit.dart';

// Define the option data structure
class OptionItem {
  final String icon;
  final String title;
  final Widget screen;
  final String flipImage;

  OptionItem({
    required this.icon,
    required this.title,
    required this.screen,
    required this.flipImage,
  });
}

// Define app categories
enum AppCategory {
  games,
  education,
}

// Reusable options grid
class OptionsGrid extends StatelessWidget {
  final CustomMQ mq;
  final AppCategory category;

  const OptionsGrid({
    super.key,
    required this.mq,
    required this.category,
  });

  List<OptionItem> get options {
    switch (category) {
      case AppCategory.games:
        return _getGameOptions();
      case AppCategory.education:
        return _getEducationOptions();
    }
  }

  List<OptionItem> _getGameOptions() {
    return [
      OptionItem(
        icon: ImageManager.setting,
        title: 'Memory Game',
        screen: const MemoryGameScreen(level: 1),
        flipImage: ImageManager.flipMath,
      ),
      OptionItem(
        icon: ImageManager.math,
        title: 'Tic Tac Toe',
        screen: const TicTacToeGame(),
        flipImage: ImageManager.flipQuiz,
      ),
      OptionItem(
        icon: ImageManager.flipMath,
        title: 'Flappy Bird',
        screen: GameWidget(game: FlappyBirdGame()),
        flipImage: ImageManager.flipQuiz,
      ),
    ];
  }

  List<OptionItem> _getEducationOptions() {
    return [
      OptionItem(
        icon: ImageManager.numbers,
        title: 'Numbers',
        screen: BlocProvider(
          create: (context) => NumberBloc(),
          child: const NumberScreen(),
        ),
        flipImage: ImageManager.flipNumbers,
      ),
      OptionItem(
        icon: ImageManager.quiz,
        title: 'Quiz',
        screen: const AnimalQuizScreen(level: 1),
        flipImage: ImageManager.flipQuiz,
      ),
      OptionItem(
        icon: ImageManager.letters,
        title: 'Alphabet',
        screen: BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const AlphabetScreen(),
        ),
        flipImage: ImageManager.flipLetters,
      ),
      OptionItem(
        icon: ImageManager.shapes,
        title: 'Shapes',
        screen: BlocProvider(
          create: (context) => ShapeCubit(),
          child: const ShapeScreen(),
        ),
        flipImage: ImageManager.flipShapes,
      ),
      OptionItem(
        icon: ImageManager.puzzle,
        title: 'Puzzles',
        screen: BlocProvider(
          create: (context) => PuzzleCubit(),
          child: const PuzzleScreen(level: 1),
        ),
        flipImage: ImageManager.flipPuzzle,
      ),
      OptionItem(
        icon: ImageManager.math,
        title: 'Math Game',
        screen: const MathGame(level: 1),
        flipImage: ImageManager.flipMath,
      ),
      OptionItem(
        icon: ImageManager.setting,
        title: 'Level Map',
        screen: BlocProvider(
          create: (context) => LevelCubit(),
          child: const LevelMapScreen(),
        ),
        flipImage: ImageManager.flipPuzzle,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: mq.width(4),
        mainAxisSpacing: mq.height(2),
        childAspectRatio: 3 / 2.5,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return OptionCard(
          icon: option.icon,
          title: option.title,
          screen: option.screen,
          flipImage: option.flipImage,
          mq: mq,
        );
      },
    );
  }
}

class OptionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String flipImage;
  final Widget screen;
  final CustomMQ mq;

  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.flipImage,
    required this.screen,
    required this.mq,
  });

  @override
  OptionCardState createState() => OptionCardState();
}

class OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _flipCard() {
    if (_flipped) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => widget.screen),
      );
    } else {
      _controller.forward();
      setState(() {
        _flipped = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final isFront = angle < 3.14159 / 2;

          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: isFront
                ? _buildFrontSide()
                : Transform(
                    transform: Matrix4.rotationY(3.14159),
                    alignment: Alignment.center,
                    child: _buildBackSide(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.mq.width(4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(widget.mq.width(4)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            widget.icon,
            width: widget.mq.width(12),
            height: widget.mq.width(12),
            fit: BoxFit.contain,
          ),
          SizedBox(height: widget.mq.height(1)),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: widget.mq.width(4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.mq.width(4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        widget.flipImage,
        width: widget.mq.width(12),
        height: widget.mq.width(12),
        fit: BoxFit.contain,
      ),
    );
  }
}
