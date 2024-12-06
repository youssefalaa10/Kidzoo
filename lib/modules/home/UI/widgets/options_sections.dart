import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzoo/modules/Numbers/bloc/number_bloc.dart';
import 'package:kidzoo/modules/Numbers/number_screen.dart';
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
        'icon': Icons.looks_one,
        'title': 'Numbers',
        'subtitle': '(números)',
        'screen': BlocProvider(
          create: (context) => NumberBloc(),
          child: const NumberScreen(),
        ),
      },
      {
        'icon': Icons.menu_book,
        'title': 'Reading',
        'subtitle': '(Leer)',
        'screen': null,
      },
      {
        'icon': Icons.category,
        'title': 'Shapes',
        'subtitle': '(Formas)',
        'screen': BlocProvider(
          create: (context) => ShapeBloc(),
          child: const ShapeScreen(),
        ),
      },
      {
        'icon': Icons.abc,
        'title': 'Vocab & Letters',
        'subtitle': '(Vocabulario & Letras)',
        'screen': BlocProvider(
          create: (context) => AlphabetBloc(),
          child: const AlphabetScreen(),
        ),
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Learning Analysis',
        'subtitle': '(análisis de aprendizaje)',
        'screen': null,
      },
      {
        'icon': Icons.settings,
        'title': 'Settings',
        'subtitle': '(Ajustes de aplicación)',
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
          icon: option['icon'] as IconData,
          title: option['title'] as String,
          subtitle: option['subtitle'] as String,
          screen: option['screen'] as Widget?,
          mq: mq,
        );
      },
    );
  }
}

class OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? screen;
  final CustomMQ mq;

  const OptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
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
            Icon(icon, size: mq.width(10), color: Colors.deepPurple),
            SizedBox(height: mq.height(1)),
            Text(
              title,
              style: TextStyle(
                fontSize: mq.width(4),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: mq.height(0.5)),
            Text(
              subtitle,
              style: TextStyle(fontSize: mq.width(3), color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
