import 'package:flutter/material.dart';
import 'package:kidzo/core/helpers/media_query.dart';
import 'package:kidzo/core/localization/app_localizations.dart';
import 'package:kidzo/core/mixins/background_music_mixin.dart';
import 'package:kidzo/core/services/background_resolver.dart';
import 'package:kidzo/core/shared/widgets/fluid_container.dart';

import 'app_category_options.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with BackgroundMusicMixin {
  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);

    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(BackgroundResolver(context, BackgroundType.game).resolveBackground()!),
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
                          size: 30, color: Colors.blue[800]),
                    ),
                    HeaderSection(
                      mq: mq,
                      title: AppLocalizations.of(context).funGames,
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
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    required this.mq,
    super.key,
    this.title = 'Welcome to kidzo',
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
