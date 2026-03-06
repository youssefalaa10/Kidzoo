import 'package:flutter/material.dart';

import '../../../../core/helpers/media_query.dart';
import 'package:kidzoo/core/utils/assets.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({required this.mq, super.key});
  final CustomMQ mq;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  const AssetImage(Assets.genImagesHomeShapes),
              radius: mq.width(7),
            ),
            SizedBox(width: mq.width(3)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello',
                  style:
                      TextStyle(fontSize: mq.width(4), color: Colors.grey[600]),
                ),
                Text(
                  'Youssef',
                  style: TextStyle(
                    fontSize: mq.width(6),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.search, size: mq.width(6), color: Colors.grey[800]),
            SizedBox(width: mq.width(3)),
            Icon(Icons.menu, size: mq.width(6), color: Colors.grey[800]),
          ],
        ),
      ],
    );
  }
}