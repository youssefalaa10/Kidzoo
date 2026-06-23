import '../services/cubit/music_cubit.dart';
import 'tts_service.dart';

class TtsHelper {
  TtsHelper({required this.musicCubit, this.languageCode = 'en'}) {
    _initTts();
  }

  final MusicCubit musicCubit;
  final String languageCode;

  final TtsService _ttsService = TtsService();

  bool _isInitCalled = false;

  void _initTts() {
    if (_isInitCalled) return;
    _isInitCalled = true;

    _ttsService.init(languageCode: languageCode);

    _ttsService.setCompletionHandler(() {
      musicCubit.resumeMusic();
    });

    _ttsService.setErrorHandler((msg) {
      musicCubit.resumeMusic();
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await musicCubit.stopMusic();
      // Ensure language is correct for this specific speak call
      await _ttsService.setLanguage(languageCode);
      await _ttsService.speak(text);
    } catch (e) {
      musicCubit.resumeMusic();
    }
  }

  Future<void> stop() async {
    try {
      await _ttsService.stop();
      musicCubit.resumeMusic();
    } catch (_) {}
  }
}
