import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/helpers/media_query.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';
import 'package:kidzoo/features/Alphabets/alphabet_screen.dart';
import 'package:kidzoo/features/Alphabets/bloc/alphabet_bloc.dart';
import 'package:kidzoo/features/FlappyBird/flappy_bird_screen.dart';
import 'package:kidzoo/features/Game2048/UI/game_2048_home.dart';
import 'package:kidzoo/features/Game2048/data/logic/game_cubit.dart';
import 'package:kidzoo/features/MissingLetterGame/Ui/missing_letter_screen.dart';
import 'package:kidzoo/features/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/features/Numbers/number_screen.dart';
import 'package:kidzoo/features/Shapes/bloc/shape_cubit.dart';
import 'package:kidzoo/features/Shapes/shape_screen.dart';
import 'package:kidzoo/features/Tic-Tac-Toe/UI/tic_tac_toe_game.dart';

// Define the option data structure
class OptionItem {
  OptionItem({
    required this.icon,
    required this.title,
    required this.screen,
    required this.flipImage,
  });
  final String icon;
  final String title;
  final Widget screen;
  final String flipImage;
}

// Define app categories
enum AppCategory {
  games,
  education,
}

// Reusable options grid
class OptionsGrid extends StatelessWidget {
  const OptionsGrid({
    required this.mq,
    required this.category,
    super.key,
  });
  final CustomMQ mq;
  final AppCategory category;

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
        icon: ImageManager.flipMath,
        title: 'Tic Tac Toe',
        screen: const TicTacToeGame(),
        flipImage: ImageManager.brain,
      ),
      OptionItem(
        icon: ImageManager.flappyBird,
        title: 'Flappy Bird',
        screen: const FlappyBirdScreen(),
        flipImage: ImageManager.birdAnimal,
      ),
      OptionItem(
        icon: ImageManager.letterL,
        title: 'Missing Letter',
        screen: const MissingLetterScreen(),
        flipImage: ImageManager.flipQuiz,
      ),
      OptionItem(
        icon: ImageManager.math,
        title: '2048 Game',
        screen: BlocProvider(
          create: (context) => GameCubit(),
          child: const Game2048Home(),
        ),
        flipImage: ImageManager.numbers,
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
  const OptionCard({
    required this.icon,
    required this.title,
    required this.flipImage,
    required this.screen,
    required this.mq,
    super.key,
  });
  final String icon;
  final String title;
  final String flipImage;
  final Widget screen;
  final CustomMQ mq;

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
      Navigator.push<void>(
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
