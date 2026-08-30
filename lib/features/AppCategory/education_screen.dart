import 'package:flutter/material.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/mixins/background_music_mixin.dart';
import 'package:kidzo/core/services/background_resolver.dart';
import 'package:kidzo/core/shared/widgets/fluid_container.dart';

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BackgroundResolver(context, BackgroundType.education).resolveBackground()!),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: FluidContainer(
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
                      title: AppLocalizations.of(context).learningActivities,
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
      ),
    );
  }
}
