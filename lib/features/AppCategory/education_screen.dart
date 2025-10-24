import 'package:flutter/material.dart';
import 'package:kidzoo/core/helpers/media_query.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';

import 'app_category_options.dart';
import 'header_section.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> with TTSMusicMixin {
  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);

    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      // appBar: AppBar(
      //   title: const Text('Education'),
      //   backgroundColor: Colors.green[300],
      // ),
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
                            size: 30, color: Colors.green[800]),
                      ),
                      HeaderSection(
                        mq: mq,
                        title: 'Learning Activities',
                        textColor: Colors.green[800]!,
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height(3)),
                  Expanded(
                    child: OptionsGrid(
                      mq: mq,
                      category: AppCategory.education,
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
