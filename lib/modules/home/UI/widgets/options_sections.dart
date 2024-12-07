import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/modules/Numbers/number_screen.dart';
import 'package:kidzoo/modules/Quiz/UI/animal_quiz_screen.dart';
import 'package:kidzoo/modules/Shapes/bloc/shape_bloc.dart';
import 'package:kidzoo/modules/Shapes/shape_screen.dart';
import '../../../../shared/media_query.dart';

import '../../../Alphabets/alphabet_screen.dart';
import '../../../Alphabets/bloc/alphabet_bloc.dart';

class OptionsGrid extends StatelessWidget {
  final CustomMQ mq;

  const OptionsGrid({super.key, required this.mq});

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'icon': "assets/images/home/numbers.png",
        'title': 'Numbers',
        'screen': BlocProvider(
          create: (context) => NumberBloc(),
          child: const NumberScreen(),
        ),
        'flipImage': "assets/images/home/one.png",
      },
      {
        'icon': "assets/images/home/brain.png",
        'title': 'Quiz',
        'screen': const AnimalQuizScreen(),
        'flipImage': "assets/images/animal/lion.png",
      },
      {
        'icon': "assets/images/home/shapes.png",
        'title': 'Shapes',
        'screen': BlocProvider(
          create: (context) => ShapeBloc(),
          child: const ShapeScreen(),
        ),
        'flipImage': "assets/images/home/rule.png",
      },
      {
        'icon': "assets/images/home/abc-block.png",
        'title': 'Vocab & Letters',
        'screen': BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const AlphabetScreen(),
        ),
        'flipImage': "assets/images/alphabet/a.png",
      },
      {
        'icon': "assets/images/home/setting.png",
        'title': 'Learning Analysis',
        'screen': null,
        'flipImage': null,
      },
      {
        'icon': "assets/images/home/setting.png",
        'title': 'Settings',
        'screen': null,
        'flipImage': null,
      },
    ];

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
          icon: option['icon'] as String,
          title: option['title'] as String,
          screen: option['screen'] as Widget?,
          flipImage: option['flipImage'] as String?,
          mq: mq,
        );
      },
    );
  }
}

class OptionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String? flipImage;
  final Widget? screen;
  final CustomMQ mq;

  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    this.flipImage,
    this.screen,
    required this.mq,
  });

  @override
  _OptionCardState createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
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
      if (widget.screen != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => widget.screen!),
        );
      }
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
      child: widget.flipImage != null
          ? Image.asset(
              widget.flipImage!,
              width: widget.mq.width(12),
              height: widget.mq.width(12),
              fit: BoxFit.contain,
            )
          : const Text(
              "No Image Available",
              style: TextStyle(color: Colors.white),
            ),
    );
  }
}
