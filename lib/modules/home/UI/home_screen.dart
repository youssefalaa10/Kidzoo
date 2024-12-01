import 'package:flutter/material.dart';

import '../../../shared/media_query.dart';
import 'widgets/header_section.dart';
import 'widgets/options_sections.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width(5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: mq.height(2)),
              HeaderSection(mq: mq),
              SizedBox(height: mq.height(3)),
              Expanded(child: OptionsGrid(mq: mq)),
            ],
          ),
        ),
      ),
    );
  }
}


