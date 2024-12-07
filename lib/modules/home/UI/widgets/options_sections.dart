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
      },
      {
        'icon': "assets/images/home/brain.png",
        'title': 'Quiz',
        'screen': const AnimalQuizScreen(),
      },
      {
        'icon': "assets/images/home/shapes.png",
        'title': 'Shapes',
        'screen': BlocProvider(
          create: (context) => ShapeBloc(),
          child: const ShapeScreen(),
        ),
      },
      {
        'icon': "assets/images/home/abc-block.png",
        'title': 'Vocab & Letters',
        'screen': BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const AlphabetScreen(),
        ),
      },
      {
        'icon': "assets/images/home/setting.png", // Add the asset image path
        'title': 'Learning Analysis',
        'screen': null,
      },
      {
        'icon': "assets/images/home/setting.png",
        'title': 'Settings',
        'screen': null,
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
          mq: mq,
        );
      },
    );
  }
}

class OptionCard extends StatelessWidget {
  final String icon;
  final String title;

  final Widget? screen;
  final CustomMQ mq;

  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    this.screen,
    required this.mq,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen!),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(mq.width(4)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(mq.width(4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: mq.width(12), // Adjust size as needed
              height: mq.width(12),
              fit: BoxFit.contain,
            ),
            SizedBox(height: mq.height(1)),
            Text(
              title,
              style: TextStyle(
                fontSize: mq.width(4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
