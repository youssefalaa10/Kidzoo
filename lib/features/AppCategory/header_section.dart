import 'package:flutter/material.dart';

import '../../core/helpers/media_query.dart';

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
