import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/core/helpers/media_query.dart';
import 'package:kidzoo/core/localization/app_localizations.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';
import 'package:kidzoo/features/Alphabets/alphabet_screen.dart';
import 'package:kidzoo/features/Alphabets/bloc/alphabet_bloc.dart';
import 'package:kidzoo/features/AnimalNameGame/UI/animal_name_game_screen.dart';
import 'package:kidzoo/features/ColorSwitchGame/color_switch_screen.dart';
import 'package:kidzoo/features/DotsAndBoxes/UI/dots_and_boxes_screen.dart';
import 'package:kidzoo/features/DrawLab/UI/screens/drawlab_screen.dart';
import 'package:kidzoo/features/FlagGame/pages/flag_game_menu_screen.dart';
import 'package:kidzoo/features/FlagGame/pages/listening_game_screen.dart';
import 'package:kidzoo/features/FlappyBird/flappy_bird_screen.dart';
import 'package:kidzoo/features/Game2048/UI/game_2048_home.dart';
import 'package:kidzoo/features/Game2048/data/logic/game_cubit.dart';
import 'package:kidzoo/features/MissingLetterGame/Ui/missing_letter_home.dart';
import 'package:kidzoo/features/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/features/Numbers/number_screen.dart';
import 'package:kidzoo/features/PaddleBounce/UI/paddle_bounce_menu_screen.dart';
import 'package:kidzoo/features/Shapes/bloc/shape_cubit.dart';
import 'package:kidzoo/features/Shapes/shape_screen.dart';
import 'package:kidzoo/features/Tic-Tac-Toe/UI/tic_tac_toe_game.dart';

// Define the option data structure
class OptionItem {
  final String icon;
  final String title;
  final Widget screen;
  final String flipImage;
  final IconData? backIcon;
  final IconData? frontIcon;

  OptionItem({
    required this.icon,
    required this.title,
    required this.screen,
    required this.flipImage,
    this.backIcon,
    this.frontIcon,
  });
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

  List<OptionItem> getOptions(BuildContext context) {
    switch (category) {
      case AppCategory.games:
        return _getGameOptions(context);
      case AppCategory.education:
        return _getEducationOptions(context);
    }
  }

  List<OptionItem> _getGameOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      OptionItem(
        icon: ImageManager.xo,
        title: l10n.ticTacToe,
        screen: const TicTacToeGame(),
        flipImage: ImageManager.brain,
        backIcon: Icons.grid_3x3_rounded,
      ),
      OptionItem(
        icon: ImageManager.flappyBird,
        title: l10n.flappyBird,
        screen: const FlappyBirdScreen(),
        flipImage: ImageManager.birdAnimal,
      ),
      OptionItem(
        icon: ImageManager.letterL,
        title: l10n.missingLetter,
        screen: const MissingLetterHome(),
        flipImage: ImageManager.brain,
        backIcon: Icons.spellcheck_rounded,
      ),
      OptionItem(
        icon: ImageManager.i2048,
        title: l10n.game2048,
        screen: BlocProvider(
          create: (context) => GameCubit(),
          child: const Game2048Home(),
        ),
        flipImage: ImageManager.numbers,
      ),
      OptionItem(
        icon: ImageManager.pen,
        title: l10n.dotsAndBoxes,
        screen: const DotsAndBoxesScreen(),
        flipImage: ImageManager.flipShapes,
      ),
      OptionItem(
        icon: ImageManager.gamepad,
        title: l10n.paddleBounce,
        screen: const PaddleBounceMenuScreen(),
        flipImage: ImageManager.brain,
        backIcon: Icons.sports_esports_rounded,
      ),
      OptionItem(
        icon: ImageManager.simle,
        title: l10n.drawLab,
        screen: const DrawLabScreen(),
        flipImage: ImageManager.pen,
      ),
    ];
  }

  List<OptionItem> _getEducationOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      OptionItem(
        icon: ImageManager.numbers,
        title: l10n.numbers,
        screen: BlocProvider(
          create: (context) => NumberBloc(),
          child: const NumberScreen(),
        ),
        flipImage: ImageManager.flipNumbers,
      ),
      OptionItem(
        icon: ImageManager.letters,
        title: l10n.alphabet,
        screen: BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const AlphabetScreen(),
        ),
        flipImage: ImageManager.flipLetters,
      ),
      OptionItem(
        icon: ImageManager.shapes,
        title: l10n.shapes,
        screen: BlocProvider(
          create: (context) => ShapeCubit(),
          child: const ShapeScreen(),
        ),
        flipImage: ImageManager.flipShapes,
      ),
      OptionItem(
        icon: ImageManager.colorLearn,
        title: l10n.colorSwitch,
        screen: const ColorSwitchScreen(),
        flipImage: ImageManager.colorLearn,
        backIcon: Icons.palette_rounded,
        frontIcon: Icons.color_lens_rounded,
      ),
      OptionItem(
        icon: ImageManager.lion,
        title: l10n.animalNameGame,
        screen: const AnimalNameGameScreen(),
        flipImage: ImageManager.elephant,
      ),
      OptionItem(
        icon: ImageManager.egypt,
        title: l10n.flagGame,
        screen: const FlagGameMenuScreen(),
        flipImage: ImageManager.worldMap,
        backIcon: Icons.flag_rounded,
        frontIcon: Icons.public_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final options = getOptions(context);
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: mq.width(4),
        vertical: mq.height(2),
      ),
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
          backIcon: option.backIcon,
          frontIcon: option.frontIcon,
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
    this.backIcon,
    this.frontIcon,
    super.key,
  });
  final String icon;
  final String title;
  final String flipImage;
  final Widget screen;
  final CustomMQ mq;
  final IconData? backIcon;
  final IconData? frontIcon;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controller.value == 1) {
          _controller.reverse();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => widget.screen),
              );
            }
          });
        } else {
          _controller.forward();
        }
      },
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
    final isSpecialIcon = widget.icon == ImageManager.simle ||
        widget.icon == ImageManager.pen ||
        widget.icon == ImageManager.xo ||
        widget.frontIcon != null;

    final iconSize = isSpecialIcon ? widget.mq.width(16) : widget.mq.width(12);

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
      padding: EdgeInsets.all(widget.mq.width(2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.frontIcon != null)
            Icon(
              widget.frontIcon,
              size: iconSize,
              color: const Color(0xFFe2c9b5),
            )
          else
            Image.asset(
              widget.icon,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          SizedBox(height: widget.mq.height(1)),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: widget.mq.width(3.5),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    final iconSize = widget.mq.width(12);

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
      child: widget.backIcon != null
          ? Icon(
              widget.backIcon,
              size: iconSize,
              color: const Color(0xFF776E65),
            )
          : Image.asset(
              widget.flipImage,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
    );
  }
}
