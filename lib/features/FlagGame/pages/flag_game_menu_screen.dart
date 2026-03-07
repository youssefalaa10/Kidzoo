import 'package:flutter/material.dart';
import 'package:kidzoo/core/helpers/media_query.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/core/shared/style/image_manager.dart';
import '../data/flag_data_manager.dart';
import 'guess_the_flag_screen.dart';
import 'tap_to_learn_screen.dart';
import 'listening_game_screen.dart';

class FlagGameMenuScreen extends StatefulWidget {
  const FlagGameMenuScreen({super.key});

  @override
  State<FlagGameMenuScreen> createState() => _FlagGameMenuScreenState();
}

class _FlagGameMenuScreenState extends State<FlagGameMenuScreen>
    with TTSMusicMixin {
  @override
  void initState() {
    super.initState();
    FlagDataManager.loadCountries();
  }

  @override
  Widget build(BuildContext context) {
    final mq = CustomMQ(context);

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
            ImageManager.homeBackground,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(mq.width(4)),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.green),
                      ),
                      const Text(
                        'Learn Country Flags',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(mq.width(6)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MenuButton(
                            title: 'Guess the Flag',
                            subtitle: 'Match flag to country',
                            icon: Icons.flag,
                            color: Colors.orange,
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => const GuessTheFlagScreen()),
                            ),
                            mq: mq,
                          ),
                          SizedBox(height: mq.height(3)),
                          _MenuButton(
                            title: 'Tap to Learn',
                            subtitle: 'Explore world flags',
                            icon: Icons.menu_book,
                            color: Colors.blue,
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => const TapToLearnScreen()),
                            ),
                            mq: mq,
                          ),
                          SizedBox(height: mq.height(3)),
                          _MenuButton(
                            title: 'Listening Game',
                            subtitle: 'Hear and find the flag',
                            icon: Icons.hearing,
                            color: Colors.purple,
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (_) => const ListeningGameScreen()),
                            ),
                            mq: mq,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final CustomMQ mq;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.mq,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(mq.width(6)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(mq.width(3)),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: mq.width(8)),
            ),
            SizedBox(width: mq.width(4)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
