import 'package:flutter/material.dart';
import 'package:kidzoo/core/helpers/media_query.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';

import 'app_category_options.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);

    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      body: Stack(
        children: [
          Image.asset(
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.fitHeight,
            ImageManager.homeBackground,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width(5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: mq.height(2)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_outlined,
                            size: 30, color: Colors.blue[800]),
                      ),
                      HeaderSection(
                        mq: mq,
                        title: 'Fun Games',
                        textColor: Colors.blue[800]!,
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height(3)),
                  Expanded(
                    child: OptionsGrid(
                      mq: mq,
                      category: AppCategory.games,
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
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    required this.mq,
    super.key,
    this.title = 'Welcome to KidZoo!',
    this.textColor = const Color(0xFF6A1B9A), // Purple by default
  });
  final CustomMQ mq;
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: mq.width(7),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: mq.height(1)),
        Container(
          width: mq.width(20),
          height: mq.height(0.8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(mq.width(1)),
          ),
        ),
      ],
    );
  }
}
