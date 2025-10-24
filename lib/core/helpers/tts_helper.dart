import 'package:flutter_tts/flutter_tts.dart';

import '../services/cubit/music_cubit.dart';

class TtsHelper {
  TtsHelper({required this.musicCubit}) {
    _initTts();
  }
  final FlutterTts _flutterTts = FlutterTts();
  final MusicCubit musicCubit;

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);

    // Set up completion handler to resume music after TTS completes
    _flutterTts.setCompletionHandler(() {
      musicCubit.resumeMusic();
    });
  }

  Future<void> speak(String text) async {
    try {
      // Stop background music completely before speaking to avoid تداخل
      await musicCubit.stopMusic();

      await _flutterTts.speak(text);
    } catch (e) {
      // Resume music even if TTS fails
      musicCubit.resumeMusic();
      throw Exception('Error with TTS: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      // Resume music when TTS is stopped
      musicCubit.resumeMusic();
    } catch (e) {
      throw Exception('Error stopping TTS: $e');
    }
  }

  Future<void> getVoices() async {
    try {
      _flutterTts.getVoices.then((voices) {
        throw Exception('Available Voices: $voices');
      });
    } catch (e) {
      throw Exception('Error fetching voices: $e');
    }
  }
}
