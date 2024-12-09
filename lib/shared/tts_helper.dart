import 'package:flutter_tts/flutter_tts.dart';

class TtsHelper {
  final FlutterTts _flutterTts = FlutterTts();

  TtsHelper() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error with TTS: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print("Error stopping TTS: $e");
    }
  }

  Future<void> getVoices() async {
    try {
      _flutterTts.getVoices.then((voices) {
        print("Available Voices: $voices");
      });
    } catch (e) {
      print("Error fetching voices: $e");
    }
  }
}
