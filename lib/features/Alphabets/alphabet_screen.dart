import 'package:flutter/material.dart';
import 'package:kidzoo/core/helpers/tts_service.dart';
import 'package:kidzoo/core/mixins/background_music_mixin.dart';
import 'package:kidzoo/features/Alphabets/widgets/alphabet_app_bar.dart';

import 'widgets/alphabet_display.dart';
import 'widgets/alphabet_selection.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> with TTSMusicMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = Localizations.localeOf(context).languageCode;
      if (lang == 'ar') {
        TtsService.checkAndRequestArabicVoice(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf5f1),
      body: Row(
        children: [
          // Left side: Alphabet display area
          const Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlphabetAppBar(),
                AlphabetDisplay(),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AlphabetSelection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
